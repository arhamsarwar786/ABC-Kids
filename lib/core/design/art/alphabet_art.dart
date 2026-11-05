import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art_kit.dart';

/// Pictures for the A–Z explorer, in the same flat style as the lesson words.
class AlphabetArt {
  static ArtPainter? forWord(String wordId) => switch (wordId) {
        'w_ball' => const _Ball(),
        'w_cat' => const _Cat(),
        'w_duck' => const _Duck(),
        'w_egg' => const _Egg(),
        'w_fish' => const _Fish(),
        'w_goat' => const _Goat(),
        'w_hat' => const _Hat(),
        'w_igloo' => const _Igloo(),
        'w_jug' => const _Jug(),
        'w_kite' => const _Kite(),
        'w_lion' => const _Lion(),
        'w_octopus' => const _Octopus(),
        'w_quilt' => const _Quilt(),
        'w_rainbow' => const _Rainbow(),
        'w_umbrella' => const _Umbrella(),
        'w_van' => const _Van(),
        'w_whale' => const _Whale(),
        'w_box' => const _Box(),
        'w_yoyo' => const _YoYo(),
        'w_zebra' => const _Zebra(),
        _ => null,
      };
}

class PearArt extends ArtPainter {
  const PearArt();
  @override
  void draw(Canvas c) {
    c.drawLine(const Offset(52, 22), const Offset(56, 8), stroke(const Color(0xFF7A4B2A), 4));
    c.drawOval(Rect.fromCenter(center: const Offset(66, 14), width: 18, height: 9), fill(const Color(0xFF5DB37E)));
    final g = fill(const Color(0xFFB7D96B));
    c.drawCircle(const Offset(50, 34), 16, g);
    c.drawCircle(const Offset(50, 66), 28, g);
    c.drawRect(const Rect.fromLTWH(36, 34, 28, 20), g);
    c.drawCircle(const Offset(40, 60), 6, fill(const Color(0x55FFFFFF)));
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

class _Cat extends ArtPainter {
  const _Cat();
  @override
  void draw(Canvas c) {
    final o = fill(const Color(0xFFF7B267));
    c.drawPath(roundedPath(const [Offset(20, 40), Offset(24, 12), Offset(44, 28)]), o);
    c.drawPath(roundedPath(const [Offset(80, 40), Offset(76, 12), Offset(56, 28)]), o);
    c.drawCircle(const Offset(50, 56), 34, o);
    drawFace(c, const Offset(50, 56), 1.1);
    final w = stroke(const Color(0xFF8A5A44), 1.4);
    for (final dy in [-2.0, 3.0]) {
      c.drawLine(Offset(36, 62 + dy), Offset(16, 60 + dy * 2), w);
      c.drawLine(Offset(64, 62 + dy), Offset(84, 60 + dy * 2), w);
    }
  }
}

class _Duck extends ArtPainter {
  const _Duck();
  @override
  void draw(Canvas c) {
    final y = fill(const Color(0xFFFFD45E));
    c.drawOval(const Rect.fromLTWH(18, 48, 66, 38), y);
    c.drawCircle(const Offset(36, 38), 18, y);
    c.drawPath(roundedPath(const [Offset(14, 38), Offset(24, 34), Offset(24, 44)]), fill(const Color(0xFFF7A54A)));
    c.drawCircle(const Offset(34, 34), 3, fill(ink));
    c.drawArc(const Rect.fromLTWH(46, 54, 30, 22), 0.2, 2.6, false, stroke(const Color(0xFFE8B83E), 3));
    c.drawRect(const Rect.fromLTWH(0, 86, 100, 6), fill(const Color(0xFF9FD0F2)));
  }
}

class _Egg extends ArtPainter {
  const _Egg();
  @override
  void draw(Canvas c) {
    final egg = Path()
      ..moveTo(50, 10)
      ..cubicTo(78, 10, 86, 60, 80, 72)
      ..cubicTo(72, 92, 28, 92, 20, 72)
      ..cubicTo(14, 60, 22, 10, 50, 10);
    c.drawPath(egg, fill(const Color(0xFFFFF4E0)));
    c.drawPath(egg, stroke(const Color(0xFFE2C79A), 2.5));
    c.drawOval(Rect.fromCenter(center: const Offset(38, 36), width: 10, height: 16), fill(Colors.white));
  }
}

class _Fish extends ArtPainter {
  const _Fish();
  @override
  void draw(Canvas c) {
    final b = fill(const Color(0xFF6FB1F0));
    c.drawPath(roundedPath(const [Offset(70, 50), Offset(94, 30), Offset(94, 70)]), b);
    c.drawOval(const Rect.fromLTWH(8, 26, 70, 48), b);
    c.drawArc(const Rect.fromLTWH(30, 30, 20, 40), -1.2, 2.4, false, stroke(const Color(0xFF3F84C6), 3));
    c.drawCircle(const Offset(22, 46), 4, fill(Colors.white));
    c.drawCircle(const Offset(22, 46), 2.2, fill(ink));
  }
}

class _Goat extends ArtPainter {
  const _Goat();
  @override
  void draw(Canvas c) {
    final w = fill(const Color(0xFFF1EDE4));
    final horn = stroke(const Color(0xFFB89466), 5);
    c.drawArc(const Rect.fromLTWH(26, 6, 22, 30), math.pi, 1.6, false, horn);
    c.drawArc(const Rect.fromLTWH(52, 6, 22, 30), -0.6, 1.6, false, horn);
    c.drawOval(const Rect.fromLTWH(10, 30, 22, 12), w);
    c.drawOval(const Rect.fromLTWH(68, 30, 22, 12), w);
    c.drawOval(const Rect.fromLTWH(26, 22, 48, 58), w);
    c.drawOval(const Rect.fromLTWH(26, 22, 48, 58), stroke(const Color(0xFFD8D2C4), 2));
    drawFace(c, const Offset(50, 48), 1);
    c.drawPath(roundedPath(const [Offset(44, 78), Offset(56, 78), Offset(50, 94)]), fill(const Color(0xFFD8D2C4)));
  }
}

class _Hat extends ArtPainter {
  const _Hat();
  @override
  void draw(Canvas c) {
    c.drawOval(const Rect.fromLTWH(6, 58, 88, 22), fill(const Color(0xFF9C7BEA)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, 22, 48, 46), const Radius.circular(16)), fill(const Color(0xFF9C7BEA)));
    c.drawRect(const Rect.fromLTWH(26, 52, 48, 8), fill(const Color(0xFFFFC857)));
  }
}

class _Igloo extends ArtPainter {
  const _Igloo();
  @override
  void draw(Canvas c) {
    c.drawArc(const Rect.fromLTWH(8, 24, 84, 100), math.pi, math.pi, true, fill(const Color(0xFFE3F1FB)));
    final line = stroke(const Color(0xFFB9D6EA), 2);
    for (final y in [44.0, 58.0]) {
      c.drawLine(Offset(16, y), Offset(84, y), line);
    }
    c.drawLine(const Offset(36, 30), const Offset(36, 44), line);
    c.drawLine(const Offset(64, 30), const Offset(64, 44), line);
    c.drawLine(const Offset(50, 44), const Offset(50, 58), line);
    c.drawArc(const Rect.fromLTWH(38, 56, 24, 34), math.pi, math.pi, true, fill(const Color(0xFF6E8BA8)));
    c.drawRect(const Rect.fromLTWH(0, 74, 100, 4), fill(const Color(0xFFB9D6EA)));
  }
}

class _Jug extends ArtPainter {
  const _Jug();
  @override
  void draw(Canvas c) {
    c.drawArc(const Rect.fromLTWH(62, 32, 26, 34), -1.4, 2.8, false, stroke(const Color(0xFF6FB1F0), 7));
    final body = Path()
      ..moveTo(28, 20)
      ..lineTo(68, 20)
      ..lineTo(74, 84)
      ..quadraticBezierTo(50, 92, 22, 84)
      ..close();
    c.drawPath(body, fill(const Color(0xFF6FB1F0)));
    c.drawPath(roundedPath(const [Offset(20, 18), Offset(32, 12), Offset(32, 24)]), fill(const Color(0xFF6FB1F0)));
    c.drawRect(const Rect.fromLTWH(30, 48, 38, 8), fill(Colors.white.withValues(alpha: 0.6)));
  }
}

class _Kite extends ArtPainter {
  const _Kite();
  @override
  void draw(Canvas c) {
    c.drawPath(roundedPath(const [Offset(50, 6), Offset(80, 36), Offset(50, 72), Offset(20, 36)]), fill(const Color(0xFFFF8A80)));
    c.drawPath(roundedPath(const [Offset(50, 6), Offset(80, 36), Offset(50, 36)]), fill(const Color(0xFFFFC857)));
    c.drawPath(roundedPath(const [Offset(20, 36), Offset(50, 72), Offset(50, 36)]), fill(const Color(0xFFFFC857)));
    final tail = Path()
      ..moveTo(50, 72)
      ..quadraticBezierTo(38, 82, 50, 88)
      ..quadraticBezierTo(62, 94, 52, 100);
    c.drawPath(tail, stroke(const Color(0xFF7956D9), 2.5));
  }
}

class _Lion extends ArtPainter {
  const _Lion();
  @override
  void draw(Canvas c) {
    final mane = fill(const Color(0xFFD9893A));
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawCircle(Offset(50 + 32 * math.cos(a), 52 + 32 * math.sin(a)), 13, mane);
    }
    c.drawCircle(const Offset(50, 52), 30, fill(const Color(0xFFFFC56E)));
    drawFace(c, const Offset(50, 52), 1.1);
    c.drawOval(Rect.fromCenter(center: const Offset(50, 60), width: 9, height: 6), fill(const Color(0xFF8A5A44)));
  }
}

