import 'package:flutter/material.dart';
import '../../features/splash/view/splash_screen.dart';
import '../../features/onboarding/view/onboarding_screen.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/learning/view/abc_screen.dart';
import '../../features/learning/view/counting_screen.dart';
import '../../features/learning/view/detail_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../../features/learning/model/learning_item.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String abc = '/abc';
  static const String counting = '/counting';
  static const String detail = '/detail';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case abc:
        return MaterialPageRoute(builder: (_) => const AbcScreen());
      case counting:
        return MaterialPageRoute(builder: (_) => const CountingScreen());
      case detail:
        final item = settings.arguments as LearningItem;
        return MaterialPageRoute(builder: (_) => DetailScreen(item: item));
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found!')),
          ),
        );
    }
  }
}
