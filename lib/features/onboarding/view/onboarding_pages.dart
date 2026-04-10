import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final IconData iconPath; // Using IconData temporarily
  final Color backgroundColor;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.iconPath,
    required this.backgroundColor,
  });
}

final List<OnboardingPageModel> onboardingPages = [
  OnboardingPageModel(
    title: 'Welcome!',
    description: 'Let\'s learn ABC and Numbers in a fun way!',
    iconPath: Icons.toys_rounded,
    backgroundColor: AppTheme.primaryColor,
  ),
  OnboardingPageModel(
    title: 'Listen & Learn',
    description: 'Listen to the pronunciations of every letter and number.',
    iconPath: Icons.record_voice_over_rounded,
    backgroundColor: AppTheme.accentPink,
  ),
  OnboardingPageModel(
    title: 'Ready to Play?',
    description: 'Let\'s start our learning journey today!',
    iconPath: Icons.check_circle_outline_rounded,
    backgroundColor: AppTheme.accentGreen,
  ),
];
