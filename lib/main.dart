import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/services/audio_service.dart';
import 'core/utils/app_preferences.dart';
import 'features/home/viewmodel/home_viewmodel.dart';
import 'features/learning/viewmodel/learning_viewmodel.dart';
import 'features/settings/viewmodel/settings_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Preferences
  await AppPreferences.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => LearningViewModel()),
      ],
      child: const AbcKidsApp(),
    ),
  );
}
