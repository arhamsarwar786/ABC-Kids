import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared drawing helpers for the app's flat, friendly vector style.
/// Painters draw in a 100×100 design space that is scaled to the widget.
abstract class ArtPainter extends CustomPainter {
  const ArtPainter();

  void draw(Canvas c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => oldDelegate.runtimeType != runtimeType;
}

Paint fill(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;

Paint stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

const Color ink = Color(0xFF2A2440);
const Color blush = Color(0x66FF8FA3);

/// Two eyes, a smile and cheeks. [sleepy] draws closed eyes.
void drawFace(Canvas c, Offset center, double scale, {bool sleepy = false, bool open = false}) {
  final dx = 9 * scale, eyeY = center.dy - 3 * scale;
  for (final x in [center.dx - dx, center.dx + dx]) {
    if (sleepy) {
      c.drawArc(Rect.fromCenter(center: Offset(x, eyeY), width: 7 * scale, height: 5 * scale), 0.2, math.pi - 0.4, false,
          stroke(ink, 1.6 * scale));
    } else {
      c.drawCircle(Offset(x, eyeY), 4.8 * scale, fill(Colors.white));
      c.drawCircle(Offset(x, eyeY), 3.4 * scale, fill(ink));
      c.drawCircle(Offset(x + 1.1 * scale, eyeY - 1.2 * scale), 1.1 * scale, fill(Colors.white));
    }
    c.drawCircle(Offset(x + (x < center.dx ? -3 : 3) * scale, eyeY + 6 * scale), 2.6 * scale, fill(blush));
  }
  final mouth = Rect.fromCenter(center: Offset(center.dx, center.dy + 4 * scale), width: 9 * scale, height: 7 * scale);
  if (open) {
    final p = Path()..addArc(mouth, 0, math.pi);
    c.drawPath(p, fill(const Color(0xFFB23A48)));
  } else {
    c.drawArc(mouth, 0.25, math.pi - 0.5, false, stroke(ink, 1.6 * scale));
  }
}

Path roundedPath(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

/// Wraps a painter at a given size with an optional semantics label.
class Art extends StatelessWidget {
  final CustomPainter painter;
  final double size;
  final String? label;
  const Art(this.painter, {super.key, this.size = 96, this.label});

  @override
  Widget build(BuildContext context) {
    final art = SizedBox.square(dimension: size, child: CustomPaint(painter: painter));
    return label == null ? ExcludeSemantics(child: art) : Semantics(image: true, label: label, child: art);
  }
}
