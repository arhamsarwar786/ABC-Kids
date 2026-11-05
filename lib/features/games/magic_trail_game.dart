import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/art/stroke_painter.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/tokens.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../../engine/activity_engine.dart';
import '../../state/progress_store.dart';
import '../../core/design/components/scaffolds.dart';
import 'game_framework.dart';
import '../../core/design/app_icons.dart';

/// Pure tracing logic, unit-tested separately from the widget.
class TraceTracker {
  final List<LetterStroke> strokes;
  double tolerance;
  double startRadius;
  int strokeIndex = 0;
  int progress = 0;
  bool active = false;
  final Set<int> done = {};

  TraceTracker(this.strokes, {this.tolerance = 0.13, this.startRadius = 0.13});

  bool get finished => strokeIndex >= strokes.length;
  LetterStroke? get current => finished ? null : strokes[strokeIndex];

  /// Returns true if the touch began close enough to the start.
  bool begin(Offset p) {
    final s = current;
    if (s == null) return false;
    if ((s.start - p).distance > startRadius) return false;
    if (s.kind == StrokeKind.dot) {
      _completeStroke();
      return true;
    }
    active = true;
    progress = 0;
    return true;
  }

  /// Advances along the stroke. Returns false (and cancels the stroke) when
  /// the finger wanders too far from the path.
  bool move(Offset p) {
    final s = current;
    if (!active || s == null) return true;
    var best = progress;
    var bestD = double.infinity;
    final end = math.min(s.points.length - 1, progress + 6);
    for (var i = progress; i <= end; i++) {
      final d = (s.points[i] - p).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (bestD > tolerance) {
      // Allow small detours if the nearest point on the whole stroke is close.
      final anyClose = s.points.any((q) => (q - p).distance <= tolerance);
      if (!anyClose) {
        active = false;
        progress = 0;
        return false;
      }
      return true;
    }
    progress = math.max(progress, best);
    if (progress >= s.points.length - 2) _completeStroke();
    return true;
  }

  void end() {
    if (active) {
      active = false;
      progress = 0;
    }
  }

  void _completeStroke() {
    done.add(strokeIndex);
    strokeIndex++;
    active = false;
    progress = 0;
  }

  void restart() {
    done.clear();
    strokeIndex = 0;
    progress = 0;
    active = false;
  }
}

/// Magic Trail: optional tracing with explicit stroke order, a clear green
/// start, wide tolerance, cancel/restart, a replayable demonstration and Skip.
/// No accuracy scores.
class MagicTrailGame extends GameWidget {
  const MagicTrailGame({super.key, required super.spec, required super.onFinished});
  @override
  State<MagicTrailGame> createState() => _TrailState();
}

class _TrailState extends GameState<MagicTrailGame> with SingleTickerProviderStateMixin {
  late TraceTracker _tracker;
  int _roundSeen = -1;
  bool _demoWatched = false;
  String? _tip;
  late final AnimationController _demo;

  @override
  void initState() {
    _demo = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    super.initState();
  }

  @override
  String get title => 'Magic Trail';

  @override
  SceneTheme get scene => SceneTheme.night;

  @override
  bool get hasReplay => false;

  @override
  List<EngineRound> buildRounds() {
    final letters = widget.spec.letters.where((l) => ContentCatalog.letter(l)?.strokes != null).toList();
    final use = letters.isEmpty ? ['m'] : letters.take(3).toList();
    return [for (final l in use) EngineRound(targetId: Targets.letter(l), payload: l)];
  }

  List<LetterStroke> get _strokes => ContentCatalog.letter(engine.round.payload as String)!.strokes!.strokes;

  void _sync() {
    if (_roundSeen == engine.roundIndex) return;
    _roundSeen = engine.roundIndex;
    _tracker = TraceTracker(_strokes);
    _demoWatched = false;
    _tip = null;
  }

  @override
  SkillDomain domainFor(EngineRound round) => SkillDomain.tracing;

  @override
  String instructionFor(EngineRound round) => 'Trace from the green dot';

