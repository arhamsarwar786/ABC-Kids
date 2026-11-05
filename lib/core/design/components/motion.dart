import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../state/settings_store.dart';

/// True when the system or the parent setting asks for reduced motion.
bool reduceMotion(BuildContext context) {
  final system = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  final store = Provider.of<SettingsStore?>(context, listen: true);
  return system || (store?.settings.reduceMotion ?? false);
}

Duration motion(BuildContext context, Duration normal) => reduceMotion(context) ? Duration.zero : normal;

/// Slides and fades [child] in, staggered by [index], once on first build.
class Entrance extends StatefulWidget {
  final Widget child;
  final int index;
  final double offset;
  const Entrance({super.key, required this.child, this.index = 0, this.offset = 24});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final int _delay = 60 * widget.index.clamp(0, 8);
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: 420 + _delay));
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Interval(_delay / (420 + _delay), 1));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    reduceMotion(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final t = Curves.easeOutBack.transform(_t.value);
          return Opacity(
            // Labels stay available to screen readers while fading in.
            alwaysIncludeSemantics: true,
            opacity: Curves.easeOut.transform(_t.value),
            child: Transform.translate(offset: Offset(0, (1 - t) * widget.offset), child: child),
          );
        },
        child: widget.child,
      );
}

/// Gentle float up and down. Stops after a few cycles so it never
/// distracts for long (and screens settle).
class Bob extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final int cycles;
  const Bob({super.key, required this.child, this.amplitude = 6, this.cycles = 4});

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!reduceMotion(context)) _c.repeat(count: widget.cycles);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, -math.sin(_c.value * math.pi * 2) * widget.amplitude), child: child),
        child: widget.child,
      );
}

/// Scales [child] in with a springy pop, once.
class PopIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final int _delay = widget.delay.inMilliseconds;
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: 650 + _delay));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    reduceMotion(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: CurvedAnimation(parent: _c, curve: Interval(_delay / (650 + _delay), 1, curve: Curves.elasticOut)),
        child: widget.child,
      );
}

/// A soft pulse to draw the eye (e.g. the next sound). Pulses a few times.
class Pulse extends StatefulWidget {
  final Widget child;
  final bool active;
  const Pulse({super.key, required this.child, this.active = true});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.active && !reduceMotion(context)) _c.repeat(reverse: true, count: 6);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.07).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}
