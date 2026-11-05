import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'alphabet_art.dart';
import 'art_kit.dart';

/// Vector illustrations for picture words, counting objects and shapes.
class WordArt {
  static ArtPainter? forWord(String wordId) => switch (wordId) {
        'w_sun' => const _Sun(),
        'w_sock' => const _Sock(),
        'w_snake' => const _Snake(),
        'w_ant' => const _Ant(),
        'w_apple' => const _Apple(),
        'w_alligator' => const _Alligator(),
        'w_tiger' => const _Tiger(),
        'w_tomato' => const _Tomato(),
        'w_tent' => const _Tent(),
        'w_pear' => const PearArt(),
        'w_pizza' => const _Pizza(),
        'w_penguin' => const _Penguin(),
        'w_insect' => const _Ladybird(),
        'w_ink' => const _Ink(),
        'w_nose' => const _Nose(),
        'w_nut' => const _Nut(),
        'w_net' => const _Net(),
        'w_moon' => const _Moon(),
        'w_mouse' => const _Mouse(),
        'w_monkey' => const _Monkey(),
        'w_flower' => const _Flower(),
        _ => AlphabetArt.forWord(wordId) ?? LessonWordArt.forWord(wordId),
      };

  static const List<String> countingObjects = ['star', 'apple', 'ball', 'flower'];

  static ArtPainter countingObject(String id) => switch (id) {
        'apple' => const _Apple(face: false),
        'ball' => const _Ball(),
        'flower' => const _Flower(),
        _ => const StarArt(),
      };
}

class _Sun extends ArtPainter {
  const _Sun();
  @override
  void draw(Canvas c) {
    final ray = fill(const Color(0xFFFFC94D));
    for (var i = 0; i < 10; i++) {
      c.save();
      c.translate(50, 50);
      c.rotate(i * math.pi / 5);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -46, 8, 13), const Radius.circular(4)), ray);
      c.restore();
    }
    c.drawCircle(const Offset(50, 50), 29, fill(const Color(0xFFFFD966)));
    drawFace(c, const Offset(50, 52), 1.1);
  }
}

class _Moon extends ArtPainter {
  const _Moon();
  @override
  void draw(Canvas c) {
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: const Offset(48, 52), radius: 36)),
      Path()..addOval(Rect.fromCircle(center: const Offset(70, 36), radius: 31)),
    );
    c.drawPath(moon.shift(const Offset(0, 2)), fill(const Color(0x22000000)));
    c.drawPath(moon, fill(const Color(0xFFFFD966)));
    final f = Offset(30, 64);
    c.drawArc(Rect.fromCenter(center: f.translate(-5, -6), width: 6, height: 4), 0.2, math.pi - 0.4, false, stroke(ink, 1.6));
    c.drawArc(Rect.fromCenter(center: f.translate(6, -2), width: 6, height: 4), 0.2, math.pi - 0.4, false, stroke(ink, 1.6));
    c.drawArc(Rect.fromCenter(center: f.translate(2, 6), width: 9, height: 6), 0.3, math.pi - 0.6, false, stroke(ink, 1.6));
    c.drawCircle(f.translate(-6, 2), 2.6, fill(blush));
  }
}

class _Sock extends ArtPainter {
  const _Sock();
  @override
  void draw(Canvas c) {
    final body = Path()
      ..moveTo(36, 14)
      ..lineTo(62, 14)
      ..lineTo(62, 58)
      ..quadraticBezierTo(62, 66, 70, 68)
      ..quadraticBezierTo(86, 72, 84, 84)
      ..quadraticBezierTo(82, 92, 68, 90)
      ..lineTo(46, 86)
      ..quadraticBezierTo(34, 84, 36, 70)
      ..close();
    c.drawPath(body, fill(const Color(0xFF8FB8F0)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(33, 10, 32, 12), const Radius.circular(5)), fill(const Color(0xFFF59AA8)));
    c.drawRect(const Rect.fromLTWH(36, 34, 26, 6), fill(const Color(0xFFF59AA8)));
    c.drawCircle(const Offset(76, 82), 7, fill(const Color(0xFFF59AA8)));
  }
}

