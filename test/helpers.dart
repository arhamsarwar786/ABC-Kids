import 'package:abc_kids_learning/app/theme/app_theme.dart';
import 'package:abc_kids_learning/core/audio/audio_coordinator.dart';
import 'package:abc_kids_learning/core/audio/audio_driver.dart';
import 'package:abc_kids_learning/core/services/ads_service.dart';
import 'package:abc_kids_learning/data/content/audio_manifest.dart';
import 'package:abc_kids_learning/data/storage/app_storage.dart';
import 'package:abc_kids_learning/domain/active_time.dart';
import 'package:abc_kids_learning/state/learner_store.dart';
import 'package:abc_kids_learning/state/progress_store.dart';
import 'package:abc_kids_learning/state/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudioDriver implements AudioDriver {
  final List<String> played = [];
  final List<String> spoken = [];
  bool voiceAvailable;
  bool clipsSucceed = true;
  FakeAudioDriver({this.voiceAvailable = true});

  @override
  Future<void> init() async {}
  @override
  Future<bool> playVoice(String assetPath, double volume) async {
    played.add(assetPath);
    return clipsSucceed;
  }

  @override
  Future<void> stopVoice() async {}
  @override
  Future<bool> speak(String text, double volume) async {
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<bool> deviceVoiceAvailable() async => voiceAvailable;
  @override
  Future<void> playEffect(String assetPath, double volume) async {}
  @override
  Future<void> startMusic(String assetPath, double volume) async {}
  @override
  Future<void> setMusicVolume(double volume) async {}
  @override
  Future<void> pauseMusic() async {}
  @override
  Future<void> dispose() async {}
}

class TestApp {
  final AppStorage storage;
  final SettingsStore settings;
  final LearnerStore learners;
  final ProgressStore progress;
  final AudioCoordinator audio;
  final FakeAudioDriver driver;
  final AdsService ads;
  final ActiveTimeTracker timer;

  TestApp._(this.storage, this.settings, this.learners, this.progress, this.audio, this.driver, this.ads, this.timer);

  static Future<TestApp> create({Map<String, Object> prefs = const {}, bool deviceVoice = true}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final storage = await AppStorage.open(p);
    final settings = SettingsStore(storage);
    final learners = LearnerStore(storage);
    final progress = ProgressStore(storage, learners);
    final driver = FakeAudioDriver(voiceAvailable: deviceVoice);
    final bundled = {for (final a in AudioManifest.all.values) if (a.path != null) a.path!};
    final audio = AudioCoordinator(driver, settings, bundledAssets: bundled, voiceRetryDelays: const []);
    await audio.init();
    return TestApp._(storage, settings, learners, progress, audio, driver, AdsService(audio: audio), ActiveTimeTracker());
  }

  Widget wrap(Widget child) => MultiProvider(
        providers: [
          Provider.value(value: storage),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: learners),
          ChangeNotifierProvider.value(value: progress),
          ChangeNotifierProvider.value(value: audio),
          ChangeNotifierProvider.value(value: ads),
          ChangeNotifierProvider.value(value: timer),
        ],
        child: MaterialApp(theme: AppTheme.light, home: child),
      );
}

/// Sets a logical screen size and text scale for layout tests.
Future<void> setScreen(WidgetTester tester, Size size, {double textScale = 1}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

/// Advances time in small steps so engine timers and animations run.
Future<void> settleFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}
