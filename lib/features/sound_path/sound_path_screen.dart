import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/art/characters.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../domain/lesson_planner.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';
import '../alphabet/alphabet_screen.dart';
import '../lesson/lesson_screen.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/components/motion.dart';

/// The guided sound path (new / explored / practising). In guided mode,
/// sounds after the next one are shown but wait ("coming later"); in free
/// play every sound with lesson content can be opened.
class SoundPathScreen extends StatelessWidget {
  const SoundPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<LearnerStore>().preferences;
    final progress = context.watch<ProgressStore>();
    final seq = prefs.soundSequence.where(ContentCatalog.hasLessonContent).toList();
    final next = LessonPlanner.nextSound(prefs, progress.data.completedLessons);
    final nextIndex = next == null ? seq.length : seq.indexOf(next);
    final continueLetter = next ?? seq.last;

    return ChildScaffold(
      title: 'My sound path',
      scene: SceneTheme.meadow,
      leading: const [BackChildButton()],
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryButton(
          label: next == null ? 'Practise ${seq.last}' : 'Continue with $continueLetter',
          icon: AppIcons.forward,
          expand: true,
          onPressed: () => openLesson(context, planLesson(context, continueLetter)),
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: 'Explore all letters',
          icon: AppIcons.grid,
          expand: true,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlphabetScreen())),
        ),
      ]),
      body: LayoutBuilder(builder: (context, c) {
        final node = math.min(84.0, c.maxWidth / 4.2);
        final rowH = node + 18;
        final height = math.max(c.maxHeight, seq.length * rowH + 40);
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _PathLine(count: seq.length, node: node, rowH: rowH))),
              for (var i = 0; i < seq.length; i++)
                Positioned(
                  top: i * rowH + 8,
                  left: _x(i, c.maxWidth, node),
                  child: Pulse(
                    active: i == nextIndex,
                    child: PathNode(
                      letter: seq[i],
                      size: node,
                      status: progress.pathStatus(seq[i]),
                      current: i == nextIndex,
                      enabled: LessonPlanner.isOpen(prefs, progress.data.completedLessons, seq[i]),
                      onTap: () => openLesson(context, planLesson(context, seq[i])),
                    ),
                  ),
                ),
              if (nextIndex < seq.length)
                Positioned(
                  top: nextIndex * rowH + 8,
                  left: _x(nextIndex, c.maxWidth, node) + (nextIndex.isEven ? node + 10 : -node * 0.9),
                  child: LetterCharacter(seq[nextIndex], size: node * 0.75, cheer: true),
                ),
            ]),
          ),
        );
      }),
    );
  }

  static double _x(int i, double width, double node) {
    const pattern = [0.12, 0.42, 0.68, 0.42];
    return (width - node) * pattern[i % pattern.length] / 0.8;
  }
}

class _PathLine extends CustomPainter {
  final int count;
  final double node;
  final double rowH;
  _PathLine({required this.count, required this.node, required this.rowH});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final p = Path();
    for (var i = 0; i < count; i++) {
      final o = Offset(SoundPathScreen._x(i, size.width, node) + node / 2, i * rowH + 8 + node / 2);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
        p,
        Paint()
          ..color = AppTokens.lavender
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _PathLine o) => o.count != count || o.node != node;
}