class _Snake extends ArtPainter {
  const _Snake();
  @override
  void draw(Canvas c) {
    final body = Path()
      ..moveTo(14, 80)
      ..cubicTo(30, 96, 44, 60, 56, 74)
      ..cubicTo(68, 88, 80, 66, 72, 50)
      ..cubicTo(66, 38, 54, 40, 56, 30);
    c.drawPath(body, stroke(const Color(0xFF6CC48A), 14));
    c.drawPath(body, stroke(const Color(0xFF9EDCB0), 4)..strokeWidth = 4);
    c.drawOval(Rect.fromCenter(center: const Offset(58, 24), width: 26, height: 20), fill(const Color(0xFF6CC48A)));
    c.drawLine(const Offset(70, 26), const Offset(80, 28), stroke(const Color(0xFFE5576B), 2));
    c.drawCircle(const Offset(54, 20), 2.6, fill(ink));
    c.drawCircle(const Offset(63, 20), 2.6, fill(ink));
  }
}

class _Ant extends ArtPainter {
  const _Ant();
  @override
  void draw(Canvas c) {
    final leg = stroke(const Color(0xFF5B3A29), 2.6);
    for (final x in [42.0, 50.0, 58.0]) {
      c.drawLine(Offset(x, 60), Offset(x - 8, 80), leg);
      c.drawLine(Offset(x, 60), Offset(x + 8, 80), leg);
    }
    final body = fill(const Color(0xFF8A5A44));
    c.drawCircle(const Offset(26, 50), 13, body);
    c.drawCircle(const Offset(50, 58), 11, body);
    c.drawOval(Rect.fromCenter(center: const Offset(76, 60), width: 30, height: 24), body);
    c.drawLine(const Offset(22, 39), const Offset(14, 24), leg);
    c.drawLine(const Offset(30, 38), const Offset(34, 22), leg);
    c.drawCircle(const Offset(22, 48), 2.6, fill(Colors.white));
    c.drawCircle(const Offset(22, 48), 1.4, fill(ink));
    c.drawCircle(const Offset(30, 48), 2.6, fill(Colors.white));
    c.drawCircle(const Offset(30, 48), 1.4, fill(ink));
  }
}

class _Apple extends ArtPainter {
  final bool face;
  const _Apple({this.face = true});
  @override
  void draw(Canvas c) {
    c.drawLine(const Offset(50, 30), const Offset(54, 14), stroke(const Color(0xFF7A4B2A), 4));
    c.drawOval(Rect.fromCenter(center: const Offset(66, 18), width: 20, height: 10), fill(const Color(0xFF6CC48A)));
    final red = fill(const Color(0xFFF2685C));
    c.drawCircle(const Offset(38, 56), 28, red);
    c.drawCircle(const Offset(62, 56), 28, red);
    c.drawCircle(const Offset(36, 46), 6, fill(const Color(0x55FFFFFF)));
    if (face) drawFace(c, const Offset(50, 60), 1);
  }
}

class _Alligator extends ArtPainter {
  const _Alligator();
  @override
  void draw(Canvas c) {
    final g = fill(const Color(0xFF6CC48A));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 44, 58, 26), const Radius.circular(13)), g);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 50, 40, 16), const Radius.circular(8)), g);
    for (var x = 10.0; x < 44; x += 7) {
      c.drawPath(roundedPath([Offset(x, 66), Offset(x + 3.5, 71), Offset(x + 7, 66)]), fill(Colors.white));
    }
    c.drawCircle(const Offset(40, 42), 7, g);
    c.drawCircle(const Offset(40, 41), 3, fill(Colors.white));
    c.drawCircle(const Offset(40, 41), 1.6, fill(ink));
    for (final x in [38.0, 76.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 66, 9, 12), const Radius.circular(4)), g);
    }
    c.drawPath(roundedPath(const [Offset(86, 50), Offset(98, 58), Offset(86, 64)]), g);
  }
}

class _Tiger extends ArtPainter {
  const _Tiger();
  @override
  void draw(Canvas c) {
    final o = fill(const Color(0xFFF7A54A));
    c.drawCircle(const Offset(26, 26), 11, o);
    c.drawCircle(const Offset(74, 26), 11, o);
    c.drawCircle(const Offset(50, 54), 36, o);
    final s = stroke(ink, 3);
    c.drawLine(const Offset(50, 20), const Offset(50, 30), s);
    c.drawLine(const Offset(40, 22), const Offset(42, 30), s);
    c.drawLine(const Offset(60, 22), const Offset(58, 30), s);
    c.drawLine(const Offset(16, 52), const Offset(26, 54), s);
    c.drawLine(const Offset(84, 52), const Offset(74, 54), s);
    c.drawOval(Rect.fromCenter(center: const Offset(50, 68), width: 34, height: 22), fill(const Color(0xFFFFF4E6)));
    drawFace(c, const Offset(50, 54), 1.1);
    c.drawOval(Rect.fromCenter(center: const Offset(50, 62), width: 8, height: 5), fill(ink));
  }
}