class _Octopus extends ArtPainter {
  const _Octopus();
  @override
  void draw(Canvas c) {
    final p = fill(const Color(0xFFC59BF0));
    for (var i = 0; i < 6; i++) {
      final x = 20.0 + i * 12;
      final leg = Path()
        ..moveTo(x, 56)
        ..quadraticBezierTo(x - 6, 76, x + 2, 90);
      c.drawPath(leg, stroke(const Color(0xFFC59BF0), 8));
    }
    c.drawOval(const Rect.fromLTWH(18, 12, 64, 54), p);
    drawFace(c, const Offset(50, 40), 1.1);
  }
}

class _Quilt extends ArtPainter {
  const _Quilt();
  @override
  void draw(Canvas c) {
    const colors = [Color(0xFFFF8A80), Color(0xFF6FB1F0), Color(0xFFFFC857), Color(0xFF6CC9A0), Color(0xFF9C7BEA), Color(0xFFF58FC0)];
    for (var r = 0; r < 3; r++) {
      for (var q = 0; q < 3; q++) {
        c.drawRect(Rect.fromLTWH(14 + q * 24, 14 + r * 24, 24, 24), fill(colors[(r * 3 + q) % colors.length]));
      }
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 14, 72, 72), const Radius.circular(6)), stroke(Colors.white, 3));
  }
}

