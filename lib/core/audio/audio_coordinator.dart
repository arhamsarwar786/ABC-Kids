import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/content/audio_manifest.dart';
import '../../data/models/content.dart';
import '../../data/models/device_settings.dart';
import '../../state/settings_store.dart';
import 'audio_driver.dart';

enum PlayResult { played, unavailable, failed, cancelled }

enum AppPresence { foreground, background }

/// Single owner of all app audio.
///
/// * One narration at a time: every new narration (clip or device voice)
///   stops the previous one. Nothing is queued, so rapid taps cannot build a
///   backlog; an identical request within [repeatGuard] is ignored.
/// * Music ducks under narration and is paused while suspended (ads, paused
///   activities) or in the background.
/// * Backgrounding stops narration immediately and notifies listeners via
///   [presence] so activities can pause and require an explicit resume.
/// * Only assets that exist in the bundle and match their declared kind are
///   played. Missing audio returns [PlayResult.unavailable]; callers must
///   offer retry or an alternate path.
class AudioCoordinator extends ChangeNotifier with WidgetsBindingObserver {
  final AudioDriver _driver;
  final SettingsStore _settingsStore;
  final Set<String> _bundled;
  static const Duration repeatGuard = Duration(milliseconds: 300);
  static const double duckFactor = 0.25;

  int _token = 0;
  bool _narrating = false;
  String? _lastRequest;
  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _foreground = true;
  bool _musicPlaying = false;
  bool _musicStarted = false;
  final Set<String> _suspensions = {};
  bool? _deviceVoiceOk;
  bool _disposed = false;
  final List<Timer> _voiceRetries = [];
  final StreamController<AppPresence> _presence = StreamController.broadcast();

  /// When the device voice is not ready at start, it is checked again
  /// after these delays.
  final List<Duration> voiceRetryDelays;

  AudioCoordinator(this._driver, this._settingsStore,
      {required Set<String> bundledAssets,
      bool observeLifecycle = true,
      this.voiceRetryDelays = const [Duration(seconds: 3), Duration(seconds: 8), Duration(seconds: 20)]})
      : _bundled = bundledAssets {
    _settingsStore.addListener(_applySettings);
    if (observeLifecycle) WidgetsBinding.instance.addObserver(this);
  }

  Future<void> init() async {
    await _driver.init();
    _deviceVoiceOk = await _driver.deviceVoiceAvailable();
    notifyListeners();
    if (_deviceVoiceOk != true) {
      // The system voice can take a few seconds to start after boot.
      for (final d in voiceRetryDelays) {
        _voiceRetries.add(Timer(d, refreshDeviceVoice));
      }
    }
  }

  /// Checks the device voice again and notifies listeners if it changed
  /// (e.g. the TTS engine finished starting, or a voice was installed).
  Future<void> refreshDeviceVoice() async {
    if (_disposed || _deviceVoiceOk == true) return;
    final ok = await _driver.deviceVoiceAvailable();
    if (_disposed || ok == _deviceVoiceOk) return;
    _deviceVoiceOk = ok;
    notifyListeners();
  }

  DeviceSettings get _s => _settingsStore.settings;
  Stream<AppPresence> get presence => _presence.stream;
  bool get isForeground => _foreground;
  bool get isNarrating => _narrating;

  /// Whether the device voice may be used for whole words and instructions.
  bool get deviceVoiceUsable => _s.deviceVoiceForWords && (_deviceVoiceOk ?? false);
  bool? get deviceVoiceInstalled => _deviceVoiceOk;

  bool isBundled(String? path) => path != null && _bundled.contains(path);

  bool assetPlayable(AudioAsset? a) => a != null && a.hasFile && isBundled(a.path);

  // -------------------------------------------------------------- narration

  bool _guard(String key) {
    final now = DateTime.now();
    if (_narrating && key == _lastRequest && now.difference(_lastRequestAt) < repeatGuard) return false;
    _lastRequest = key;
    _lastRequestAt = now;
    return true;
  }

  Future<int> _beginNarration() async {
    final token = ++_token;
    await _driver.stopVoice();
    await _driver.stopSpeaking();
    _narrating = true;
    _applyMusic();
    return token;
  }

