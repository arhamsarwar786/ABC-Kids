import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/content.dart';
import 'art_kit.dart';

/// Stroke thickness relative to the drawing area (not to the letter), so
/// small letters such as s stay readable after being fitted.
const double strokeWidthFactor = 0.07;

/// Maps letter coordinates (unit box) to pixels and back. The letter's own
/// bounds are fitted to [fill] of the area, so every letter is drawn large
/// and centred regardless of where it sits in the unit box.
class LetterFrame {
  final Rect bounds;
  final Size size;
  final double fill;

  LetterFrame(List<LetterStroke> strokes, this.size, {this.fill = 0.62}) : bounds = _bounds(strokes);

  static Rect _bounds(List<LetterStroke> strokes) {
    var r = PiecePainter.bounds(strokes.first);
    for (final s in strokes.skip(1)) {
      r = r.expandToInclude(PiecePainter.bounds(s));
    }
    return r;
  }

  /// Pixels per letter unit.
  double get scale => math.min(size.width, size.height) * fill / math.max(bounds.width, bounds.height).clamp(0.05, 1.0);

  Offset toLocal(Offset unit) => (unit - bounds.center) * scale + Offset(size.width / 2, size.height / 2);

  Offset toUnit(Offset local) => (local - Offset(size.width / 2, size.height / 2)) / scale + bounds.center;

  /// Converts a pixel distance on screen to letter units.
  double unitsFor(double pixels) => pixels / scale;

  double get strokeWidth => math.min(size.width, size.height) * strokeWidthFactor;
}

Path strokePath(LetterStroke s, Offset Function(Offset) map) {
  final pts = s.points.map(map).toList();
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  return p;
}

void paintStroke(Canvas c, LetterStroke s, Offset Function(Offset) map, Paint paint) {
  if (s.kind == StrokeKind.dot) {
    c.drawCircle(map(s.points.first), paint.strokeWidth * 0.62, Paint()..color = paint.color);
  } else {
    c.drawPath(strokePath(s, map), paint);
  }
}

/// Draws the letter as a soft guide, highlights finished strokes and the
/// partly traced current stroke.
class LetterGuidePainter extends CustomPainter {
  final List<LetterStroke> strokes;
  final Set<int> done;
  final Color doneColor;
  final Color guideColor;
  final int? currentIndex;
  final int currentProgress;
  final bool showStart;
  final Offset? demoDot;
  final bool showNumbers;

  LetterGuidePainter({
    required this.strokes,
    this.done = const {},
    this.doneColor = const Color(0xFF9C7BEA),
    this.guideColor = const Color(0xFFE9E4F7),
    this.currentIndex,
    this.currentProgress = 0,
    this.showStart = false,
    this.demoDot,
    this.showNumbers = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final f = LetterFrame(strokes, size);
    final w = f.strokeWidth;
    final guide = stroke(guideColor, w * 1.5);
    for (final s in strokes) {
      paintStroke(canvas, s, f.toLocal, guide);
    }
    final finished = stroke(doneColor, w);
    for (final i in done) {
      paintStroke(canvas, strokes[i], f.toLocal, finished);
    }
    final ci = currentIndex;
    if (ci != null && ci < strokes.length) {
      final s = strokes[ci];
      if (s.kind == StrokeKind.path && currentProgress > 0) {
        final partial = LetterStroke(StrokeKind.path, s.points.sublist(0, math.min(currentProgress + 1, s.points.length)), s.shapeGroup);
        paintStroke(canvas, partial, f.toLocal, finished);
      }
      if (showStart) {
        if (s.kind == StrokeKind.path && s.points.length > 6) {
          // Direction arrow a little way along the stroke, clear of the dot.
          final i = math.min(s.points.length - 1, (s.points.length * 0.3).round());
          _arrow(canvas, f.toLocal(s.points[i - 1]), f.toLocal(s.points[i]), w * 0.45);
        }
        final start = f.toLocal(s.start);
        canvas.drawCircle(start, w * 0.7, fill(const Color(0xFF3FB27F)));
        canvas.drawCircle(start, w * 0.7, stroke(Colors.white, w * 0.18));
      }
    }
    if (showNumbers) {
      for (var i = 0; i < strokes.length; i++) {
        final o = f.toLocal(strokes[i].start);
        canvas.drawCircle(o, w * 0.6, fill(const Color(0xFF7956D9)));
        final tp = TextPainter(
          text: TextSpan(text: '${i + 1}', style: TextStyle(color: Colors.white, fontSize: w * 0.75, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
      }
    }
    if (demoDot != null) {
      final o = f.toLocal(demoDot!);
      canvas.drawCircle(o, w * 0.6, fill(const Color(0xFFFFC857)));
      canvas.drawCircle(o, w * 0.6, stroke(Colors.white, w * 0.15));
    }
  }

  void _arrow(Canvas c, Offset a, Offset b, double size) {
    final dir = b - a;
    if (dir.distance == 0) return;
    final u = dir / dir.distance;
    final tip = b + u * size;
    final left = b + Offset(-u.dy, u.dx) * size * 0.8;
    final right = b - Offset(-u.dy, u.dx) * size * 0.8;
    c.drawPath(roundedPath([tip, left, right]), fill(const Color(0xFF3FB27F)));
  }

  @override
  bool shouldRepaint(covariant LetterGuidePainter o) => true;
}

/// Renders one piece centred in its own box at [scale] pixels per letter unit.
class PiecePainter extends CustomPainter {
  final LetterStroke piece;
  final Color color;
  final double scale;
  final double strokeWidth;
  PiecePainter(this.piece, this.color, {required this.scale, required this.strokeWidth});

  static Rect bounds(LetterStroke s) {
    var minX = s.points.first.dx, maxX = minX, minY = s.points.first.dy, maxY = minY;
    for (final p in s.points) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = bounds(piece).center;
    Offset map(Offset p) => (p - c) * scale + Offset(size.width / 2, size.height / 2);
    paintStroke(canvas, piece, map, stroke(color, strokeWidth));
  }

  @override
  bool shouldRepaint(covariant PiecePainter o) => o.piece != piece || o.color != color || o.scale != scale;
}
