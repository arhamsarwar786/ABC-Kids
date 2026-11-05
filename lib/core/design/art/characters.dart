import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';
import 'art_kit.dart';
import '../app_icons.dart';

/// Pastel fill and deeper edge colour pairs for letter characters.
class LetterColors {
  static const List<(Color, Color)> pairs = [
    (Color(0xFFFF8A80), Color(0xFFD9605A)),
    (Color(0xFF9C7BEA), Color(0xFF7956D9)),
    (Color(0xFF6CC9A0), Color(0xFF3E9C77)),
    (Color(0xFF6FB1F0), Color(0xFF3F84C6)),
    (Color(0xFFFFC857), Color(0xFFD69E2E)),
    (Color(0xFFF58FC0), Color(0xFFCC5F97)),
  ];

  static (Color, Color) forLetter(String letter) {
    final code = letter.toLowerCase().codeUnitAt(0) - 97;
    return pairs[(code < 0 ? 0 : code) % pairs.length];
  }
}

/// A big rounded letter with a friendly face: the app's letter "character".
class LetterCharacter extends StatelessWidget {
  final String letter;
  final double size;
  final bool face;
  final bool cheer;
  const LetterCharacter(this.letter, {super.key, this.size = 160, this.face = true, this.cheer = false});

  @override
  Widget build(BuildContext context) {
    final (fillC, edge) = LetterColors.forLetter(letter);
    final style = TextStyle(
      fontFamily: AppTokens.letterFont,
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.0,
      color: fillC,
      shadows: [Shadow(color: edge, offset: Offset(0, size * 0.04))],
    );
    final isUpper = letter.toUpperCase() == letter && letter.toLowerCase() != letter;
    return ExcludeSemantics(
      child: SizedBox(
        height: size * 1.05,
        child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
          Text(letter, style: style, textScaler: TextScaler.noScaling),
          if (face)
            Positioned(
              top: size * (isUpper ? 0.38 : 0.52),
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.3,
                child: CustomPaint(painter: _FacePainter(cheer: cheer)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final bool cheer;
  _FacePainter({required this.cheer});
  @override
  void paint(Canvas canvas, Size size) {
    drawFace(canvas, Offset(size.width / 2, size.height / 2), size.width / 40, open: cheer);
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) => oldDelegate.cheer != cheer;
}

/// The friendly purple monster for Feed the Monster. [mouth] 0..1 opens it.
class MonsterArt extends ArtPainter {
  final double mouth;
  final bool happy;
  const MonsterArt({this.mouth = 0.6, this.happy = false});

  @override
  void draw(Canvas c) {
    final body = fill(const Color(0xFF8E6BE8));
    final horn = fill(const Color(0xFFFFC857));
    c.drawPath(roundedPath(const [Offset(22, 26), Offset(16, 6), Offset(32, 20)]), horn);
    c.drawPath(roundedPath(const [Offset(78, 26), Offset(84, 6), Offset(68, 20)]), horn);
    final fur = Path();
    for (var i = 0; i < 18; i++) {
      final a = i * math.pi * 2 / 18;
      fur.addOval(Rect.fromCircle(center: Offset(50 + 38 * math.cos(a), 56 + 36 * math.sin(a)), radius: 9));
    }
    c.drawPath(fur, body);
    c.drawOval(Rect.fromCenter(center: const Offset(50, 56), width: 78, height: 74), body);
    for (final x in [36.0, 64.0]) {
      c.drawCircle(Offset(x, 40), 11, fill(Colors.white));
      c.drawCircle(Offset(x + 1, 42), 6, fill(ink));
      c.drawCircle(Offset(x + 3, 39), 2, fill(Colors.white));
    }
    final h = 6 + 22 * mouth.clamp(0.0, 1.0);
    final m = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(50, 66 + h / 4), width: 40, height: h), Radius.circular(h / 2));
    c.drawRRect(m, fill(const Color(0xFF5A2E7A)));
    if (mouth > 0.3) {
      c.drawOval(Rect.fromCenter(center: Offset(50, 66 + h / 2), width: 18, height: h / 3), fill(const Color(0xFFF58FA8)));
      c.drawRect(Rect.fromLTWH(38, 66 + h / 4 - h / 2, 7, 6), fill(Colors.white));
      c.drawRect(Rect.fromLTWH(55, 66 + h / 4 - h / 2, 7, 6), fill(Colors.white));
    }
    if (happy) {
      c.drawCircle(const Offset(24, 58), 5, fill(blush));
      c.drawCircle(const Offset(76, 58), 5, fill(blush));
    }
  }

  @override
  bool shouldRepaint(covariant MonsterArt oldDelegate) => oldDelegate.mouth != mouth || oldDelegate.happy != happy;
}

/// Little round car carrying a letter.
class CarArt extends StatelessWidget {
  final String label;
  final Color color;
  final double width;
  const CarArt({super.key, required this.label, required this.color, this.width = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.72,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: CustomPaint(painter: _CarPainter(color))),
        Positioned(
          top: width * 0.06,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: width * 0.08),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(width * 0.12)),
            child: Text(label,
                textScaler: TextScaler.noScaling,
                style: TextStyle(fontFamily: AppTokens.letterFont, fontWeight: FontWeight.w700, fontSize: width * 0.26, height: 1.15, color: AppTokens.navy)),
          ),
        ),
      ]),
    );
  }
}

