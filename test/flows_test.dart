
import 'package:abc_kids_learning/data/content/stickers.dart';
import 'package:abc_kids_learning/data/models/content.dart';
import 'package:abc_kids_learning/data/models/progress.dart';
import 'package:abc_kids_learning/features/games/game_framework.dart';
import 'package:abc_kids_learning/features/games/game_launcher.dart';
import 'package:abc_kids_learning/features/games/games_catalogue.dart';
import 'package:abc_kids_learning/features/home/home_tab.dart';
import 'package:abc_kids_learning/features/lesson/lesson_screen.dart';
import 'package:abc_kids_learning/features/shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const LessonPlan parkingPlan = LessonPlan(letterId: 'm', distractorLetterIds: [], steps: [
  LessonStep(LessonStepKind.introduction),
  LessonStep(LessonStepKind.pictureDiscovery),
  LessonStep(LessonStepKind.activity, gameType: GameType.parking),
  LessonStep(LessonStepKind.completion),
]);

Future<void> tapGarage(WidgetTester tester, String letter) async {
  await tester.tap(find.bySemanticsLabel('garage with letter $letter'));
  await tester.pump();
}

void main() {
  testWidgets('m lesson: intro → discovery → game → completion, sticker and evidence', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(const LessonScreen(plan: parkingPlan)));
    await tester.pump();

    expect(find.text('Meet the sound'), findsOneWidget);
    // No reviewed phoneme: the grown-up prompt is shown, the letter-name
    // recording is not played as a sound.
    expect(find.textContaining('say the sound /m/'), findsOneWidget);
    expect(find.bySemanticsLabel('Hear the sound'), findsNothing);
    expect(app.progress.validCheckpoint()?.stepIndex, 0);

    await tester.tap(find.text('Let’s play'));
    await tester.pump();
    expect(find.text('Listen and discover'), findsOneWidget);
    expect(app.progress.validCheckpoint()?.stepIndex, 1);
    await tester.tap(find.text('moon'));
    await tester.pump();
    expect(app.driver.spoken, contains('moon'));

    await tester.tap(find.text('Play with m'));
    await settleFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.text('I’m ready'));
    await settleFor(tester, const Duration(milliseconds: 300));

    for (var round = 0; round < 4; round++) {
      await tapGarage(tester, 'm');
      await settleFor(tester, const Duration(milliseconds: 1500));
    }
    await settleFor(tester, const Duration(milliseconds: 500));

    expect(find.text('You did it!'), findsOneWidget);
    expect(find.text('New sticker!'), findsOneWidget);
    expect(app.progress.data.completedLessons, contains('m'));
    expect(app.progress.data.stickers.keys, contains(StickerCatalog.lessonAwardId('m')));
    expect(app.progress.validCheckpoint(), isNull);
    final games = app.progress.data.attempts.where((a) => a.gameType == GameType.parking).toList();
    expect(games, hasLength(4));
    expect(games.every((a) => a.domain == SkillDomain.visualMatching && a.context == ActivityContext.guidedLesson), isTrue);
    expect(games.every((a) => a.outcome == AttemptOutcome.correctFirstTry), isTrue);
    // Visual matching is never phonics evidence.
    expect(games.any((a) => a.domain.isPhonics), isFalse);
  });

  testWidgets('leaving mid-lesson saves a checkpoint that Home can resume', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(const HomeTab()));
    await tester.pump();
    expect(find.text('Keep going'), findsNothing);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Meet the sound'), findsOneWidget);
    await tester.tap(find.text('Let’s play'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Start again'), findsOneWidget);
    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('Listen and discover'), findsOneWidget);
  });

  testWidgets('Back during a lesson game leaves the lesson and keeps the checkpoint', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(const HomeTab()));
    await tester.pump();
    final ctx = tester.element(find.byType(HomeTab));
    openLesson(ctx, parkingPlan, startStep: 2);
    await settleFor(tester, const Duration(milliseconds: 500));
    expect(find.byWidgetPredicate((w) => w is GameWidget), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is GameWidget), findsNothing);
    expect(find.text('Keep going'), findsOneWidget);
    expect(app.progress.validCheckpoint()?.stepIndex, 2);

    // System back behaves the same.
    await tester.tap(find.text('Keep going'));
    await settleFor(tester, const Duration(milliseconds: 500));
    expect(find.byWidgetPredicate((w) => w is GameWidget), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is GameWidget), findsNothing);
    expect(find.text('Keep going'), findsOneWidget);
  });

  testWidgets('background pauses the activity; foreground needs explicit resume', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    GameResult? result;
    await tester.pumpWidget(app.wrap(buildGame(
      const GameSpec(type: GameType.parking, letters: ['m'], showIntroDemo: false),
      (r) => result = r,
    )));
    await settleFor(tester, const Duration(milliseconds: 300));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    expect(app.timer.running, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settleFor(tester, const Duration(seconds: 2));
    expect(find.text('Paused'), findsOneWidget, reason: 'resume must be explicit');

    await tester.tap(find.text('Keep playing'));
    await settleFor(tester, const Duration(milliseconds: 300));
    expect(find.text('Paused'), findsNothing);
    await tapGarage(tester, 'm');
    expect(app.progress.data.attempts.where((a) => a.gameType == GameType.parking), hasLength(1));
    expect(result, isNull);
  });

  testWidgets('three wrong answers lead to a demonstration, never independent credit', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(buildGame(
      const GameSpec(type: GameType.parking, letters: ['m'], distractors: ['s', 'a'], showIntroDemo: false),
      (_) {},
    )));
    await settleFor(tester, const Duration(milliseconds: 300));

    for (var i = 0; i < 3; i++) {
      final wrong = find.bySemanticsLabel(RegExp(r'^garage with letter [^m]$'));
      expect(wrong, findsWidgets);
      await tester.tap(wrong.first);
      await settleFor(tester, const Duration(milliseconds: 1300));
    }
    expect(find.textContaining('Here it is'), findsOneWidget);
    final a = app.progress.data.attempts.single;
    expect(a.outcome, AttemptOutcome.demonstrated);
    expect(a.demonstrationShown, isTrue);
    expect(a.outcome.isIndependent, isFalse);
    await settleFor(tester, const Duration(seconds: 3));
  });

  testWidgets('exit from a game cancels it without recording a result', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    GameResult? result;
    await tester.pumpWidget(app.wrap(buildGame(
      const GameSpec(type: GameType.feedMonster, letters: ['m'], showIntroDemo: false),
      (r) => result = r,
    )));
    await settleFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel('Back'));
    await settleFor(tester, const Duration(seconds: 3));
    expect(result?.exited, isTrue);
    expect(app.progress.data.attempts, isEmpty);
  });

  testWidgets('tapping a game starts it straight away (no setup screen)', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(const GamesCatalogue()));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Letter Parking'));
    await settleFor(tester, const Duration(seconds: 4));
    expect(find.bySemanticsLabel(RegExp(r'^garage with letter ')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'^round 1 of ')), findsOneWidget);
  });

  testWidgets('tab bar: four tabs, ABC opens the letter grid, Home ABC tile switches tab', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(const MainShell()));
    await tester.pumpAndSettle();
    for (final t in ['Home, tab 1 of 4', 'ABC, tab 2 of 4', 'Games, tab 3 of 4', 'Stickers, tab 4 of 4']) {
      expect(find.bySemanticsLabel(t), findsOneWidget, reason: t);
    }
    await tester.tap(find.bySemanticsLabel('ABC, tab 2 of 4'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('letter A'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('ABC, tab 2 of 4')), containsSemantics(isSelected: true));
    // No back button on the ABC tab itself.
    expect(find.bySemanticsLabel('Back'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Home, tab 1 of 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('ABC'));
    await tester.pumpAndSettle();
    expect(tester.getSemantics(find.bySemanticsLabel('ABC, tab 2 of 4')), containsSemantics(isSelected: true));
  });
}
