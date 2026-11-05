import 'package:flutter/material.dart';

import '../tokens.dart';
import 'motion.dart';

/// Chunky, tactile surface: a gradient face sitting on a darker lip, with a
/// soft coloured glow. The face sinks onto the lip while pressed, like a
/// real button. Used by buttons, big tiles and cards on child screens.
///
/// Semantics are left to the caller.
class Chunky extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Gradient? gradient;
  final Color? lipColor;
  final double radius;
  final bool circle;
  final Border? border;
  final bool glow;
  final double lip;

  const Chunky({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppTokens.surface,
    this.gradient,
    this.lipColor,
    this.radius = AppTokens.radius,
    this.circle = false,
    this.border,
    this.glow = true,
    this.lip = AppTokens.lip,
  });

  @override
  State<Chunky> createState() => _ChunkyState();
}

class _ChunkyState extends State<Chunky> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final lipColor = widget.lipColor ?? AppTokens.lipFor(widget.color);
    final pressed = _down && enabled;
    final drop = pressed ? widget.lip - 1.5 : 0.0;
    final shape = widget.circle ? BoxShape.circle : BoxShape.rectangle;
    final radius = widget.circle ? null : BorderRadius.circular(widget.radius);
    final d = motion(context, const Duration(milliseconds: 70));
    return Padding(
      padding: EdgeInsets.only(bottom: widget.lip),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: d,
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, drop, 0),
          decoration: BoxDecoration(
            color: widget.gradient == null ? widget.color : null,
            gradient: widget.gradient,
            shape: shape,
            borderRadius: radius,
            border: widget.border,
            boxShadow: [
              // The lip: a hard shadow straight below the face.
              BoxShadow(color: lipColor, offset: Offset(0, widget.lip - drop), blurRadius: 0),
              if (widget.glow && !pressed) ...AppTokens.glow(widget.color),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius ?? BorderRadius.circular(999),
            child: Stack(fit: StackFit.passthrough, children: [
              // Soft top highlight for a glossy, rounded look.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 18,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
              widget.child,
            ]),
          ),
        ),
      ),
    );
  }
}
