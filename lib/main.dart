import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/services/ads_service.dart';
import 'core/services/audio_service.dart';
import 'core/utils/app_preferences.dart';
import 'features/home/viewmodel/home_viewmodel.dart';
import 'features/learning/viewmodel/learning_viewmodel.dart';
import 'features/settings/viewmodel/settings_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Edge-to-Edge mode for true transparency on modern Android
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Preferences
  await AppPreferences.init();

  // Initialize Google Mobile Ads (child-directed / G-rated)
  await AdsService.configureSdk();

  final audioService = AudioService();
  final adsService = AdsService();
  adsService.attachAudio(audioService);
  await adsService.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: audioService),
        ChangeNotifierProvider.value(value: adsService),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => LearningViewModel()),
      ],
      child: const AbcKidsApp(),
    ),
  );
}
