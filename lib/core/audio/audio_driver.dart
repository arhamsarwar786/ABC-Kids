import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Thin platform layer under [AudioCoordinator]; faked in tests.
abstract class AudioDriver {
  Future<void> init();

  /// Plays a bundled clip and completes when it ends. Returns false on error.
  Future<bool> playVoice(String assetPath, double volume);
  Future<void> stopVoice();

  /// Speaks whole words/instructions with the device voice. Returns false if
  /// the engine is unavailable or fails.
  Future<bool> speak(String text, double volume);
  Future<void> stopSpeaking();
  Future<bool> deviceVoiceAvailable();

  Future<void> playEffect(String assetPath, double volume);
  Future<void> startMusic(String assetPath, double volume);
  Future<void> setMusicVolume(double volume);
  Future<void> pauseMusic();
  Future<void> dispose();
}

class PlatformAudioDriver implements AudioDriver {
  final AudioPlayer _voice = AudioPlayer(playerId: 'voice');
  final AudioPlayer _effects = AudioPlayer(playerId: 'effects');
  final AudioPlayer _music = AudioPlayer(playerId: 'music');
  final FlutterTts _tts = FlutterTts();
  bool? _ttsOk;
  bool _musicLoaded = false;
  Completer<bool>? _voiceDone;

  static String _rel(String path) => path.startsWith('assets/') ? path.substring(7) : path;

  @override
  Future<void> init() async {
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      await _voice.setReleaseMode(ReleaseMode.stop);
      _voice.onPlayerComplete.listen((_) => _completeVoice(true));
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.42);
    } catch (e) {
      debugPrint('Audio init failed: $e');
    }
  }

  void _completeVoice(bool ok) {
    final c = _voiceDone;
    if (c != null && !c.isCompleted) c.complete(ok);
  }

  @override
  Future<bool> playVoice(String assetPath, double volume) async {
    _completeVoice(false);
    final done = Completer<bool>();
    _voiceDone = done;
    try {
      await _voice.stop();
      await _voice.setVolume(volume);
      await _voice.play(AssetSource(_rel(assetPath)));
    } catch (e) {
      debugPrint('Voice playback failed for $assetPath: $e');
      _completeVoice(false);
    }
    return done.future.timeout(const Duration(seconds: 12), onTimeout: () => false);
  }

  @override
  Future<void> stopVoice() async {
    _completeVoice(false);
    try {
      await _voice.stop();
    } catch (_) {}
  }

  @override
  Future<bool> deviceVoiceAvailable() async {
    // Only a positive answer is cached: right after boot the Android TTS
    // engine may not be bound yet and answers “no” for a few seconds.
    if (_ttsOk == true) return true;
    try {
      final engines = defaultTargetPlatform == TargetPlatform.android ? await _tts.getEngines : const ['ios'];
      final hasEngine = engines is List && engines.isNotEmpty;
      var lang = false;
      for (final l in const ['en-GB', 'en-US', 'en']) {
        final r = await _tts.isLanguageAvailable(l);
        if (r == true || r == 1) {
          await _tts.setLanguage(l);
          lang = true;
          break;
        }
      }
      _ttsOk = hasEngine && lang;
    } catch (e) {
      debugPrint('Device voice unavailable: $e');
      _ttsOk = false;
    }
    return _ttsOk!;
  }

  @override
  Future<bool> speak(String text, double volume) async {
    if (!await deviceVoiceAvailable()) return false;
    try {
      await _tts.setVolume(volume);
      final r = await _tts.speak(text).timeout(const Duration(seconds: 12));
      return r == 1 || r == true;
    } catch (e) {
      debugPrint('Device voice failed: $e');
      return false;
    }
  }

  @override
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  Future<void> playEffect(String assetPath, double volume) async {
    try {
      await _effects.stop();
      await _effects.setVolume(volume);
      await _effects.play(AssetSource(_rel(assetPath)));
    } catch (e) {
      debugPrint('Effect failed: $e');
    }
  }

  @override
  Future<void> startMusic(String assetPath, double volume) async {
    try {
      await _music.setVolume(volume);
      if (_musicLoaded) {
        await _music.resume();
      } else {
        await _music.play(AssetSource(_rel(assetPath)));
        _musicLoaded = true;
      }
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  @override
  Future<void> setMusicVolume(double volume) async {
    try {
      await _music.setVolume(volume);
    } catch (_) {}
  }

  @override
  Future<void> pauseMusic() async {
    try {
      await _music.pause();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await _voice.dispose();
    await _effects.dispose();
    await _music.dispose();
    await _tts.stop();
  }
}
