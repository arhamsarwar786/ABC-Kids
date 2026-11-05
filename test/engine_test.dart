import 'package:abc_kids_learning/data/models/progress.dart';
import 'package:abc_kids_learning/engine/activity_engine.dart';
import 'package:abc_kids_learning/engine/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

const rounds = [
  EngineRound(targetId: 'letter:m', answer: 'm', choices: ['m', 's', 'a']),
  EngineRound(targetId: 'letter:s', answer: 's', choices: ['s', 'm', 't']),
];

class Harness {
  final scheduler = ManualScheduler();
  final results = <RoundResult>[];
  final prompts = <PromptReason>[];
  bool promptOk = true;
  bool boundaryContinue = true;
  int completed = 0;
  late final ActivityEngine engine;

  Harness({bool demo = false, List<EngineRound> r = rounds}) {
    engine = ActivityEngine(
      rounds: r,
      scheduler: scheduler,
      hasIntroDemo: demo,
      onResult: results.add,
      onPrompt: (round, reason) async {
        prompts.add(reason);
        return promptOk;
      },
      atBoundary: () async => boundaryContinue,
      onCompleted: () => completed++,
    );
  }

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> runTimers() async {
    for (var i = 0; i < 10; i++) {
      scheduler.runAll();
      await settle();
    }
  }
}

void main() {
  test('first-try answers flow through all states to completion', () async {
    final h = Harness();
    h.engine.start();
    await h.settle();
    expect(h.engine.state, EngineState.awaitingInput);
    h.engine.choose('m');
    expect(h.engine.state, EngineState.feedback);
    expect(h.engine.feedback, FeedbackKind.correct);
    await h.runTimers();
    expect(h.engine.roundIndex, 1);
    expect(h.engine.state, EngineState.awaitingInput);
    h.engine.choose('s');
    await h.runTimers();
    expect(h.engine.state, EngineState.completed);
    expect(h.completed, 1);
    expect(h.results.map((r) => r.outcome), [AttemptOutcome.correctFirstTry, AttemptOutcome.correctFirstTry]);
  });

  test('double taps are locked out while evaluating', () async {
    final h = Harness();
    h.engine.start();
    await h.settle();
    h.engine.choose('m');
    h.engine.choose('m');
    h.engine.choose('s');
    expect(h.results, hasLength(1));
  });

  test('mistakes escalate: replay, then fewer choices, then demonstration', () async {
    final h = Harness();
    h.engine.start();
    await h.settle();

    h.engine.choose('s');
    expect(h.engine.feedback, FeedbackKind.tryAgain);
    await h.runTimers();
    expect(h.prompts.last, PromptReason.afterMistake);
    expect(h.engine.visibleChoices, hasLength(3));

    h.engine.choose('a');
    await h.runTimers();
    expect(h.prompts.last, PromptReason.withHint);
    expect(h.engine.visibleChoices, hasLength(2));
    expect(h.engine.visibleChoices, contains('m'));

    h.engine.choose(h.engine.visibleChoices.firstWhere((c) => c != 'm'));
    h.scheduler.runNext(); // feedback delay → demonstration
    await h.settle();
    expect(h.engine.state, EngineState.demonstrating);
    expect(h.engine.showAnswer, isTrue);
    expect(h.results.single.outcome, AttemptOutcome.demonstrated);
    expect(h.results.single.demonstrationShown, isTrue);
    expect(h.results.single.outcome.isIndependent, isFalse);
    await h.runTimers();
    expect(h.engine.roundIndex, 1);
  });

  test('correct after replay and after hint are assisted, not independent', () async {
    final h = Harness();
    h.engine.start();
    await h.settle();
    h.engine.choose('s');
    await h.runTimers();
    h.engine.choose('m');
    expect(h.results.last.outcome, AttemptOutcome.correctAfterRetry);
    await h.runTimers();
    h.engine.choose('m');
    await h.runTimers();
    h.engine.choose('t');
    await h.runTimers();
    h.engine.choose('s');
    expect(h.results.last.outcome, AttemptOutcome.correctWithHint);
    expect(h.results.last.outcome.isAssisted, isTrue);
  });

  test('pause cancels pending callbacks; explicit resume replays the prompt', () async {
    final h = Harness();
    h.engine.start();
    await h.settle();
    h.engine.choose('s');
    expect(h.scheduler.pending, 1);
    h.engine.pause();
    expect(h.engine.state, EngineState.paused);
    await h.runTimers();
    expect(h.engine.state, EngineState.paused, reason: 'no timer may fire while paused');
    h.engine.choose('m');
    expect(h.results, isEmpty, reason: 'input is ignored while paused');
    h.engine.resume();
    await h.settle();
    expect(h.prompts.last, PromptReason.resumed);
    expect(h.engine.state, EngineState.awaitingInput);
    expect(h.engine.wrongCount, 1, reason: 'retry state survives a pause');
  });

  test('pause after a resolved round continues to the next round on resume', () async {
    final h = Harness();
    h.engine.start();
    await h.settle();
    h.engine.choose('m');
    h.engine.pause();
    h.engine.resume();
    await h.settle();
    expect(h.engine.roundIndex, 1);
    expect(h.results, hasLength(1));
  });

  test('exit cancels timers and ignores late async prompt results', () async {
    final h = Harness();
    h.engine.start();
    h.engine.exit();
    await h.runTimers();
    expect(h.engine.state, EngineState.exited);
    h.engine.choose('m');
    expect(h.results, isEmpty);
  });

  test('failed essential prompt audio leads to error with retry, never success', () async {
    final h = Harness()..promptOk = false;
    h.engine.start();
    await h.settle();
    expect(h.engine.state, EngineState.error);
    h.engine.choose('m');
    expect(h.results, isEmpty);
    h.promptOk = true;
    h.engine.retryAfterError();
    await h.settle();
    expect(h.engine.state, EngineState.awaitingInput);
  });

  test('intro demonstration can be skipped', () async {
    final h = Harness(demo: true);
    h.engine.start();
    expect(h.engine.state, EngineState.demonstrating);
    h.engine.skipDemo();
    await h.settle();
    expect(h.engine.state, EngineState.awaitingInput);
    await h.runTimers();
    expect(h.prompts, [PromptReason.first], reason: 'cancelled demo timer must not prompt again');
  });

  test('boundary can finish early at a natural break', () async {
    final h = Harness()..boundaryContinue = false;
    h.engine.start();
    await h.settle();
    h.engine.choose('m');
    await h.runTimers();
    expect(h.engine.state, EngineState.completed);
    expect(h.engine.endedEarly, isTrue);
    expect(h.results, hasLength(1));
  });

  test('task rounds record completed vs completedWithHelp vs demonstrated', () async {
    final h = Harness(r: const [
      EngineRound(targetId: 'letter:m'),
      EngineRound(targetId: 'letter:s'),
      EngineRound(targetId: 'letter:a'),
    ]);
    h.engine.start();
    await h.settle();
    h.engine.completeTask();
    await h.runTimers();
    h.engine.completeTask(helped: true);
    await h.runTimers();
    h.engine.demonstrateTask();
    await h.runTimers();
    expect(h.results.map((r) => r.outcome), [
      AttemptOutcome.completed,
      AttemptOutcome.completedWithHelp,
      AttemptOutcome.demonstrated,
    ]);
    expect(h.engine.state, EngineState.completed);
  });
}
