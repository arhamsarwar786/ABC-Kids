import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/components/feedback.dart';
import '../../core/design/components/scaffolds.dart';
import '../../data/content/content_catalog.dart';
import '../../data/content/stickers.dart';
import '../../data/models/progress.dart';
import '../../domain/active_time.dart';
import '../../domain/lesson_planner.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';
import '../games/game_framework.dart';
import '../games/game_launcher.dart';
import '../shared/break_reminder.dart';
import '../stickers/sticker_art.dart';
import 'lesson_steps.dart';

/// Creates a plan for [letterId] from the learner's evidence and preferences.
LessonPlan planLesson(BuildContext context, String letterId) {
  final prefs = context.read<LearnerStore>().preferences;
  final progress = context.read<ProgressStore>();
  return LessonPlanner(availabilityOf(context)).plan(
    letterId: letterId,
    prefs: prefs,
    introduced: progress.introducedLetters(),
    recentGames: progress.recentGames,
    labelFor: (d) => progress.label(d, Targets.letter(letterId)),
  );
}

/// True when every game left in a saved lesson can still run (for example
/// the device voice may have been turned off since it was saved).
bool checkpointStillRuns(BuildContext context, SessionCheckpoint cp) {
  final avail = availabilityOf(context);
  final introduced = context.read<ProgressStore>().introducedLetters();
  return cp.plan.steps
      .skip(cp.stepIndex)
      .every((s) => s.kind != LessonStepKind.activity || avail.forGame(s.gameType!, cp.plan.letterId, introduced: introduced).available);
}

Future<void> openLesson(BuildContext context, LessonPlan plan, {int startStep = 0}) {
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(plan: plan, startStep: startStep)));
}

/// Runs one guided lesson. A checkpoint is saved at the start of every step,
/// so leaving at any point can be resumed from Home.
class LessonScreen extends StatefulWidget {
  final LessonPlan plan;
  final int startStep;
  const LessonScreen({super.key, required this.plan, this.startStep = 0});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late int _step = widget.startStep.clamp(0, widget.plan.steps.length - 1);
  late final ProgressStore _progress;
  late final ActiveTimeTracker _timer;
  late final AudioCoordinator _audio;
  StreamSubscription<AppPresence>? _presence;
  bool? _newSticker;

  LessonStep get step => widget.plan.steps[_step];

  @override
  void initState() {
    super.initState();
    _progress = context.read<ProgressStore>();
    _timer = context.read<ActiveTimeTracker>();
    _audio = context.read<AudioCoordinator>();
    _timer.setMinutes(context.read<LearnerStore>().preferences.reminderMinutes);
    _timer.start();
    _presence = _audio.presence.listen((p) => p == AppPresence.background ? _timer.pause() : _timer.start());
    // Writes notify listeners, so they wait until after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _progress.recordExposure(Targets.letter(widget.plan.letterId), 'lesson.${widget.plan.letterId}');
      _enterStep();
    });
  }

  @override
  void dispose() {
    _presence?.cancel();
    _timer.pause();
    super.dispose();
  }

  void _enterStep() {
    if (step.kind == LessonStepKind.completion) {
      _finishLesson();
    } else {
      _progress.saveCheckpoint(widget.plan, _step);
    }
  }

  Future<void> _finishLesson() async {
    final letter = widget.plan.letterId;
    final def = StickerCatalog.forLesson(letter);
    final isNew = await _progress.award(StickerCatalog.lessonAwardId(letter), def.id, 'Finished the ${letter.toUpperCase()} lesson');
    await _progress.completeLesson(letter);
    if (mounted) setState(() => _newSticker = isNew);
  }

  /// Moves on, offering the gentle reminder at this natural boundary.
  Future<void> _next() async {
    if (_timer.reminderDue) {
      _timer.pause();
      final keepGoing = await showBreakReminder(context);
      if (!mounted) return;
      if (!keepGoing) {
        // Checkpoint already points at the step just finished; move it on.
        await _progress.saveCheckpoint(widget.plan, _step + 1);
        _timer.resetSession();
        _goodbye();
        return;
      }
      _timer.acknowledge();
      _timer.start();
    }
    setState(() => _step++);
    _enterStep();
  }

  void _exit() {
    _audio.stopNarration();
    // pop, not maybePop: during a game step the PopScope below blocks
    // maybePop, which left the child on a stopped game.
    Navigator.of(context).pop();
  }

  void _goodbye() {
    _timer.resetSession();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (ctx) => GoodbyeScreen(
        onHome: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
        onPlayAgain: () => Navigator.of(ctx).pop(),
      ),
    ));
  }

  void _nextSound(String letterId) {
    final plan = planLesson(context, letterId);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LessonScreen(plan: plan)));
  }

  @override
  Widget build(BuildContext context) {
    final letter = ContentCatalog.letter(widget.plan.letterId);
    if (letter == null) {
      return ChildScaffold(
        body: ErrorPanel(
          title: 'This lesson isn’t available',
          message: 'Let’s choose another sound.',
          onRetry: _exit,
          retryLabel: 'Back',
        ),
      );
    }
    return PopScope(
      canPop: step.kind != LessonStepKind.activity,
      child: switch (step.kind) {
        LessonStepKind.introduction => SoundIntroStep(letter: letter, onNext: _next, onExit: _exit),
        LessonStepKind.pictureDiscovery => PictureDiscoveryStep(letter: letter, onNext: _next, onExit: _exit),
        LessonStepKind.activity => buildGame(
            GameSpec(
              type: step.gameType!,
              letters: [letter.id],
              distractors: widget.plan.distractorLetterIds,
              level: step.level,
              context: ActivityContext.guidedLesson,
              showIntroDemo: !_progress.recentGames.contains(step.gameType),
            ),
            (result) {
              if (result.exited) {
                _exit();
              } else if (result.endedEarly) {
                _progress.saveCheckpoint(widget.plan, _step + 1).then((_) {
                  if (mounted) _goodbye();
                });
              } else {
                _next();
              }
            },
            key: ValueKey('step$_step'),
          ),
        LessonStepKind.completion =>
          _newSticker == null ? const ChildScaffold(body: Center(child: CircularProgressIndicator())) : _completion(letter.id),
      },
    );
  }

  Widget _completion(String letterId) {
    final prefs = context.read<LearnerStore>().preferences;
    final next = LessonPlanner.nextSound(prefs, _progress.data.completedLessons);
    return LessonCompleteStep(
      letter: ContentCatalog.letter(letterId)!,
      newSticker: _newSticker!,
      stickerArt: StickerArtView(StickerCatalog.forLesson(letterId).id),
      nextLetter: next,
      onNextSound: next == null ? null : () => _nextSound(next),
      onFinish: _goodbye,
    );
  }
}
