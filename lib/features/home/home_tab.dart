import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/app_icons.dart';
import '../../core/design/art/art_kit.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/art/word_art.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/chunky.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/tokens.dart';
import '../../data/models/learner.dart';
import '../../domain/lesson_planner.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';
import '../lesson/lesson_screen.dart';
import '../numbers/numbers_hub.dart';
import '../parent/parent_dashboard.dart';
import '../parent/parent_gate.dart';
import '../shapes/shapes_hub.dart';
import '../shell/main_shell.dart';
import '../sound_path/sound_path_screen.dart';

/// Home: a friendly greeting, one big “next adventure” card with progress,
/// and big picture tiles (one word each) to explore.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  void _open(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final learner = context.watch<LearnerStore>().active;
    final progress = context.watch<ProgressStore>();
    final stickers = progress.stickers.length + progress.data.legacyStars;
    return ChildScaffold(
      scene: SceneTheme.meadow,
      scrollable: true,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Entrance(
          child: _Greeting(
            learner: learner,
            stickers: stickers,
            onStickers: () => MainShell.selectTab(context, ShellTab.stickers),
            onGrownUps: () async {
              if (await ParentGate.show(context) && context.mounted) _open(context, const ParentDashboard());
            },
          ),
        ),
        const SizedBox(height: 18),
        Entrance(index: 1, child: _AdventureCard(learner: learner, progress: progress)),
        const SizedBox(height: 22),
        Entrance(
          index: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Let’s explore', style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
        Entrance(
          index: 3,
          child: BigTile(
            label: 'ABC',
            subtitle: 'A to Z',
            color: AppTokens.coral,
            height: 150,
            art: const Row(mainAxisSize: MainAxisSize.min, children: [
              LetterCharacter('A', size: 70, face: false),
              LetterCharacter('B', size: 70, face: false),
              LetterCharacter('C', size: 70, face: false),
            ]),
            onTap: () => MainShell.selectTab(context, ShellTab.abc),
          ),
        ),
        const SizedBox(height: 12),
        Entrance(
          index: 4,
          child: Row(children: [
            Expanded(
              child: BigTile(
                label: 'Sounds',
                subtitle: 'Sound path',
                color: AppTokens.lavender,
                art: const LetterCharacter('s', size: 74),
                onTap: () => _open(context, const SoundPathScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BigTile(
                label: 'Games',
                subtitle: 'Play and learn',
                color: AppTokens.mint,
                art: const Art(MonsterArt(happy: true), size: 84),
                onTap: () => MainShell.selectTab(context, ShellTab.games),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Entrance(
          index: 5,
          child: Row(children: [
            Expanded(
              child: BigTile(
                label: 'Numbers',
                subtitle: '1 to 10',
                color: AppTokens.yellow,
                art: const Row(mainAxisSize: MainAxisSize.min, children: [
                  LetterCharacter('1', size: 52, face: false),
                  LetterCharacter('2', size: 52, face: false),
                  LetterCharacter('3', size: 52, face: false),
                ]),
                onTap: () => _open(context, const NumbersHub()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BigTile(
                label: 'Shapes',
                subtitle: 'Find and match',
                color: AppTokens.blue,
                art: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Art(ShapeArt(ShapeKind.circle, Color(0xFFFF8A80)), size: 40),
                  Art(ShapeArt(ShapeKind.triangle, Color(0xFF6FB1F0)), size: 40),
                  Art(ShapeArt(ShapeKind.square, Color(0xFFFFC857)), size: 40),
                ]),
                onTap: () => _open(context, const ShapesHub()),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

/// Avatar, greeting, sticker count and the grown-ups lock.
class _Greeting extends StatelessWidget {
  final LearnerProfile learner;
  final int stickers;
  final VoidCallback onStickers;
  final VoidCallback onGrownUps;
  const _Greeting({required this.learner, required this.stickers, required this.onStickers, required this.onGrownUps});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(children: [
      Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTokens.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTokens.lavender, width: 3),
          boxShadow: AppTokens.softShadow,
        ),
        child: ExcludeSemantics(
          child: Text(Avatar.byId(learner.avatarId).emoji, style: const TextStyle(fontSize: 34), textScaler: TextScaler.noScaling),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            header: true,
            child: Text('Hi, ${learner.nickname}!', style: t.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text('Ready to play?', style: t.bodyMedium?.copyWith(color: AppTokens.navyMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
      Semantics(
        button: true,
        label: '$stickers stickers',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onStickers,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFE08A), width: 2),
              boxShadow: AppTokens.softShadow,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(AppIcons.star, color: Color(0xFFFFB800), size: 24),
              const SizedBox(width: 4),
              Text('$stickers', style: t.titleLarge?.copyWith(height: 1), textScaler: TextScaler.noScaling),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),
      ChildIconButton(icon: AppIcons.lock, label: 'Grown-ups', onPressed: onGrownUps),
    ]);
  }
}

/// The hero card: next sound (or resume), lesson number, progress and Play.
class _AdventureCard extends StatelessWidget {
  final LearnerProfile learner;
  final ProgressStore progress;
  const _AdventureCard({required this.learner, required this.progress});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final prefs = learner.preferences;
    final cp = progress.validCheckpoint();
    final completed = progress.data.completedLessons;
    final next = LessonPlanner.nextSound(prefs, completed);
    final letter = cp?.plan.letterId ?? next ?? prefs.soundSequence.first;
    final seq = prefs.soundSequence;
    final done = seq.where(completed.contains).length;
    final number = seq.indexOf(letter) + 1;
    const white = Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8063FF), Color(0xFF6440EE), Color(0xFF4E2CCB)],
        ),
        boxShadow: AppTokens.glow(AppTokens.purple),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(children: [
          // Decorative bubbles.
          Positioned(right: -30, top: -40, child: _Bubble(150, white.withValues(alpha: 0.10))),
          Positioned(left: -24, bottom: -50, child: _Bubble(120, white.withValues(alpha: 0.08))),
          Positioned(right: 70, bottom: 12, child: _Bubble(18, white.withValues(alpha: 0.25))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF3A1FB0).withValues(alpha: 0.55), borderRadius: BorderRadius.circular(12)),
                      child: Text(cp != null ? 'Your lesson' : (next == null ? 'Play again' : 'Next sound'),
                          style: t.bodyMedium?.copyWith(color: white, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Letter $letter', style: t.displaySmall?.copyWith(color: white)),
                    ),
                    if (number > 0)
                      Text('Lesson $number of ${seq.length}',
                          style: t.bodyLarge?.copyWith(color: white, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(width: 8),
                Bob(
                  child: Container(
                    width: 108,
                    height: 108,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF3A1FB0).withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))
                      ],
                    ),
                    child: LetterCharacter(letter, size: 92, cheer: true),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _LessonsBar(done: done, total: seq.length),
              const SizedBox(height: 14),
              PrimaryButton(
                label: cp != null ? 'Keep going' : 'Play',
                icon: AppIcons.play,
                inverted: true,
                expand: true,
                onPressed: () async {
                  if (cp != null && checkpointStillRuns(context, cp)) {
                    openLesson(context, cp.plan, startStep: cp.stepIndex);
                    return;
                  }
                  if (cp != null) await progress.clearCheckpoint();
                  if (context.mounted) openLesson(context, planLesson(context, letter));
                },
              ),
              if (cp != null)
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(minimumSize: const Size(0, 48), foregroundColor: white),
                    onPressed: () async {
                      await progress.clearCheckpoint();
                      if (context.mounted) openLesson(context, planLesson(context, letter));
                    },
                    icon: const Icon(AppIcons.replay, size: 20),
                    label: Text('Start again', style: t.titleMedium?.copyWith(color: white)),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LessonsBar extends StatelessWidget {
  final int done;
  final int total;
  const _LessonsBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : done / total;
    return Semantics(
      label: '$done of $total sounds finished',
      excludeSemantics: true,
      child: Row(children: [
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(7)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: frac.clamp(0.04, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFC94A)]),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(AppIcons.star, color: Color(0xFFFFE08A), size: 22),
        const SizedBox(width: 4),
        Text('$done/$total',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white), textScaler: TextScaler.noScaling),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;
  const _Bubble(this.size, this.color);
  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// A big tappable picture tile with one word and a small hint below it.
class BigTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget art;
  final Color color;
  final VoidCallback onTap;
  final double height;
  const BigTile({
    super.key,
    required this.label,
    required this.art,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.height = 158,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Chunky(
        color: color,
        gradient: AppTokens.fill(color),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(children: [
            Positioned(right: -18, top: -18, child: _Bubble(70, Colors.white.withValues(alpha: 0.35))),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(children: [
                Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: art))),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: t.headlineSmall)),
                if (subtitle != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(subtitle!, style: t.bodyMedium?.copyWith(color: AppTokens.navyMuted, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