  @override
  Future<bool> playPrompt(EngineRound round, PromptReason reason) async {
    if (reason == PromptReason.first && engine.roundIndex == 0) {
      await sayInstruction('Trace from the green dot!');
    }
    return true;
  }

  @override
  void dispose() {
    _demo.dispose();
    super.dispose();
  }

  void _showDemo() {
    _demoWatched = true;
    if (reduceMotion(context)) {
      setState(() => _tip = 'Follow the numbers in order.');
      return;
    }
    _demo.forward(from: 0);
  }

  Offset? _demoDot() {
    if (!_demo.isAnimating) return null;
    final paths = _strokes;
    final total = paths.fold<int>(0, (n, s) => n + s.points.length);
    var at = (_demo.value * (total - 1)).round();
    for (final s in paths) {
      if (at < s.points.length) return s.points[at];
      at -= s.points.length;
    }
    return null;
  }

  void _afterStroke() {
    if (_tracker.finished) {
      audio.playEffect(Effect.chime);
      engine.completeTask(helped: _demoWatched);
    } else {
      audio.playEffect(Effect.pop);
    }
  }

  @override
  Widget buildBoard(BuildContext context) {
    _sync();
    final still = reduceMotion(context);
    return LayoutBuilder(builder: (context, c) {
      final box = math.min(c.maxWidth, c.maxHeight - 180).clamp(120.0, 440.0);
      final frame = LetterFrame(_strokes, Size(box, box));
      Offset unit(Offset local) => frame.toUnit(local);
      // Wide, screen-relative tolerance: a little beyond the visible guide.
      _tracker
        ..tolerance = frame.unitsFor(frame.strokeWidth * 1.4)
        ..startRadius = frame.unitsFor(frame.strokeWidth * 1.3);
      return SingleChildScrollView(
          physics: _tracker.active ? const NeverScrollableScrollPhysics() : null,
          child: Column(children: [
            Semantics(
              label: 'Tracing area for letter ${engine.round.payload}. Stroke ${_tracker.strokeIndex + 1} of ${_strokes.length}.',
              child: GestureDetector(
                onPanStart: (d) {
                  final before = _tracker.strokeIndex;
                  final ok = _tracker.begin(unit(d.localPosition));
                  setState(() => _tip = ok ? null : 'Start at the green dot');
                  if (_tracker.strokeIndex != before) _afterStroke();
                },
                onPanUpdate: (d) {
                  final before = _tracker.strokeIndex;
                  final ok = _tracker.move(unit(d.localPosition));
                  setState(() => _tip = ok ? null : 'Oops, let’s go back to the green dot');
                  if (_tracker.strokeIndex != before) _afterStroke();
                },
                onPanEnd: (_) => setState(_tracker.end),
                onTapUp: (d) {
                  final before = _tracker.strokeIndex;
                  if (_tracker.current?.kind == StrokeKind.dot && _tracker.begin(unit(d.localPosition))) {
                    setState(() {});
                    if (_tracker.strokeIndex != before) _afterStroke();
                  }
                },
                child: Container(
                  width: box,
                  height: box,
                  decoration: BoxDecoration(
                      color: AppTokens.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(color: AppTokens.outline)),
                  child: AnimatedBuilder(
                    animation: _demo,
                    builder: (_, _) => CustomPaint(
                      painter: LetterGuidePainter(
                        strokes: _strokes,
                        done: _tracker.done,
                        currentIndex: _tracker.finished ? null : _tracker.strokeIndex,
                        currentProgress: _tracker.progress,
                        showStart: !_tracker.finished,
                        demoDot: _demoDot(),
                        showNumbers: still && _demoWatched,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: Center(child: Text(_tip ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTokens.gentle))),
            ),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              SecondaryButton(label: 'Show me', icon: AppIcons.playCircleOutline, onPressed: _showDemo),
              SecondaryButton(label: 'Start again', icon: AppIcons.refresh, onPressed: () => setState(_tracker.restart)),
              SecondaryButton(label: 'Skip', icon: AppIcons.skip, onPressed: engine.skipRound),
            ]),
          ]));
    });
  }
}