  void _endNarration(int token) {
    if (token != _token) return;
    _narrating = false;
    _applyMusic();
  }

  /// Plays a declared asset. Phoneme assets play only if reviewed.
  Future<PlayResult> playAsset(AudioAsset? asset) async {
    if (!_foreground) return PlayResult.cancelled;
    if (!assetPlayable(asset)) return PlayResult.unavailable;
    if (asset!.kind == AudioKind.phoneme && !asset.usableForPhonics) return PlayResult.unavailable;
    if (!_guard(asset.id)) return PlayResult.cancelled;
    final token = await _beginNarration();
    final ok = await _driver.playVoice(asset.path!, _s.narrationVolume);
    if (token != _token) return PlayResult.cancelled;
    _endNarration(token);
    return ok ? PlayResult.played : PlayResult.failed;
  }

  /// Device voice for whole words or instructions only. Never pass isolated
  /// letters or sounds here: the engine would say letter names.
  Future<PlayResult> speak(String text) async {
    if (!_foreground) return PlayResult.cancelled;
    if (!deviceVoiceUsable) return PlayResult.unavailable;
    if (!_guard('tts:$text')) return PlayResult.cancelled;
    final token = await _beginNarration();
    final ok = await _driver.speak(text, _s.narrationVolume);
    if (token != _token) return PlayResult.cancelled;
    _endNarration(token);
    return ok ? PlayResult.played : PlayResult.failed;
  }

  /// Plays a word: reviewed recording first, otherwise the device voice.
  Future<PlayResult> playWord(WordExample w) async {
    final rec = AudioManifest.byId(w.audioId);
    if (rec != null && rec.status == ReviewStatus.reviewed && assetPlayable(rec)) return playAsset(rec);
    return speak(w.text);
  }

  bool wordAudioAvailable(WordExample w) {
    final rec = AudioManifest.byId(w.audioId);
    return (rec != null && rec.status == ReviewStatus.reviewed && assetPlayable(rec)) || deviceVoiceUsable;
  }

  /// Stops any narration now (screen exit, pause, background).
  Future<void> stopNarration() async {
    _token++;
    _narrating = false;
    await _driver.stopVoice();
    await _driver.stopSpeaking();
    _applyMusic();
  }

  Future<void> playEffect(Effect e) async {
    if (!_foreground || _s.effectsVolume <= 0) return;
    final a = AudioManifest.byId('effect_${e.name}');
    if (!assetPlayable(a)) return;
    await _driver.playEffect(a!.path!, _s.effectsVolume);
  }

  // ------------------------------------------------------------------ music

  void suspendMusic(String reason) {
    if (_suspensions.add(reason)) _applyMusic();
  }

  void releaseMusic(String reason) {
    if (_suspensions.remove(reason)) _applyMusic();
  }

  /// Called once the child UI is visible.
  void enableMusic() {
    _musicStarted = true;
    _applyMusic();
  }

  bool get musicShouldPlay =>
      _musicStarted && _foreground && !_s.musicMuted && _s.musicVolume > 0 && _suspensions.isEmpty;

  void _applyMusic() {
    final music = AudioManifest.byId('music_background');
    if (!assetPlayable(music)) return;
    final volume = _s.musicVolume * (_narrating ? duckFactor : 1.0);
    if (musicShouldPlay) {
      if (_musicPlaying) {
        _driver.setMusicVolume(volume);
      } else {
        _musicPlaying = true;
        _driver.startMusic(music!.path!, volume);
      }
    } else if (_musicPlaying) {
      _musicPlaying = false;
      _driver.pauseMusic();
    }
  }

  void _applySettings() {
    _applyMusic();
    notifyListeners();
  }

  // -------------------------------------------------------------- lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (!_foreground) return;
        _foreground = false;
        stopNarration();
        _applyMusic();
        _presence.add(AppPresence.background);
      case AppLifecycleState.resumed:
        if (_foreground) return;
        _foreground = true;
        refreshDeviceVoice();
        _applyMusic();
        _presence.add(AppPresence.foreground);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _voiceRetries) {
      t.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    _settingsStore.removeListener(_applySettings);
    _presence.close();
    _driver.dispose();
    super.dispose();
  }
}
