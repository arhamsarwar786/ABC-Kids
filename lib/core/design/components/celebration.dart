import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_icons.dart';
import '../tokens.dart';
import 'motion.dart';

/// One-shot confetti burst from the top centre. Purely decorative: ignores
/// touches and is skipped when motion is reduced.
class ConfettiBurst extends StatefulWidget {
  final int pieces;
  final Duration duration;
  const ConfettiBurst({super.key, this.pieces = 70, this.duration = const Duration(milliseconds: 1800)});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final List<_Piece> _pieces;
  bool _skip = false;

  static const _colors = [
    Color(0xFFFF8A80),
    Color(0xFFFFC857),
    Color(0xFF6CC9A0),
    Color(0xFF6FB1F0),
    Color(0xFF9C7BEA),
    Color(0xFFF58FC0),
  ];

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _pieces = List.generate(widget.pieces, (i) {
      final angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1;
      final speed = 0.55 + r.nextDouble() * 0.6;
      return _Piece(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        spin: (r.nextDouble() - 0.5) * 14,
        size: 6 + r.nextDouble() * 7,
        color: _colors[i % _colors.length],
        round: r.nextBool(),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _skip = reduceMotion(context);
    if (!_skip && !_c.isAnimating && _c.value == 0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_skip) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) =>
              _c.isCompleted ? const SizedBox.shrink() : CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _c.value)),
        ),
      ),
    );
  }
}

class _Piece {
  final double vx, vy, spin, size;
  final Color color;
  final bool round;
  const _Piece({required this.vx, required this.vy, required this.spin, required this.size, required this.color, required this.round});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final origin = Offset(s.width / 2, s.height * 0.28);
    final fade = t < 0.7 ? 1.0 : (1 - t) / 0.3;
    for (final p in pieces) {
      final d = s.shortestSide * 0.9;
      final x = origin.dx + p.vx * d * t;
      final y = origin.dy + p.vy * d * t + 0.9 * d * t * t; // gravity
      final paint = Paint()..color = p.color.withValues(alpha: fade.clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), const Radius.circular(2)),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// Soft sun rays behind a reward. Turns slowly for a few seconds, then rests.
class Sunburst extends StatefulWidget {
  final double size;
  final Color color;
  final Widget child;
  const Sunburst({super.key, required this.size, required this.child, this.color = const Color(0xFFFFE08A)});

  @override
  State<Sunburst> createState() => _SunburstState();
}

class _SunburstState extends State<Sunburst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!reduceMotion(context)) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: widget.size,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: RotationTransition(
                turns: Tween(begin: 0.0, end: 0.25).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
                child: CustomPaint(painter: _RaysPainter(widget.color)),
              ),
            ),
          ),
          widget.child,
        ]),
      );
}

class _RaysPainter extends CustomPainter {
  final Color color;
  _RaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.shortestSide / 2;
    canvas.drawCircle(
        c,
        r * 0.62,
        Paint()
          ..shader = RadialGradient(colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c, radius: r * 0.62)));
    final ray = Paint()..color = color.withValues(alpha: 0.45);
    const n = 14;
    for (var i = 0; i < n; i++) {
      final a = i * math.pi * 2 / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.11) * r, c.dy + math.sin(a - 0.11) * r)
        ..lineTo(c.dx + math.cos(a + 0.11) * r, c.dy + math.sin(a + 0.11) * r)
        ..close();
      canvas.drawPath(path, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => old.color != color;
}

/// Row of stars showing rounds: filled for done, glowing for the current one.
class StarTrack extends StatelessWidget {
  final int index;
  final int count;
  const StarTrack({super.key, required this.index, required this.count});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedScale(
              scale: i == index ? 1.2 : 1,
              duration: motion(context, const Duration(milliseconds: 250)),
              child: Icon(
                AppIcons.star,
                size: 26,
                color: i < index ? const Color(0xFFFFC94A) : (i == index ? AppTokens.purple : AppTokens.lavender),
                shadows: i < index ? const [Shadow(color: Color(0x66E0A93A), blurRadius: 6, offset: Offset(0, 2))] : null,
              ),
            ),
          ),
      ]);
}