class _Rainbow extends ArtPainter {
  const _Rainbow();
  @override
  void draw(Canvas c) {
    const colors = [Color(0xFFFF8A80), Color(0xFFFFC857), Color(0xFF6CC9A0), Color(0xFF6FB1F0), Color(0xFF9C7BEA)];
    for (var i = 0; i < colors.length; i++) {
      final r = 42.0 - i * 7;
      c.drawArc(Rect.fromCircle(center: const Offset(50, 76), radius: r), math.pi, math.pi, false, stroke(colors[i], 7)..strokeCap = StrokeCap.butt);
    }
    c.drawCircle(const Offset(14, 78), 9, fill(Colors.white));
    c.drawCircle(const Offset(86, 78), 9, fill(Colors.white));
  }
}

class _Umbrella extends ArtPainter {
  const _Umbrella();
  @override
  void draw(Canvas c) {
    c.drawArc(const Rect.fromLTWH(8, 14, 84, 72), math.pi, math.pi, true, fill(const Color(0xFFF58FC0)));
    c.drawArc(const Rect.fromLTWH(36, 14, 28, 72), math.pi, math.pi, true, fill(const Color(0xFFFFC857)));
    final handle = Path()
      ..moveTo(50, 50)
      ..lineTo(50, 84)
      ..quadraticBezierTo(50, 92, 42, 92)
      ..quadraticBezierTo(36, 92, 36, 86);
    c.drawPath(handle, stroke(const Color(0xFF7A4B2A), 4));
  }
}

