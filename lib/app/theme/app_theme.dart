import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/app_colors.dart';

class AppTheme {
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color backgroundColor = AppColors.background;
  static const Color cardColor = AppColors.card;
  static const Color textColor = AppColors.text;
  static const Color accentPink = AppColors.pink;
  static const Color accentGreen = AppColors.green;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      // Apply Fredoka globally as the font family
      fontFamily: GoogleFonts.fredoka().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: AppColors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 6,
        shadowColor: AppColors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: GoogleFonts.fredokaTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: textColor,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: AppColors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
