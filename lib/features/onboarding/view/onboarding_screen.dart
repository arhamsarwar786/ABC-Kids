import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/constants/app_assets.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_colors.dart';
import 'onboarding_pages.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuart,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onSkip() {
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    await AppPreferences.setOnboardingSeen(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Persistent Professional Background
          Positioned.fill(
            child: Image.asset(AppAssets.onboardBackground, fit: BoxFit.cover),
          ),

          // 2. Main Page Content (Sliding Part)
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingPages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final page = onboardingPages[index];
              return Column(
                children: [
                  // Top Section (Icon Area)
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          color: AppColors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          page.iconPath,
                          size: 140,
                          color: AppColors.transparent,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Professional Sheet (Sliding Content)
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black12,
                            blurRadius: 15,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            page.title,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page.description,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text.withOpacity(0.7),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Skip Button (Top Right)
          Positioned(
            top: 44,
            left: 16,
            child: TextButton(
              onPressed: _onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 4. Fixed Bottom Controller (System)
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: SafeArea(
              bottom: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingPages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Professional Button System
                  GestureDetector(
                    onTap: _onNext,
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.pink,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _currentPage == onboardingPages.length - 1
                            ? 'GET STARTED'
                            : 'NEXT',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