class _Tomato extends ArtPainter {
  const _Tomato();
  @override
  void draw(Canvas c) {
    c.drawOval(Rect.fromCenter(center: const Offset(50, 58), width: 72, height: 62), fill(const Color(0xFFEE5A4F)));
    final leaf = fill(const Color(0xFF5DB37E));
    for (var i = 0; i < 5; i++) {
      c.save();
      c.translate(50, 30);
      c.rotate(i * 2 * math.pi / 5);
      c.drawOval(const Rect.fromLTWH(-3, -14, 6, 14), leaf);
      c.restore();
    }
    c.drawCircle(const Offset(34, 48), 6, fill(const Color(0x55FFFFFF)));
    drawFace(c, const Offset(50, 62), 1);
  }
}

class _Tent extends ArtPainter {
  const _Tent();
  @override
  void draw(Canvas c) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 82, 88, 6), const Radius.circular(3)), fill(const Color(0xFF9ED39A)));
    c.drawPath(roundedPath(const [Offset(50, 14), Offset(90, 84), Offset(10, 84)]), fill(const Color(0xFFF7A54A)));
    c.drawPath(roundedPath(const [Offset(50, 40), Offset(64, 84), Offset(36, 84)]), fill(const Color(0xFF8A5A44)));
    c.drawLine(const Offset(50, 14), const Offset(50, 6), stroke(const Color(0xFF8A5A44), 3));
    c.drawPath(roundedPath(const [Offset(50, 6), Offset(62, 10), Offset(50, 14)]), fill(const Color(0xFFE5576B)));
  }
}

class _Pizza extends ArtPainter {
  const _Pizza();
  @override
  void draw(Canvas c) {
    final slice = roundedPath(const [Offset(14, 20), Offset(86, 20), Offset(50, 92)]);
    c.drawPath(slice, fill(const Color(0xFFFFD66B)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 12, 80, 14), const Radius.circular(7)), fill(const Color(0xFFD99A5B)));
    // Vegetable toppings: tomato slices, green pepper and olives.
    c.drawCircle(const Offset(36, 38), 7, fill(const Color(0xFFEE5A4F)));
    c.drawCircle(const Offset(62, 40), 6, stroke(const Color(0xFF5DB37E), 3));
    c.drawCircle(const Offset(50, 62), 4, fill(const Color(0xFF34405C)));
    c.drawCircle(const Offset(44, 48), 3, fill(const Color(0xFF34405C)));
  }
}

class _Penguin extends ArtPainter {
  const _Penguin();
  @override
  void draw(Canvas c) {
    c.drawOval(Rect.fromCenter(center: const Offset(50, 54), width: 60, height: 76), fill(const Color(0xFF34405C)));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 62), width: 40, height: 56), fill(Colors.white));
    c.drawCircle(const Offset(42, 38), 3, fill(ink));
    c.drawCircle(const Offset(58, 38), 3, fill(ink));
    c.drawPath(roundedPath(const [Offset(44, 44), Offset(56, 44), Offset(50, 52)]), fill(const Color(0xFFF7A54A)));
    final foot = fill(const Color(0xFFF7A54A));
    c.drawOval(Rect.fromCenter(center: const Offset(40, 92), width: 14, height: 6), foot);
    c.drawOval(Rect.fromCenter(center: const Offset(60, 92), width: 14, height: 6), foot);
  }
}

class _Ladybird extends ArtPainter {
  const _Ladybird();
  @override
  void draw(Canvas c) {
    c.drawLine(const Offset(42, 26), const Offset(36, 14), stroke(ink, 2.4));
    c.drawLine(const Offset(58, 26), const Offset(64, 14), stroke(ink, 2.4));
    c.drawCircle(const Offset(50, 34), 13, fill(ink));
    c.drawCircle(const Offset(50, 60), 32, fill(const Color(0xFFEE5A4F)));
    c.drawLine(const Offset(50, 30), const Offset(50, 92), stroke(ink, 2.4));
    for (final o in const [Offset(36, 50), Offset(64, 50), Offset(34, 70), Offset(66, 70), Offset(50, 80)]) {
      c.drawCircle(o, 5, fill(ink));
    }
  }
}