class _Van extends ArtPainter {
  const _Van();
  @override
  void draw(Canvas c) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 28, 78, 46), const Radius.circular(10)), fill(const Color(0xFF6CC9A0)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(62, 34, 20, 16), const Radius.circular(4)), fill(const Color(0xFFDDEFFC)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 34, 40, 16), const Radius.circular(4)), fill(const Color(0xFFDDEFFC)));
    for (final x in [26.0, 70.0]) {
      c.drawCircle(Offset(x, 76), 10, fill(ink));
      c.drawCircle(Offset(x, 76), 4, fill(const Color(0xFFDDDDE8)));
    }
  }
}

class _Whale extends ArtPainter {
  const _Whale();
  @override
  void draw(Canvas c) {
    final b = fill(const Color(0xFF6FA8E8));
    c.drawPath(roundedPath(const [Offset(78, 50), Offset(96, 32), Offset(94, 58)]), b);
    c.drawOval(const Rect.fromLTWH(6, 36, 80, 46), b);
    c.drawOval(const Rect.fromLTWH(14, 58, 60, 22), fill(const Color(0xFFDDEFFC)));
    c.drawCircle(const Offset(28, 52), 3, fill(ink));
    final spout = stroke(const Color(0xFF9FD0F2), 3);
    c.drawLine(const Offset(44, 34), const Offset(44, 18), spout);
    c.drawLine(const Offset(44, 20), const Offset(36, 12), spout);
    c.drawLine(const Offset(44, 20), const Offset(52, 12), spout);
  }
}

class _Box extends ArtPainter {
  const _Box();
  @override
  void draw(Canvas c) {
    c.drawPath(roundedPath(const [Offset(12, 34), Offset(50, 22), Offset(88, 34), Offset(50, 46)]), fill(const Color(0xFFE8BE84)));
    c.drawPath(roundedPath(const [Offset(12, 34), Offset(50, 46), Offset(50, 90), Offset(12, 76)]), fill(const Color(0xFFD9A066)));
    c.drawPath(roundedPath(const [Offset(88, 34), Offset(50, 46), Offset(50, 90), Offset(88, 76)]), fill(const Color(0xFFC88E54)));
    c.drawLine(const Offset(31, 28), const Offset(69, 40), stroke(const Color(0xFFB07A44), 4));
  }
}

class _YoYo extends ArtPainter {
  const _YoYo();
  @override
  void draw(Canvas c) {
    c.drawLine(const Offset(50, 4), const Offset(50, 30), stroke(const Color(0xFF7A4B2A), 2));
    c.drawCircle(const Offset(50, 60), 32, fill(const Color(0xFFFF8A80)));
    c.drawCircle(const Offset(50, 60), 20, fill(const Color(0xFFFFC857)));
    c.drawCircle(const Offset(50, 60), 6, fill(const Color(0xFFFF8A80)));
  }
}

class _Zebra extends ArtPainter {
  const _Zebra();
  @override
  void draw(Canvas c) {
    final w = fill(Colors.white);
    c.drawOval(const Rect.fromLTWH(30, 8, 12, 22), w);
    c.drawOval(const Rect.fromLTWH(58, 8, 12, 22), w);
    c.drawOval(const Rect.fromLTWH(24, 18, 52, 68), w);
    c.save();
    c.clipPath(Path()..addOval(const Rect.fromLTWH(24, 18, 52, 68)));
    final s = fill(ink);
    for (final y in [26.0, 38.0, 50.0]) {
      c.drawRect(Rect.fromLTWH(24, y, 12, 5), s);
      c.drawRect(Rect.fromLTWH(64, y, 12, 5), s);
    }
    c.restore();
    c.drawOval(const Rect.fromLTWH(24, 18, 52, 68), stroke(const Color(0xFFBFBFCB), 2));
    c.drawOval(const Rect.fromLTWH(32, 62, 36, 22), fill(const Color(0xFFBFB3C9)));
    drawFace(c, const Offset(50, 48), 0.9);
    c.drawCircle(const Offset(43, 72), 2, fill(ink));
    c.drawCircle(const Offset(57, 72), 2, fill(ink));
  }
}