class _CarPainter extends CustomPainter {
  final Color color;
  _CarPainter(this.color);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.34, w, h * 0.42), Radius.circular(h * 0.2));
    final cabin = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.16, h * 0.02, w * 0.68, h * 0.5), Radius.circular(h * 0.22));
    c.drawRRect(cabin, fill(color));
    c.drawRRect(body, fill(color));
    for (final x in [w * 0.06, w * 0.86]) {
      c.drawCircle(Offset(x + w * 0.04, h * 0.5), h * 0.06, fill(const Color(0xFFFFF3B0)));
    }
    for (final x in [w * 0.24, w * 0.76]) {
      c.drawCircle(Offset(x, h * 0.8), h * 0.17, fill(ink));
      c.drawCircle(Offset(x, h * 0.8), h * 0.07, fill(const Color(0xFFDDDDE8)));
    }
    c.drawArc(Rect.fromCenter(center: Offset(w / 2, h * 0.6), width: w * 0.16, height: h * 0.1), 0.3, math.pi - 0.6, false,
        stroke(ink, h * 0.03));
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) => oldDelegate.color != color;
}

/// Arched garage with a letter sign; [highlight] for hints and drop targets.
class GarageArt extends StatelessWidget {
  final String label;
  final Color color;
  final double width;
  final bool highlight;
  final bool filled;
  const GarageArt({super.key, required this.label, required this.color, this.width = 120, this.highlight = false, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: width * 0.9,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(top: Radius.circular(width / 2), bottom: const Radius.circular(12)),
        border: Border.all(color: highlight ? AppTokens.purple : Colors.white, width: highlight ? 5 : 3),
      ),
      child: Column(children: [
        SizedBox(height: width * 0.12),
        Text(label,
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontFamily: AppTokens.letterFont, fontWeight: FontWeight.w700, fontSize: width * 0.3, height: 1.1, color: Colors.white)),
        const Spacer(),
        Container(
          margin: EdgeInsets.symmetric(horizontal: width * 0.12),
          height: width * 0.32,
          decoration: BoxDecoration(
            color: filled ? Colors.white : const Color(0xFF3A3552),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: filled ? const Icon(AppIcons.check, color: AppTokens.success, size: 32) : null,
        ),
      ]),
    );
  }
}

/// Soft mascot (bunny or bear) used on welcome, retry and goodbye screens.
class MascotArt extends ArtPainter {
  final bool bear;
  final bool sleepy;
  const MascotArt({this.bear = false, this.sleepy = false});

  @override
  void draw(Canvas c) {
    final main = fill(bear ? const Color(0xFFC98E5E) : Colors.white);
    final inner = fill(bear ? const Color(0xFFF1CDA8) : const Color(0xFFF8C3CC));
    if (bear) {
      c.drawCircle(const Offset(26, 30), 13, main);
      c.drawCircle(const Offset(74, 30), 13, main);
      c.drawCircle(const Offset(26, 30), 7, inner);
      c.drawCircle(const Offset(74, 30), 7, inner);
    } else {
      for (final x in [36.0, 64.0]) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 22), width: 18, height: 40), const Radius.circular(9)), main);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 24), width: 8, height: 28), const Radius.circular(4)), inner);
      }
    }
    c.drawCircle(const Offset(50, 60), 34, main);
    c.drawCircle(const Offset(50, 60), 34, stroke(const Color(0x22000000), 1.5));
    if (bear) c.drawOval(Rect.fromCenter(center: const Offset(50, 70), width: 30, height: 20), inner);
    drawFace(c, const Offset(50, 62), 1.2, sleepy: sleepy);
    c.drawOval(Rect.fromCenter(center: const Offset(50, 64), width: 7, height: 5), fill(bear ? ink : const Color(0xFFF58FA8)));
  }

  @override
  bool shouldRepaint(covariant MascotArt oldDelegate) => oldDelegate.bear != bear || oldDelegate.sleepy != sleepy;
}

/// Glossy bubble used by Pop the Sound.
class BubbleArt extends ArtPainter {
  final Color color;
  const BubbleArt(this.color);
  @override
  void draw(Canvas c) {
    c.drawCircle(const Offset(50, 50), 46, fill(color));
    c.drawCircle(const Offset(50, 50), 46, stroke(Colors.white.withValues(alpha: 0.8), 3));
    c.drawOval(Rect.fromCenter(center: const Offset(32, 28), width: 20, height: 12), fill(Colors.white.withValues(alpha: 0.7)));
  }

  @override
  bool shouldRepaint(covariant BubbleArt oldDelegate) => oldDelegate.color != color;
}

/// Gentle backdrop for Sound Safari: hill, tree and a little house.
class SafariSceneArt extends ArtPainter {
  const SafariSceneArt();
  @override
  void draw(Canvas c) {
    c.drawOval(const Rect.fromLTWH(-20, 70, 140, 50), fill(const Color(0xFFCDEBC6)));
    c.drawRect(const Rect.fromLTWH(14, 54, 6, 22), fill(const Color(0xFF9C6B47)));
    c.drawCircle(const Offset(17, 48), 13, fill(const Color(0xFF7CC68A)));
    c.drawRect(const Rect.fromLTWH(66, 58, 24, 18), fill(const Color(0xFFFFF1D6)));
    c.drawPath(roundedPath(const [Offset(62, 60), Offset(78, 46), Offset(94, 60)]), fill(const Color(0xFFF2857A)));
    c.drawRect(const Rect.fromLTWH(74, 66, 7, 10), fill(const Color(0xFF9C7BEA)));
  }
}