class _Ink extends ArtPainter {
  const _Ink();
  @override
  void draw(Canvas c) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 42, 52, 46), const Radius.circular(14)), fill(const Color(0xFF5C7FD6)));
    c.drawRect(const Rect.fromLTWH(38, 30, 24, 14), fill(const Color(0xFF5C7FD6)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 20, 32, 12), const Radius.circular(4)), fill(const Color(0xFF34405C)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 58, 40, 18), const Radius.circular(6)), fill(const Color(0xCCFFFFFF)));
    final drop = Path()
      ..moveTo(84, 30)
      ..quadraticBezierTo(92, 44, 84, 48)
      ..quadraticBezierTo(76, 44, 84, 30);
    c.drawPath(drop, fill(const Color(0xFF34405C)));
  }
}

class _Nose extends ArtPainter {
  const _Nose();
  @override
  void draw(Canvas c) {
    c.drawCircle(const Offset(50, 50), 40, fill(const Color(0xFFFFD9B8)));
    c.drawCircle(const Offset(36, 38), 3.4, fill(ink));
    c.drawCircle(const Offset(64, 38), 3.4, fill(ink));
    final nose = Path()
      ..moveTo(50, 36)
      ..quadraticBezierTo(40, 60, 42, 62)
      ..quadraticBezierTo(50, 68, 58, 62)
      ..quadraticBezierTo(60, 60, 50, 36);
    c.drawPath(nose, fill(const Color(0xFFF3A47C)));
    c.drawPath(nose, stroke(const Color(0xFFC7764F), 2));
    c.drawArc(Rect.fromCenter(center: const Offset(50, 74), width: 18, height: 8), 0.3, math.pi - 0.6, false, stroke(ink, 2));
  }
}

class _Nut extends ArtPainter {
  const _Nut();
  @override
  void draw(Canvas c) {
    c.save();
    c.translate(50, 50);
    c.rotate(-0.5);
    final shell = fill(const Color(0xFFE2B57A));
    c.drawOval(const Rect.fromLTWH(-36, -20, 40, 40), shell);
    c.drawOval(const Rect.fromLTWH(-4, -18, 40, 36), shell);
    final dot = fill(const Color(0xFFC8925A));
    for (final o in const [Offset(-22, -6), Offset(-14, 8), Offset(12, -4), Offset(22, 6), Offset(-26, 6), Offset(16, 10)]) {
      c.drawCircle(o, 2.2, dot);
    }
    c.restore();
  }
}

class _Net extends ArtPainter {
  const _Net();
  @override
  void draw(Canvas c) {
    c.drawLine(const Offset(62, 54), const Offset(92, 92), stroke(const Color(0xFF8A5A44), 6));
    final bag = Path()
      ..moveTo(18, 30)
      ..quadraticBezierTo(16, 76, 40, 82)
      ..quadraticBezierTo(60, 80, 66, 46);
    c.drawPath(bag, fill(const Color(0x335C7FD6)));
    final mesh = stroke(const Color(0xFF8FA6D9), 1.4);
    for (var i = 0; i < 5; i++) {
      c.drawLine(Offset(20 + i * 10, 34 + i * 3), Offset(30 + i * 6, 80), mesh);
    }
    c.drawOval(Rect.fromCenter(center: const Offset(42, 38), width: 52, height: 22), stroke(const Color(0xFF5C7FD6), 4));
  }
}

class _Mouse extends ArtPainter {
  const _Mouse();
  @override
  void draw(Canvas c) {
    final grey = fill(const Color(0xFFB8BDCB));
    c.drawCircle(const Offset(26, 30), 18, grey);
    c.drawCircle(const Offset(74, 30), 18, grey);
    c.drawCircle(const Offset(26, 30), 11, fill(const Color(0xFFF8C3CC)));
    c.drawCircle(const Offset(74, 30), 11, fill(const Color(0xFFF8C3CC)));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 60), width: 60, height: 54), grey);
    drawFace(c, const Offset(50, 58), 1);
    c.drawCircle(const Offset(50, 64), 3.4, fill(const Color(0xFFE5576B)));
    final w = stroke(const Color(0xFF7D8396), 1.2);
    for (final dy in [-2.0, 3.0]) {
      c.drawLine(Offset(40, 64 + dy), Offset(22, 62 + dy * 2), w);
      c.drawLine(Offset(60, 64 + dy), Offset(78, 62 + dy * 2), w);
    }
  }
}

