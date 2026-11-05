import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/celebration.dart';
import '../../core/design/components/feedback.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../../data/models/learner.dart';
import '../../data/models/progress.dart';
import '../../domain/active_time.dart';
import '../../domain/availability.dart';
import '../../engine/activity_engine.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';
import '../shared/break_reminder.dart';
import '../../core/design/app_icons.dart';

/// What to play: target letters, distractors from introduced sounds, level.
class GameSpec {
  final GameType type;
  final List<String> letters;
  final List<String> distractors;
  final int level;
  final ActivityContext context;
  final bool showIntroDemo;

  const GameSpec({
    required this.type,
    required this.letters,
    this.distractors = const [],
    this.level = 0,
    this.context = ActivityContext.freePlay,
    this.showIntroDemo = true,
  });

  String get activityId => '${type.name}.l$level';
}

class GameResult {
  final bool completed;
  final bool endedEarly;
  final bool exited;
  final List<RoundResult> results;
  const GameResult({this.completed = false, this.endedEarly = false, this.exited = false, this.results = const []});
}

abstract class GameWidget extends StatefulWidget {
  final GameSpec spec;
  final void Function(GameResult result) onFinished;
  const GameWidget({super.key, required this.spec, required this.onFinished});
}

ContentAvailability availabilityOf(BuildContext context) {
  final audio = context.read<AudioCoordinator>();
  return ContentAvailability(assetPlayable: audio.assetPlayable, wordAudio: audio.deviceVoiceUsable);
}

/// Shared behaviour for every game screen.
abstract class GameState<W extends GameWidget> extends State<W> {
  late final ActivityEngine engine;
  late final AudioCoordinator audio;
  late final ProgressStore progress;
  late final ActiveTimeTracker timer;
  late final LearningPreferences prefs;
  final Random random = Random();
  StreamSubscription<AppPresence>? _presenceSub;
  bool _paused = false;
  bool _finished = false;

  // ---- per game
  String get title;
  List<EngineRound> buildRounds();
  String instructionFor(EngineRound round);
  Future<bool> playPrompt(EngineRound round, PromptReason reason);
  SkillDomain domainFor(EngineRound round);
  Widget buildBoard(BuildContext context);
  Widget? buildIntroDemo(BuildContext context) => null;

  /// Illustrated backdrop for this game.
  SceneTheme get scene => SceneTheme.meadow;

  /// Games that override [buildIntroDemo] return true here.
  bool get supportsIntroDemo => false;

