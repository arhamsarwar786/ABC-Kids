import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/app_preferences.dart';
import '../constants/app_assets.dart';

class AudioService extends ChangeNotifier with WidgetsBindingObserver {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  bool _isAppInForeground = true;
  bool _isBgmSuspended = false;

  bool get isMuted => AppPreferences.isSoundMuted;

  AudioService() {
    _initPlayers();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppInForeground = false;
      _bgmPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      if (!isMuted && !_isBgmSuspended) {
        playBackgroundMusic();
      }
    }
  }

  Future<void> _initPlayers() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(1.0);
    await _sfxPlayer.setVolume(1.0);

    _bgmPlayer.onLog.listen((msg) => debugPrint('BGM Log: $msg'));
    _sfxPlayer.onLog.listen((msg) => debugPrint('SFX Log: $msg'));
  }

  Future<void> toggleMute() async {
    final newMuteStatus = !isMuted;
    await AppPreferences.setSoundMuted(newMuteStatus);

    if (newMuteStatus) {
      await _bgmPlayer.pause();
    } else {
      await playBackgroundMusic();
    }
    notifyListeners();
  }

  String _getRelativeAssetPath(String fullPath) {
    if (fullPath.startsWith('assets/')) {
      return fullPath.substring(7);
    }
    return fullPath;
  }

  Future<void> playBackgroundMusic() async {
    if (isMuted || !_isAppInForeground) return;
    try {
      final path = _getRelativeAssetPath(AppAssets.backgroundMusic);
      await _bgmPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint('Audio missing: ${AppAssets.backgroundMusic}');
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.pause();
  }

  void setBgmSuspended(bool suspended) {
    _isBgmSuspended = suspended;
    if (suspended) {
      stopBackgroundMusic();
    } else {
      if (_isAppInForeground) {
        playBackgroundMusic();
      }
    }
  }

  Future<void> playNumber(int number) async {

    final fullPath = CountingAudioAssets.numbers[number];
    if (fullPath != null) {
      _playSfx(fullPath);
    } else {
      debugPrint('No audio found for number $number');
    }
  }

  Future<void> playLetter(String letter) async {

    final fullPath = AlphabetAudioAssets.letters[letter.toLowerCase()];
    if (fullPath != null) {
      _playSfx(fullPath);
    } else {
      debugPrint('No audio found for letter $letter');
    }
  }

  Future<void> playSound(String fullPath) async {
    _playSfx(fullPath);
  }

  Future<void> _playSfx(String fullPath) async {
    try {
      await _sfxPlayer.stop();
      final relativePath = _getRelativeAssetPath(fullPath);
      await _sfxPlayer.play(AssetSource(relativePath));
    } catch (e) {
      debugPrint('Audio missing: $fullPath');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }
}
