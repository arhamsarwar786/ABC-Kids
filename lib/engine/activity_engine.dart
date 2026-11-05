import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/progress.dart';
import 'scheduler.dart';

enum EngineState {
  preparing,
  demonstrating,
  prompting,
  awaitingInput,
  evaluating,
  feedback,
  nextRound,
  completed,
  paused,
  error,
  exited,
}

/// Why a prompt is (re)played.
enum PromptReason { first, replayRequested, afterMistake, withHint, resumed }

enum FeedbackKind { correct, tryAgain }

/// One round. Choice games compare [answer] with the chosen id; task games
/// (build, trace) report completion with [ActivityEngine.completeTask].
class EngineRound {
  final String targetId;
  final String answer;
  final List<String> choices;
  final Object? payload;
  const EngineRound({required this.targetId, this.answer = '', this.choices = const [], this.payload});
}

class RoundResult {
  final EngineRound round;
  final AttemptOutcome outcome;
  final int hintsUsed;
  final int retries;
  final bool demonstrationShown;
  const RoundResult(this.round, this.outcome, {this.hintsUsed = 0, this.retries = 0, this.demonstrationShown = false});
}

class EngineTiming {
  final Duration feedback;
  final Duration demonstration;
  final Duration introDemo;
  const EngineTiming({
    this.feedback = const Duration(milliseconds: 1100),
    this.demonstration = const Duration(milliseconds: 2200),
    this.introDemo = const Duration(milliseconds: 2600),
  });
}

/// Game-agnostic activity state machine.
///
/// * Input is accepted only in [EngineState.awaitingInput]; every answer moves
///   to [EngineState.evaluating] first, which locks out double taps.
/// * Mistakes escalate: replay the prompt → fewer choices / hint →
///   demonstration. Demonstrated rounds never count as independent.
/// * There are no lives and no failure state.
/// * Every delayed step is a cancellable task; pause/exit cancel them all and
///   a generation counter discards late async prompt results.
class ActivityEngine extends ChangeNotifier {
  final List<EngineRound> rounds;
  final bool hasIntroDemo;
  final EngineTiming timing;
  final Scheduler _scheduler;

  /// Plays the prompt. Returns false if essential audio could not be played,
  /// which puts the engine in [EngineState.error] with a retry option.
  final Future<bool> Function(EngineRound round, PromptReason reason)? onPrompt;
  final void Function(RoundResult result) onResult;
  final void Function(FeedbackKind kind)? onFeedback;

  /// Called between rounds (a natural boundary). Return false to finish early.
  final Future<bool> Function()? atBoundary;
  final VoidCallback? onCompleted;

  ActivityEngine({
    required this.rounds,
    required this.onResult,
    this.onPrompt,
    this.onFeedback,
    this.atBoundary,
    this.onCompleted,
    this.hasIntroDemo = false,
    this.timing = const EngineTiming(),
    Scheduler scheduler = const TimerScheduler(),
  })  : assert(rounds.isNotEmpty),
        _scheduler = scheduler;

  EngineState _state = EngineState.preparing;
  EngineState? _stateBeforePause;
  int _index = 0;
  int _wrong = 0;
  int _hints = 0;
  bool _demoShown = false;
  bool _roundResolved = false;
  bool _showAnswer = false;
  bool _endedEarly = false;
  List<String> _visible = [];
  FeedbackKind? _feedback;
  String? _lastWrongChoice;
  int _gen = 0;
  final List<Cancelable> _tasks = [];
  final List<RoundResult> results = [];

  EngineState get state => _state;
  int get roundIndex => _index;
  int get roundCount => rounds.length;
  EngineRound get round => rounds[_index.clamp(0, rounds.length - 1)];
  List<String> get visibleChoices => List.unmodifiable(_visible);
  int get wrongCount => _wrong;

  /// True when the UI should visibly hint at, or demonstrate, the answer.
  bool get showAnswer => _showAnswer;
  FeedbackKind? get feedback => _feedback;
  String? get lastWrongChoice => _lastWrongChoice;
  bool get acceptsInput => _state == EngineState.awaitingInput;
  bool get isFinished => _state == EngineState.completed || _state == EngineState.exited;
  bool get endedEarly => _endedEarly;

  void _set(EngineState s) {
    _state = s;
    notifyListeners();
  }

  void _later(Duration d, VoidCallback f) {
    final gen = _gen;
    _tasks.add(_scheduler.after(d, () {
      if (gen != _gen) return;
      f();
    }));
  }

  void _cancelAll() {
    _gen++;
    for (final t in _tasks) {
      t.cancel();
    }
    _tasks.clear();
  }

  // ----------------------------------------------------------------- flow

  void start() {
    if (_state != EngineState.preparing) return;
    _beginRound();
    if (hasIntroDemo) {
      _set(EngineState.demonstrating);
      _later(timing.introDemo, () => _prompt(PromptReason.first));
    } else {
      _prompt(PromptReason.first);
    }
  }

  /// Skips the introductory demonstration.
  void skipDemo() {
    if (_state != EngineState.demonstrating || _showAnswer) return;
    _cancelAll();
    _prompt(PromptReason.first);
  }

  void _beginRound() {
    _wrong = 0;
    _hints = 0;
    _demoShown = false;
    _roundResolved = false;
    _showAnswer = false;
    _feedback = null;
    _lastWrongChoice = null;
    _visible = List.of(round.choices);
  }