  /// Whether the first prompt audio is essential (e.g. a heard sound).
  bool get hasReplay => true;

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioCoordinator>();
    progress = context.read<ProgressStore>();
    timer = context.read<ActiveTimeTracker>();
    prefs = context.read<LearnerStore>().preferences;
    timer.setMinutes(prefs.reminderMinutes);
    engine = ActivityEngine(
      rounds: buildRounds(),
      hasIntroDemo: widget.spec.showIntroDemo && supportsIntroDemo,
      onPrompt: (r, reason) => mounted ? playPrompt(r, reason) : Future.value(false),
      onResult: _record,
      onFeedback: (k) => audio.playEffect(k == FeedbackKind.correct ? Effect.chime : Effect.softTry),
      atBoundary: _atBoundary,
      onCompleted: _completed,
    )..addListener(_onEngine);
    _presenceSub = audio.presence.listen((p) {
      if (p == AppPresence.background) _pause();
    });
    timer.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) engine.start();
    });
  }

  void _onEngine() {
    if (mounted) setState(() {});
  }

  void _record(RoundResult r) {
    progress.record(
      activityId: widget.spec.activityId,
      gameType: widget.spec.type,
      domain: domainFor(r.round),
      targetId: r.round.targetId,
      outcome: r.outcome,
      context: widget.spec.context,
      hintsUsed: r.hintsUsed,
      retries: r.retries,
      demonstrationShown: r.demonstrationShown,
    );
  }

  Future<bool> _atBoundary() async {
    if (!timer.reminderDue || !mounted) return true;
    timer.pause();
    final keepGoing = await showBreakReminder(context);
    if (keepGoing) {
      timer.acknowledge();
      timer.start();
    }
    return keepGoing;
  }

  void _completed() {
    if (_finished) return;
    _finished = true;
    timer.pause();
    audio.stopNarration();
    audio.playEffect(Effect.celebrate);
    progress.notePlayed(widget.spec.type);
    widget.onFinished(GameResult(completed: !engine.endedEarly, endedEarly: engine.endedEarly, results: engine.results));
  }

  void _pause() {
    if (engine.isFinished || _paused) return;
    engine.pause();
    timer.pause();
    audio.stopNarration();
    audio.suspendMusic('activity-paused');
    setState(() => _paused = true);
  }

  void _resume() {
    audio.releaseMusic('activity-paused');
    timer.start();
    setState(() => _paused = false);
    engine.resume();
  }

  void exitGame() {
    if (_finished) return;
    _finished = true;
    engine.exit();
    timer.pause();
    audio.stopNarration();
    audio.releaseMusic('activity-paused');
    widget.onFinished(GameResult(exited: true, results: engine.results));
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    engine.removeListener(_onEngine);
    engine.exit();
    engine.dispose();
    timer.pause();
    audio.stopNarration();
    audio.releaseMusic('activity-paused');
    super.dispose();
  }

  // ---- helpers for games

  /// Speaks an instruction if the device voice is enabled. Never essential.
  Future<bool> sayInstruction(String text) async {
    await audio.speak(text);
    return true;
  }

  Future<bool> playPhoneme(String letterId) async {
    final l = ContentCatalog.letter(letterId);
    final r = await audio.playAsset(AudioManifest.byId(l?.phonemeAudioId));
    return r == PlayResult.played || r == PlayResult.cancelled;
  }

  List<String> pickDistractors(String target, int n, {List<String>? pool}) {
    bool ok(String l) => l != target && !ContentCatalog.lookAlike(l, target);
    final source = [...(pool ?? widget.spec.distractors), ...widget.spec.letters].where(ok).toSet().toList()..shuffle(random);
    if (source.length < n) {
      final extra = ['o', 'e', 'k', 'h', 'a', 's']..removeWhere((l) => !ok(l) || source.contains(l));
      source.addAll(extra.take(n - source.length));
    }
    return source.take(n).toList();
  }

  final Set<String> _usedWords = {};

  /// Target word for [letter] (varied across rounds) plus [n] distractor
  /// words that begin with different sounds, preferring introduced sounds.
  /// Sounds that start the same way (c, k and q: /k/, /kw/) are never
  /// distractors for each other.
  (WordExample, List<WordExample>) wordChoices(String letter, int n) {
    final own = ContentCatalog.wordsFor(letter)..shuffle(random);
    final target = own.firstWhere((w) => !_usedWords.contains(w.id), orElse: () => own.first);
    _usedWords.add(target.id);
    final sound = ContentCatalog.letter(letter)!.soundPolicy.taughtSound;
    final preferred = [...widget.spec.distractors, ...widget.spec.letters].where((l) => l != letter).toSet();
    bool clash(String other) => other == sound || other.substring(1, 2) == sound.substring(1, 2);
    final pool = ContentCatalog.words.where((w) => w.letterId != letter && !clash(w.beginningSound)).toList()..shuffle(random);
    pool.sort((a, b) => (preferred.contains(b.letterId) ? 1 : 0) - (preferred.contains(a.letterId) ? 1 : 0));
    final picked = <WordExample>[];
    for (final w in pool) {
      if (picked.length >= n) break;
      if (picked.any((p) => p.letterId == w.letterId)) continue;
      picked.add(w);
    }
    return (target, picked);
  }

  int choiceCountFor(int roundIndex) {
    if (roundIndex < 2) return 2;
    return prefs.readiness == Readiness.starting && roundIndex < 3 ? 2 : 3;
  }

  TileState tileStateFor(String id) {
    if (engine.showAnswer && id == engine.round.answer) return TileState.hinted;
    if (engine.state == EngineState.feedback && engine.feedback == FeedbackKind.correct && id == engine.round.answer) {
      return TileState.correct;
    }
    if (engine.state == EngineState.feedback && engine.feedback == FeedbackKind.tryAgain && id == engine.lastWrongChoice) {
      return TileState.gentleWrong;
    }
    return TileState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final demo = engine.state == EngineState.demonstrating && !engine.showAnswer ? buildIntroDemo(context) : null;
    Widget body;
    if (engine.state == EngineState.error) {
      body = ErrorPanel(
        title: 'The sound didn’t play',
        message: 'Check the volume, then try again, or do a different activity.',
        onRetry: engine.retryAfterError,
        onAlternative: exitGame,
        alternativeLabel: 'Choose another activity',
      );
    } else if (demo != null) {
      body = Column(children: [
        Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: demo))),
        const SizedBox(height: 12),
        PrimaryButton(label: 'I’m ready', icon: AppIcons.play, onPressed: engine.skipDemo, expand: true),
      ]);
    } else {
      body = Column(children: [
        RoundProgress(index: engine.roundIndex, count: engine.roundCount),
        const SizedBox(height: 10),
        InstructionBanner(
          text: instructionFor(engine.round),
          onReplay: hasReplay && engine.acceptsInput ? engine.replayPrompt : null,
          showReplay: hasReplay,
        ),
        const SizedBox(height: 12),
        Expanded(child: AbsorbPointer(absorbing: !engine.acceptsInput, child: buildBoard(context))),
        SizedBox(
          height: 56,
          child: Center(
            child: switch (engine.state) {
              EngineState.feedback => FeedbackBanner(correct: engine.feedback == FeedbackKind.correct),
              EngineState.demonstrating => const FeedbackBanner(correct: true, text: 'Here it is. Let’s look together.'),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ]);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) exitGame();
      },
      child: Stack(children: [
        ChildScaffold(
          scene: scene,
          // Large text needs more room; below this the screen scrolls.
          minBodyHeight: 470 + (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0.0, 1.5) * 260,
          title: title,
          leading: [BackChildButton(onPressed: exitGame)],
          trailing: [PauseChildButton(onPressed: engine.isFinished ? null : _pause)],
          body: body,
        ),
        if (engine.state == EngineState.feedback && engine.feedback == FeedbackKind.correct)
          Positioned.fill(child: ConfettiBurst(key: ValueKey('confetti${engine.roundIndex}'), pieces: 36)),
        if (_paused) PauseOverlay(onResume: _resume, onFinish: exitGame),
      ]),
    );
  }
}

/// Board area helper: lays out [children] in a responsive wrap.
class ChoiceWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  const ChoiceWrap({super.key, required this.children, this.spacing = 16});

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          child: Wrap(alignment: WrapAlignment.center, spacing: spacing, runSpacing: spacing, children: children),
        ),
      );
}

Color pastelFor(int i) => AppTokens.pastels[i % AppTokens.pastels.length];