/// Second lesson pictures, so every letter has at least two words.
class LessonWordArt {
  static ArtPainter? forWord(String wordId) => switch (wordId) {
        'w_banana' => const _Banana(),
        'w_bus' => const _Bus(),
        'w_cup' => const _Cup(),
        'w_door' => const _Door(),
        'w_envelope' => const _Envelope(),
        'w_grapes' => const _Grapes(),
        'w_house' => const _House(),
        'w_jam' => const _Jam(),
        'w_key' => const _Key(),
        'w_leaf' => const _Leaf(),
        'w_olive' => const _Olive(),
        'w_queen' => const _Queen(),
        'w_rocket' => const _Rocket(),
        'w_up' => const _Up(),
        'w_vase' => const _Vase(),
        'w_watermelon' => const _Watermelon(),
        'w_fox' => const _Fox(),
        'w_yoghurt' => const _Yoghurt(),
        'w_zip' => const _Zip(),
        _ => null,
      };
}

class _Banana extends ArtPainter {
  const _Banana();
  @override
  void draw(Canvas c) {
    final p = Path()
      ..moveTo(20, 30)
      ..quadraticBezierTo(30, 82, 84, 70)
      ..quadraticBezierTo(80, 62, 74, 62)
      ..quadraticBezierTo(38, 66, 30, 26)
      ..close();
    c.drawPath(p, fill(const Color(0xFFFFD45E)));
    c.drawPath(p, stroke(const Color(0xFFE0A93A), 2));
    c.drawLine(const Offset(20, 30), const Offset(26, 20), stroke(const Color(0xFF7A4B2A), 5));
  }
}

class _Bus extends ArtPainter {
  const _Bus();
  @override
  void draw(Canvas c) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 22, 84, 54), const Radius.circular(10)), fill(const Color(0xFFFFC857)));
    for (final x in [14.0, 34.0, 54.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 30, 16, 16), const Radius.circular(3)), fill(const Color(0xFFDDEFFC)));
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(74, 30, 12, 30), const Radius.circular(3)), fill(const Color(0xFFDDEFFC)));
    c.drawRect(const Rect.fromLTWH(8, 54, 84, 5), fill(const Color(0xFFF2685C)));
    for (final x in [26.0, 74.0]) {
      c.drawCircle(Offset(x, 78), 10, fill(ink));
      c.drawCircle(Offset(x, 78), 4, fill(const Color(0xFFDDDDE8)));
    }
  }
}

class _Cup extends ArtPainter {
  const _Cup();
  @override
  void draw(Canvas c) {
    c.drawCircle(const Offset(74, 52), 13, stroke(const Color(0xFF6FB1F0), 7));
    final body = Path()
      ..moveTo(20, 30)
      ..lineTo(76, 30)
      ..lineTo(70, 78)
      ..quadraticBezierTo(48, 86, 26, 78)
      ..close();
    c.drawPath(body, fill(const Color(0xFF6FB1F0)));
    c.drawOval(Rect.fromCenter(center: const Offset(48, 30), width: 56, height: 10), fill(const Color(0xFFB98A5E)));
    c.drawCircle(const Offset(36, 52), 5, fill(const Color(0x55FFFFFF)));
  }
}

class _Door extends ArtPainter {
  const _Door();
  @override
  void draw(Canvas c) {
    c.drawRRect(RRect.fromRectAndCorners(const Rect.fromLTWH(24, 10, 52, 82), topLeft: const Radius.circular(26), topRight: const Radius.circular(26)),
        fill(const Color(0xFFB98A5E)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(32, 36, 36, 20), const Radius.circular(4)), fill(const Color(0xFFA0744C)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(32, 62, 36, 22), const Radius.circular(4)), fill(const Color(0xFFA0744C)));
    c.drawCircle(const Offset(66, 58), 4, fill(const Color(0xFFFFD45E)));
  }
}

