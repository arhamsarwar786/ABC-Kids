import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/tokens.dart';

class AppTheme {
  /// Body and UI text.
  static const String fontFamily = 'Nunito';

  /// Headings and button labels: rounded and friendly.
  static const String displayFamily = 'Baloo2';

  /// The big letters children learn (simple, round letter shapes).
  static const String letterFamily = 'Fredoka';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.purple,
      primary: AppTokens.purple,
      surface: AppTokens.ivory,
      onSurface: AppTokens.navy,
    );
    const t = TextStyle(color: AppTokens.navy, fontFamily: fontFamily);
    const h = TextStyle(color: AppTokens.navy, fontFamily: displayFamily);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.ivory,
      fontFamily: fontFamily,
      textTheme: TextTheme(
        displaySmall: h.copyWith(fontSize: 38, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.3),
        headlineMedium: h.copyWith(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1),
        headlineSmall: h.copyWith(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
        titleLarge: h.copyWith(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2),
        titleMedium: t.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        bodyLarge: t.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
        bodyMedium: t.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        labelLarge: h.copyWith(fontSize: 19, fontWeight: FontWeight.w700, height: 1.15),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.ivory,
        foregroundColor: AppTokens.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: displayFamily, color: AppTokens.navy, fontSize: 24, fontWeight: FontWeight.w800),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          side: const BorderSide(color: AppTokens.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(side: BorderSide(color: AppTokens.outline, width: 1.5)),
        labelStyle: t.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        backgroundColor: AppTokens.surface,
        selectedColor: AppTokens.purpleSoft,
        checkmarkColor: AppTokens.purple,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: t.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        subtitleTextStyle: t.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: AppTokens.navyMuted),
        iconColor: AppTokens.purple,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppTokens.purple : null),
      ),
      sliderTheme: const SliderThemeData(activeTrackColor: AppTokens.purple, thumbColor: AppTokens.purple),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTokens.purpleSoft,
        height: 74,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: displayFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: s.contains(WidgetState.selected) ? AppTokens.purple : AppTokens.navyMuted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 28,
              color: s.contains(WidgetState.selected) ? AppTokens.purple : AppTokens.navyMuted,
            )),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
