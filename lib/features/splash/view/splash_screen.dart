import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (AppPreferences.isOnboardingSeen) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.splashScreenLogo),
            fit: BoxFit.contain,
          ),
        ),
        // child: Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     children: [
        //       const Icon(Icons.school_rounded, size: 120, color: AppColors.white),
        //       const SizedBox(height: 24),
        //       Text(
        //         'ABC Kids Learning',
        //         style: Theme.of(context).textTheme.displayLarge?.copyWith(
        //           color: AppColors.white,
        //           shadows: const [
        //             Shadow(
        //               blurRadius: 10,
        //               color: AppColors.black26,
        //               offset: Offset(2, 2),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}