class _Envelope extends ArtPainter {
  const _Envelope();
  @override
  void draw(Canvas c) {
    const r = Rect.fromLTWH(10, 24, 80, 54);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), fill(const Color(0xFFFFF4E0)));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), stroke(const Color(0xFFE0A93A), 2.5));
    c.drawPath(roundedPath(const [Offset(12, 26), Offset(50, 54), Offset(88, 26)]), fill(const Color(0xFFFFE2A8)));
    c.drawPath(Path()..moveTo(12, 26)..lineTo(50, 54)..lineTo(88, 26), stroke(const Color(0xFFE0A93A), 2.5));
    c.drawCircle(const Offset(50, 54), 6, fill(const Color(0xFFF2685C)));
  }
}

class _Grapes extends ArtPainter {
  const _Grapes();
  @override
  void draw(Canvas c) {
    c.drawLine(const Offset(50, 22), const Offset(54, 8), stroke(const Color(0xFF7A4B2A), 4));
    c.drawOval(Rect.fromCenter(center: const Offset(66, 16), width: 20, height: 10), fill(const Color(0xFF5DB37E)));
    final g = fill(const Color(0xFF9C7BEA));
    for (final o in const [
      Offset(36, 32), Offset(50, 30), Offset(64, 32),
      Offset(43, 46), Offset(57, 46), Offset(36, 60), Offset(50, 60), Offset(64, 60),
      Offset(43, 74), Offset(57, 74), Offset(50, 86),
    ]) {
      c.drawCircle(o, 9, g);
      c.drawCircle(o.translate(-3, -3), 2.5, fill(const Color(0x55FFFFFF)));
    }
  }
}

class _House extends ArtPainter {
  const _House();
  @override
  void draw(Canvas c) {
    c.drawRect(const Rect.fromLTWH(20, 44, 60, 44), fill(const Color(0xFFFFE2A8)));
    c.drawPath(roundedPath(const [Offset(12, 46), Offset(50, 14), Offset(88, 46)]), fill(const Color(0xFFF2685C)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 60, 16, 28), const Radius.circular(3)), fill(const Color(0xFFB98A5E)));
    for (final x in [26.0, 62.0]) {
      c.drawRect(Rect.fromLTWH(x, 54, 12, 12), fill(const Color(0xFFDDEFFC)));
    }
  }
}

class _Jam extends ArtPainter {
  const _Jam();
  @override
  void draw(Canvas c) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 30, 52, 58), const Radius.circular(12)), fill(const Color(0xFFE0526A)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(22, 16, 56, 16), const Radius.circular(4)), fill(const Color(0xFFFFC857)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(32, 46, 36, 26), const Radius.circular(4)), fill(const Color(0xFFFFF4E0)));
    c.drawCircle(const Offset(50, 59), 7, fill(const Color(0xFFE0526A)));
    c.drawCircle(const Offset(30, 40), 4, fill(const Color(0x55FFFFFF)));
  }
}

class _Key extends ArtPainter {
  const _Key();
  @override
  void draw(Canvas c) {
    final gold = fill(const Color(0xFFFFC857));
    c.drawCircle(const Offset(30, 50), 20, gold);
    c.drawCircle(const Offset(30, 50), 8, fill(const Color(0xFFFFF8EE)));
    c.drawRect(const Rect.fromLTWH(46, 45, 42, 10), gold);
    c.drawRect(const Rect.fromLTWH(70, 55, 7, 12), gold);
    c.drawRect(const Rect.fromLTWH(81, 55, 7, 9), gold);
  }
}

