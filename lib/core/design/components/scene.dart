import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Illustrated backdrops for child screens. Each theme is a soft sky with
/// clouds (or stars, or bubbles) and gentle hills or waves along the bottom,
/// so every area feels like a place rather than a blank page.
enum SceneTheme { meadow, sky, ocean, night, town, sunset }

class SceneBackground extends StatelessWidget {
  final SceneTheme theme;
  final Widget child;
  const SceneBackground({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _ScenePainter(theme),
        child: child,
      );
}

class _Palette {
  final List<Color> sky;
  final Color farHill;
  final Color nearHill;
  final Color accent;
  const _Palette(this.sky, this.farHill, this.nearHill, this.accent);
}

const _palettes = {
  SceneTheme.meadow:
      _Palette([Color(0xFFE9F4FF), Color(0xFFF6F1FF), Color(0xFFFFF8EE)], Color(0xFFCDEFD9), Color(0xFFAEE3C4), Color(0xFFFFE08A)),
  SceneTheme.sky:
      _Palette([Color(0xFFEDE6FF), Color(0xFFF7F2FF), Color(0xFFFFF9F1)], Color(0xFFE3D9FF), Color(0xFFD3C5FF), Color(0xFFFFE08A)),
  SceneTheme.ocean:
      _Palette([Color(0xFFE2F3FF), Color(0xFFEAF6FF), Color(0xFFF4FAFF)], Color(0xFFB9E1FA), Color(0xFF9BD3F5), Color(0xFFFFFFFF)),
  SceneTheme.night:
      _Palette([Color(0xFFE6E0FF), Color(0xFFF0EBFF), Color(0xFFFBF7FF)], Color(0xFFD9CFFA), Color(0xFFC9BCF5), Color(0xFFFFE9A8)),
  SceneTheme.town:
      _Palette([Color(0xFFE8F3FF), Color(0xFFF4F7FF), Color(0xFFFFF8EF)], Color(0xFFD8E8F5), Color(0xFFE6E1EF), Color(0xFFFFE08A)),
  SceneTheme.sunset:
      _Palette([Color(0xFFFFE7DD), Color(0xFFFFF1E8), Color(0xFFFFF9F2)], Color(0xFFFFD9C7), Color(0xFFFFC9B3), Color(0xFFFFC857)),
};

class _ScenePainter extends CustomPainter {
  final SceneTheme theme;
  _ScenePainter(this.theme);

  @override
  void paint(Canvas canvas, Size s) {
    final p = _palettes[theme]!;
    final rect = Offset.zero & s;
    canvas.drawRect(
        rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.sky).createShader(rect));

    // Sun / moon glow, top right.
    // Sun / moon sits below the header row so it never crowds the buttons.
    final sun = Offset(s.width * 0.9, s.height * 0.3);
    final r = math.min(s.width, 500) * 0.07;
    canvas.drawCircle(sun, r * 2.4, Paint()..color = p.accent.withValues(alpha: 0.18));
    canvas.drawCircle(sun, r * 1.5, Paint()..color = p.accent.withValues(alpha: 0.28));
    canvas.drawCircle(sun, r, Paint()..color = p.accent.withValues(alpha: theme == SceneTheme.ocean ? 0.0 : 0.85));

    switch (theme) {
      case SceneTheme.night:
        final star = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
        final rnd = math.Random(7);
        for (var i = 0; i < 26; i++) {
          canvas.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.55), 1.2 + rnd.nextDouble() * 2.2, star);
        }
      case SceneTheme.ocean:
        final bubble = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        final rnd = math.Random(3);
        for (var i = 0; i < 14; i++) {
          canvas.drawCircle(
              Offset(rnd.nextDouble() * s.width, s.height * (0.15 + rnd.nextDouble() * 0.6)), 4 + rnd.nextDouble() * 10, bubble);
        }
      default:
        _cloud(canvas, Offset(s.width * 0.18, s.height * 0.10), s.width * 0.16);
        _cloud(canvas, Offset(s.width * 0.62, s.height * 0.20), s.width * 0.11);
        _cloud(canvas, Offset(s.width * 0.08, s.height * 0.42), s.width * 0.08);
    }

    // Rolling hills (or waves) along the bottom.
    final h = s.height;
    final far = Path()
      ..moveTo(0, h * 0.80)
      ..cubicTo(s.width * 0.25, h * 0.73, s.width * 0.45, h * 0.84, s.width * 0.7, h * 0.78)
      ..cubicTo(s.width * 0.85, h * 0.745, s.width * 0.95, h * 0.77, s.width, h * 0.76)
      ..lineTo(s.width, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, Paint()..color = p.farHill.withValues(alpha: 0.75));
    final near = Path()
      ..moveTo(0, h * 0.88)
      ..cubicTo(s.width * 0.3, h * 0.82, s.width * 0.6, h * 0.93, s.width, h * 0.86)
      ..lineTo(s.width, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(near, Paint()..color = p.nearHill.withValues(alpha: 0.75));

    if (theme == SceneTheme.meadow || theme == SceneTheme.sunset) {
      // Little flowers on the near hill.
      final rnd = math.Random(11);
      for (var i = 0; i < 9; i++) {
        final x = s.width * (0.05 + i * 0.11 + rnd.nextDouble() * 0.04);
        final y = h * (0.92 + rnd.nextDouble() * 0.05);
        final c = [const Color(0xFFFFFFFF), const Color(0xFFFFD45E), const Color(0xFFF59AA8)][i % 3];
        for (var k = 0; k < 5; k++) {
          final a = k * math.pi * 2 / 5;
          canvas.drawCircle(Offset(x + math.cos(a) * 4, y + math.sin(a) * 4), 3, Paint()..color = c.withValues(alpha: 0.9));
        }
        canvas.drawCircle(Offset(x, y), 2.4, Paint()..color = const Color(0xFFFFB347));
      }
    }
    if (theme == SceneTheme.town) {
      final road = Rect.fromLTWH(0, h * 0.93, s.width, h * 0.07);
      canvas.drawRect(road, Paint()..color = const Color(0xFFD6D3E3));
      final dash = Paint()..color = Colors.white;
      for (var x = 12.0; x < s.width; x += 46) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, h * 0.962, 24, 4), const Radius.circular(2)), dash);
      }
    }
  }

  void _cloud(Canvas c, Offset o, double w) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: w * 0.34), Radius.circular(w)), paint);
    c.drawCircle(o.translate(-w * 0.14, -w * 0.12), w * 0.2, paint);
    c.drawCircle(o.translate(w * 0.12, -w * 0.17), w * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.theme != theme;
}