class _Monkey extends ArtPainter {
  const _Monkey();
  @override
  void draw(Canvas c) {
    final brown = fill(const Color(0xFFA9714B));
    c.drawCircle(const Offset(16, 50), 12, brown);
    c.drawCircle(const Offset(84, 50), 12, brown);
    c.drawCircle(const Offset(16, 50), 6, fill(const Color(0xFFF1CDA8)));
    c.drawCircle(const Offset(84, 50), 6, fill(const Color(0xFFF1CDA8)));
    c.drawCircle(const Offset(50, 50), 36, brown);
    final face = Path.combine(
      PathOperation.union,
      Path()..addOval(Rect.fromCenter(center: const Offset(40, 46), width: 26, height: 28)),
      Path()..addOval(Rect.fromCenter(center: const Offset(60, 46), width: 26, height: 28)),
    );
    c.drawPath(face, fill(const Color(0xFFF1CDA8)));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 66), width: 40, height: 24), fill(const Color(0xFFF1CDA8)));
    drawFace(c, const Offset(50, 54), 1);
  }
}

class StarArt extends ArtPainter {
  final Color color;
  const StarArt({this.color = const Color(0xFFFFD45E)});
  @override
  void draw(Canvas c) {
    final pts = <Offset>[];
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 44.0 : 20.0;
      final a = -math.pi / 2 + i * math.pi / 5;
      pts.add(Offset(50 + r * math.cos(a), 54 + r * math.sin(a)));
    }
    final p = roundedPath(pts);
    c.drawPath(p, fill(color));
    c.drawPath(p, stroke(const Color(0x33000000), 2));
  }
}

class _Ball extends ArtPainter {
  const _Ball();
  @override
  void draw(Canvas c) {
    c.drawCircle(const Offset(50, 50), 38, fill(const Color(0xFF7FB3F5)));
    c.drawArc(Rect.fromCircle(center: const Offset(50, 50), radius: 38), -0.6, 1.2, true, fill(const Color(0xFFFFD45E)));
    c.drawArc(Rect.fromCircle(center: const Offset(50, 50), radius: 38), 2.5, 1.2, true, fill(const Color(0xFFF2685C)));
    c.drawCircle(const Offset(38, 36), 7, fill(const Color(0x55FFFFFF)));
  }
}

class _Flower extends ArtPainter {
  const _Flower();
  @override
  void draw(Canvas c) {
    final petal = fill(const Color(0xFFF59AA8));
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      c.drawCircle(Offset(50 + 22 * math.cos(a), 50 + 22 * math.sin(a)), 16, petal);
    }
    c.drawCircle(const Offset(50, 50), 15, fill(const Color(0xFFFFD45E)));
  }
}

enum ShapeKind { circle, square, triangle, rectangle }

class ShapeArt extends ArtPainter {
  final ShapeKind kind;
  final Color color;
  const ShapeArt(this.kind, this.color);

  @override
  void draw(Canvas c) {
    final f = fill(color);
    final edge = stroke(const Color(0x33000000), 2.5);
    switch (kind) {
      case ShapeKind.circle:
        c.drawCircle(const Offset(50, 50), 40, f);
        c.drawCircle(const Offset(50, 50), 40, edge);
      case ShapeKind.square:
        final r = RRect.fromRectAndRadius(const Rect.fromLTWH(12, 12, 76, 76), const Radius.circular(8));
        c.drawRRect(r, f);
        c.drawRRect(r, edge);
      case ShapeKind.triangle:
        final p = roundedPath(const [Offset(50, 10), Offset(92, 86), Offset(8, 86)]);
        c.drawPath(p, f);
        c.drawPath(p, edge);
      case ShapeKind.rectangle:
        final r = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 28, 92, 46), const Radius.circular(8));
        c.drawRRect(r, f);
        c.drawRRect(r, edge);
    }
  }

  @override
  bool shouldRepaint(covariant ShapeArt oldDelegate) => oldDelegate.kind != kind || oldDelegate.color != color;
}