class _Leaf extends ArtPainter {
  const _Leaf();
  @override
  void draw(Canvas c) {
    final p = Path()
      ..moveTo(18, 82)
      ..quadraticBezierTo(14, 22, 84, 16)
      ..quadraticBezierTo(84, 80, 18, 82)
      ..close();
    c.drawPath(p, fill(const Color(0xFF6CC9A0)));
    c.drawPath(Path()..moveTo(18, 82)..quadraticBezierTo(50, 52, 78, 22), stroke(const Color(0xFF3E9C72), 3));
    c.drawLine(const Offset(18, 82), const Offset(10, 90), stroke(const Color(0xFF3E9C72), 4));
  }
}

class _Olive extends ArtPainter {
  const _Olive();
  @override
  void draw(Canvas c) {
    c.drawPath(Path()..moveTo(30, 20)..quadraticBezierTo(50, 10, 74, 22), stroke(const Color(0xFF7A4B2A), 3));
    c.drawOval(Rect.fromCenter(center: const Offset(56, 14), width: 18, height: 8), fill(const Color(0xFF8FBF6A)));
    for (final o in const [Offset(36, 56), Offset(64, 62)]) {
      c.drawOval(Rect.fromCenter(center: o, width: 30, height: 40), fill(const Color(0xFF7FA34A)));
      c.drawCircle(o.translate(-6, -8), 4, fill(const Color(0x55FFFFFF)));
    }
    c.drawLine(const Offset(36, 36), const Offset(34, 22), stroke(const Color(0xFF7A4B2A), 2.5));
    c.drawLine(const Offset(64, 42), const Offset(66, 22), stroke(const Color(0xFF7A4B2A), 2.5));
  }
}

class _Queen extends ArtPainter {
  const _Queen();
  @override
  void draw(Canvas c) {
    c.drawCircle(const Offset(50, 58), 28, fill(const Color(0xFFF6C9A0)));
    c.drawPath(
        roundedPath(const [Offset(26, 36), Offset(26, 12), Offset(38, 24), Offset(50, 8), Offset(62, 24), Offset(74, 12), Offset(74, 36)]),
        fill(const Color(0xFFFFC857)));
    for (final x in [38.0, 50.0, 62.0]) {
      c.drawCircle(Offset(x, 30), 3, fill(const Color(0xFFF2685C)));
    }
    drawFace(c, const Offset(50, 60), 1.4);
  }
}

class _Rocket extends ArtPainter {
  const _Rocket();
  @override
  void draw(Canvas c) {
    c.drawPath(roundedPath(const [Offset(34, 62), Offset(20, 82), Offset(38, 76)]), fill(const Color(0xFFF2685C)));
    c.drawPath(roundedPath(const [Offset(66, 62), Offset(80, 82), Offset(62, 76)]), fill(const Color(0xFFF2685C)));
    final body = Path()
      ..moveTo(50, 8)
      ..quadraticBezierTo(74, 30, 66, 78)
      ..lineTo(34, 78)
      ..quadraticBezierTo(26, 30, 50, 8)
      ..close();
    c.drawPath(body, fill(const Color(0xFFDDEFFC)));
    c.drawCircle(const Offset(50, 40), 9, fill(const Color(0xFF6FB1F0)));
    c.drawPath(roundedPath(const [Offset(40, 80), Offset(50, 96), Offset(60, 80)]), fill(const Color(0xFFFFC857)));
  }
}

/// “up”: a balloon floating up with an arrow.
class _Up extends ArtPainter {
  const _Up();
  @override
  void draw(Canvas c) {
    c.drawPath(Path()..moveTo(40, 62)..quadraticBezierTo(34, 76, 42, 92), stroke(ink, 2));
    c.drawOval(Rect.fromCenter(center: const Offset(40, 38), width: 40, height: 48), fill(const Color(0xFFF58FC0)));
    c.drawPath(roundedPath(const [Offset(36, 62), Offset(40, 56), Offset(44, 62)]), fill(const Color(0xFFF58FC0)));
    c.drawCircle(const Offset(32, 28), 5, fill(const Color(0x55FFFFFF)));
    final arrow = stroke(const Color(0xFF6CC9A0), 7);
    c.drawLine(const Offset(78, 84), const Offset(78, 24), arrow);
    c.drawPath(Path()..moveTo(66, 36)..lineTo(78, 22)..lineTo(90, 36), arrow);
  }
}