  Future<void> _prompt(PromptReason reason) async {
    _feedback = null;
    _set(EngineState.prompting);
    final gen = _gen;
    var ok = true;
    if (onPrompt != null) {
      try {
        ok = await onPrompt!(round, reason);
      } catch (_) {
        ok = false;
      }
    }
    if (gen != _gen || _state != EngineState.prompting) return;
    _set(ok ? EngineState.awaitingInput : EngineState.error);
  }

  /// Explicit replay by the learner. Replaces the current prompt.
  void replayPrompt() {
    if (_state != EngineState.awaitingInput) return;
    _gen++;
    _prompt(PromptReason.replayRequested);
  }

  void retryAfterError() {
    if (_state != EngineState.error) return;
    _cancelAll();
    _prompt(PromptReason.resumed);
  }

  /// Answer for choice rounds. Ignored unless awaiting input.
  void choose(String choiceId) {
    if (_state != EngineState.awaitingInput) return;
    _set(EngineState.evaluating);
    if (choiceId == round.answer) {
      final outcome = _wrong == 0
          ? AttemptOutcome.correctFirstTry
          : (_hints > 0 ? AttemptOutcome.correctWithHint : AttemptOutcome.correctAfterRetry);
      _resolve(outcome);
      _giveFeedback(FeedbackKind.correct);
      _later(timing.feedback, _advance);
      return;
    }
    _wrong++;
    _lastWrongChoice = choiceId;
    _giveFeedback(FeedbackKind.tryAgain);
    if (_wrong == 1) {
      _later(timing.feedback, () => _prompt(PromptReason.afterMistake));
    } else if (_wrong == 2) {
      _hints++;
      if (_visible.length > 2) {
        _visible.remove(choiceId);
        if (_visible.length > 2) {
          final extra = _visible.firstWhere((c) => c != round.answer);
          _visible.remove(extra);
        }
      } else {
        _showAnswer = true; // gentle highlight when choices cannot shrink
      }
      _later(timing.feedback, () => _prompt(PromptReason.withHint));
    } else {
      _later(timing.feedback, _demonstrate);
    }
  }

  void _demonstrate() {
    _demoShown = true;
    _showAnswer = true;
    _feedback = null;
    _resolve(AttemptOutcome.demonstrated);
    _set(EngineState.demonstrating);
    _later(timing.demonstration, _advance);
  }

  /// Completion of a task round (build/trace). [helped] marks hints/snaps or
  /// replayed demonstrations; [demonstrated] means the task was shown.
  void completeTask({bool helped = false, int hints = 0, bool demonstrated = false}) {
    if (_state != EngineState.awaitingInput) return;
    _set(EngineState.evaluating);
    _hints = hints;
    _demoShown = demonstrated;
    final outcome = demonstrated
        ? AttemptOutcome.demonstrated
        : (helped || hints > 0 ? AttemptOutcome.completedWithHelp : AttemptOutcome.completed);
    _resolve(outcome);
    _giveFeedback(FeedbackKind.correct);
    _later(timing.feedback, _advance);
  }

  /// Task round shown by the app (e.g. learner asked to see it).
  void demonstrateTask() {
    if (_state != EngineState.awaitingInput) return;
    _cancelAll();
    _demonstrate();
  }

  void skipRound() {
    if (_state != EngineState.awaitingInput && _state != EngineState.error) return;
    _cancelAll();
    _resolve(AttemptOutcome.skipped);
    _advance();
  }

  void _resolve(AttemptOutcome outcome) {
    if (_roundResolved) return;
    _roundResolved = true;
    final r = RoundResult(round, outcome, hintsUsed: _hints, retries: _wrong, demonstrationShown: _demoShown);
    results.add(r);
    onResult(r);
  }

  void _giveFeedback(FeedbackKind k) {
    _feedback = k;
    _set(EngineState.feedback);
    onFeedback?.call(k);
  }

  Future<void> _advance() async {
    if (isFinished || _state == EngineState.paused) return;
    _set(EngineState.nextRound);
    if (_index + 1 >= rounds.length) {
      _finish();
      return;
    }
    final gen = _gen;
    if (atBoundary != null) {
      final keepGoing = await atBoundary!();
      if (gen != _gen || _state != EngineState.nextRound) return;
      if (!keepGoing) {
        _endedEarly = true;
        _finish();
        return;
      }
    }
    _index++;
    _beginRound();
    _prompt(PromptReason.first);
  }

  void _finish() {
    _cancelAll();
    _feedback = null;
    _set(EngineState.completed);
    onCompleted?.call();
  }

  // ------------------------------------------------------- pause and exit

  void pause() {
    if (isFinished || _state == EngineState.paused || _state == EngineState.preparing) return;
    _cancelAll();
    _stateBeforePause = _state;
    _set(EngineState.paused);
  }

  /// Explicit resume. Replays the current prompt, keeping retry/hint state.
  void resume() {
    if (_state != EngineState.paused) return;
    final before = _stateBeforePause;
    _stateBeforePause = null;
    if (_roundResolved) {
      _state = EngineState.feedback;
      _advance();
    } else if (before == EngineState.demonstrating && !_demoShown) {
      _prompt(PromptReason.resumed);
    } else {
      _prompt(PromptReason.resumed);
    }
  }

  void exit() {
    if (_state == EngineState.exited) return;
    _cancelAll();
    _set(EngineState.exited);
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
