import 'package:flutter/material.dart';

/// Premium-playful palette: warm cream background with a soft lilac glow,
/// a violet accent, deep indigo text and juicy pastel fills. Pastels are
/// for fills only; text on them uses [AppTokens.navy].
class AppTokens {
  static const Color ivory = Color(0xFFFFFAF3);
  static const Color ivoryGlow = Color(0xFFF3ECFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color purple = Color(0xFF6C4CF1);
  static const Color purpleLight = Color(0xFF9479FF);
  static const Color purpleDeep = Color(0xFF4A2FC4);
  static const Color purpleSoft = Color(0xFFEFE9FF);
  static const Color navy = Color(0xFF1E1B4B);
  static const Color navyMuted = Color(0xFF5B5A7E);
  static const Color outline = Color(0xFFEAE4F2);

  static const Color coral = Color(0xFFFFC4B5);
  static const Color mint = Color(0xFFB8EBD5);
  static const Color lavender = Color(0xFFDDD3FF);
  static const Color yellow = Color(0xFFFFE49A);
  static const Color blue = Color(0xFFC3E2FF);

  static const Color coralDeep = Color(0xFFB4533A);
  static const Color mintDeep = Color(0xFF2C7A5E);
  static const Color yellowDeep = Color(0xFF8A6512);
  static const Color blueDeep = Color(0xFF2D6A9F);

  static const Color success = Color(0xFF22A06B);
  static const Color gentle = Color(0xFFE0784F);

  static const List<Color> pastels = [coral, mint, lavender, yellow, blue];

  /// Font for the big letters children learn (see AppTheme).
  static const String letterFont = 'Fredoka';

  /// Minimum touch target for children.
  static const double childTarget = 56;
  static const double radius = 26;
  static const double radiusSmall = 16;

  /// Height of the darker “3D” lip under chunky buttons and tiles.
  static const double lip = 6;

  static double gutter(BuildContext context) => MediaQuery.sizeOf(context).width >= 600 ? 24 : 20;

  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).shortestSide >= 600;

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x1A3B2A8C), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Soft shadow tinted with [c], so cards glow in their own colour.
  static List<BoxShadow> glow(Color c) => [
        BoxShadow(color: shade(c, 0.25).withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10)),
      ];

  /// Lighter top, slightly deeper bottom: gives fills a soft, rounded feel.
  static LinearGradient fill(Color c) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tint(c, 0.35), c],
      );

  /// Darker shade of [c] for the 3D lip.
  static Color lipFor(Color c) => shade(c, 0.18);

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [purpleLight, purple],
  );

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [ivoryGlow, ivory, ivory],
    stops: [0, 0.45, 1],
  );

  static Color tint(Color c, double t) => Color.lerp(c, Colors.white, t)!;
  static Color shade(Color c, double t) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - t).clamp(0.0, 1.0)).withSaturation((h.saturation + t * 0.3).clamp(0.0, 1.0)).toColor();
  }
}