class _Vase extends ArtPainter {
  const _Vase();
  @override
  void draw(Canvas c) {
    for (final (o, col) in const [(Offset(38, 18), Color(0xFFF59AA8)), (Offset(62, 22), Color(0xFFFFD45E))]) {
      c.drawLine(o, const Offset(50, 46), stroke(const Color(0xFF5DB37E), 3));
      c.drawCircle(o, 9, fill(col));
    }
    final body = Path()
      ..moveTo(38, 42)
      ..lineTo(62, 42)
      ..quadraticBezierTo(60, 54, 72, 66)
      ..quadraticBezierTo(76, 90, 50, 90)
      ..quadraticBezierTo(24, 90, 28, 66)
      ..quadraticBezierTo(40, 54, 38, 42)
      ..close();
    c.drawPath(body, fill(const Color(0xFF6FB1F0)));
    c.drawCircle(const Offset(40, 72), 5, fill(const Color(0x55FFFFFF)));
  }
}

class _Watermelon extends ArtPainter {
  const _Watermelon();
  @override
  void draw(Canvas c) {
    const r = Rect.fromLTWH(8, 4, 84, 84);
    c.drawArc(r, 0, math.pi, true, fill(const Color(0xFF5DB37E)));
    c.drawArc(r.deflate(7), 0, math.pi, true, fill(const Color(0xFFF2685C)));
    for (final o in const [Offset(34, 56), Offset(50, 64), Offset(66, 56), Offset(42, 74), Offset(58, 74)]) {
      c.drawOval(Rect.fromCenter(center: o, width: 4, height: 7), fill(ink));
    }
  }
}

class _Fox extends ArtPainter {
  const _Fox();
  @override
  void draw(Canvas c) {
    final orange = fill(const Color(0xFFF59A4A));
    c.drawPath(roundedPath(const [Offset(22, 40), Offset(26, 10), Offset(44, 30)]), orange);
    c.drawPath(roundedPath(const [Offset(78, 40), Offset(74, 10), Offset(56, 30)]), orange);
    c.drawPath(roundedPath(const [Offset(16, 36), Offset(84, 36), Offset(50, 90)]), orange);
    c.drawCircle(const Offset(50, 46), 26, orange);
    c.drawPath(roundedPath(const [Offset(32, 62), Offset(50, 90), Offset(68, 62), Offset(50, 70)]), fill(const Color(0xFFFFF4E0)));
    drawFace(c, const Offset(50, 50), 1.3);
    c.drawCircle(const Offset(50, 86), 4, fill(ink));
  }
}

class _Yoghurt extends ArtPainter {
  const _Yoghurt();
  @override
  void draw(Canvas c) {
    final pot = Path()
      ..moveTo(22, 36)
      ..lineTo(78, 36)
      ..lineTo(70, 88)
      ..lineTo(30, 88)
      ..close();
    c.drawPath(pot, fill(const Color(0xFFFFF4E0)));
    c.drawPath(pot, stroke(const Color(0xFFDCD0F7), 2.5));
    c.drawRect(const Rect.fromLTWH(26, 52, 48, 14), fill(const Color(0xFFF59AA8)));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 36), width: 60, height: 12), fill(const Color(0xFFFFFFFF)));
    c.drawLine(const Offset(58, 34), const Offset(80, 8), stroke(const Color(0xFFB0B4C8), 6));
  }
}

class _Zip extends ArtPainter {
  const _Zip();
  @override
  void draw(Canvas c) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 8, 64, 86), const Radius.circular(10)), fill(const Color(0xFF6FB1F0)));
    for (var y = 14.0; y < 76; y += 8) {
      c.drawRect(Rect.fromLTWH(44, y, 6, 4), fill(const Color(0xFFDDDDE8)));
      c.drawRect(Rect.fromLTWH(50, y + 4, 6, 4), fill(const Color(0xFFDDDDE8)));
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 70, 16, 12), const Radius.circular(3)), fill(const Color(0xFFFFC857)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(46, 80, 8, 12), const Radius.circular(3)), fill(const Color(0xFFFFC857)));
  }
}
