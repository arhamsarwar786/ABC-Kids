import 'package:abc_kids_learning/core/design/art/word_art.dart';
import 'package:abc_kids_learning/data/content/content_catalog.dart';
import 'package:abc_kids_learning/data/content/letter_strokes.dart';
import 'package:abc_kids_learning/data/models/content.dart';
import 'package:abc_kids_learning/data/models/learner.dart';
import 'package:abc_kids_learning/data/models/progress.dart';
import 'package:abc_kids_learning/domain/availability.dart';
import 'package:abc_kids_learning/domain/lesson_planner.dart';
import 'package:abc_kids_learning/engine/activity_engine.dart';
import 'package:abc_kids_learning/features/alphabet/alphabet_screen.dart';
import 'package:abc_kids_learning/features/games/game_framework.dart';
import 'package:abc_kids_learning/features/games/game_launcher.dart';
import 'package:abc_kids_learning/features/games/games_catalogue.dart';
import 'package:abc_kids_learning/features/games/magic_trail_game.dart';
import 'package:abc_kids_learning/features/home/home_tab.dart';
import 'package:abc_kids_learning/features/lesson/lesson_screen.dart';
import 'package:abc_kids_learning/features/sound_path/sound_path_screen.dart';
import 'package:abc_kids_learning/state/progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const az = 'abcdefghijklmnopqrstuvwxyz';

ContentAvailability bundled({bool wordAudio = true}) =>
    ContentAvailability(assetPlayable: (a) => a != null && a.hasFile, wordAudio: wordAudio);

/// Drives whatever is on screen in a lesson until it reaches “You did it!”.
Future<void> playLessonThrough(WidgetTester tester) async {
  for (var guard = 0; guard < 120; guard++) {
    if (find.text('You did it!').evaluate().isNotEmpty) return;
    if (find.text('Let’s play').evaluate().isNotEmpty) {
      await tester.tap(find.text('Let’s play'));
    } else if (find.textContaining('Play with ').evaluate().isNotEmpty) {
      await tester.tap(find.textContaining('Play with '));
    } else {
      final games = find.byWidgetPredicate((w) => w is GameWidget);
      if (games.evaluate().isNotEmpty) {
        final e = tester.state<GameState>(games).engine;
        if (e.state == EngineState.demonstrating && !e.showAnswer) {
          e.skipDemo();
        } else if (e.acceptsInput) {
          e.round.choices.isEmpty ? e.completeTask() : e.choose(e.round.answer);
        }
      }
    }
    await settleFor(tester, const Duration(milliseconds: 1300));
  }
  fail('lesson did not finish');
}

void main() {
  group('content for every letter', () {
    test('a–z all have a guided lesson', () {
      for (final l in az.split('')) {
        expect(ContentCatalog.hasLessonContent(l), isTrue, reason: l);
      }
    });

    test('every letter has two or more pictures, each with its own illustration', () {
      for (final l in az.split('')) {
        final pics = ContentCatalog.pictureWordsFor(l);
        expect(pics.length, greaterThanOrEqualTo(2), reason: l);
        for (final w in pics) {
          expect(w.letterId, l);
          expect(WordArt.forWord(w.id), isNotNull, reason: 'no illustration for ${w.text}');
        }
      }
    });

    test('lesson words start with the taught sound; x pictures say it is at the end', () {
      for (final l in ContentCatalog.letters) {
        for (final w in ContentCatalog.wordsFor(l.id)) {
          expect(w.beginningSound, l.soundPolicy.taughtSound, reason: w.text);
        }
      }
      expect(ContentCatalog.wordsFor('x'), isEmpty);
      expect(ContentCatalog.pictureWordsFor('x').every(ContentCatalog.soundNotAtStart), isTrue);
      expect(ContentCatalog.words.map((w) => w.id).toSet().length, ContentCatalog.words.length);
    });

    test('every letter has stroke shapes inside the box; same-group pieces match', () {
      for (final l in az.split('')) {
        final strokes = LetterStrokeLibrary.all[l]?.strokes;
        expect(strokes, isNotNull, reason: l);
        final byGroup = <String, List<LetterStroke>>{};
        for (final s in strokes!) {
          for (final p in s.points) {
            expect(p.dx, inInclusiveRange(0, 1), reason: l);
            expect(p.dy, inInclusiveRange(0, 1), reason: l);
          }
          byGroup.putIfAbsent(s.shapeGroup, () => []).add(s);
        }
        for (final g in byGroup.values) {
          for (final s in g.skip(1)) {
            final d = s.points.first - g.first.points.first;
            expect(s.points.length, g.first.points.length, reason: '$l ${s.shapeGroup}');
            for (var i = 0; i < s.points.length; i++) {
              expect((s.points[i] - d - g.first.points[i]).distance, lessThan(1e-9), reason: '$l ${s.shapeGroup}');
            }
          }
        }
      }
    });

    test('following each stroke exactly finishes the trace for every letter', () {
      for (final l in az.split('')) {
        final t = TraceTracker(LetterStrokeLibrary.all[l]!.strokes);
        for (final s in t.strokes) {
          expect(t.begin(s.start), isTrue, reason: l);
          for (final p in s.points) {
            t.move(p);
          }
          t.end();
        }
        expect(t.finished, isTrue, reason: l);
      }
    });
  });

  group('sound order', () {
    test('default covers all 26 letters once', () {
      expect(LearningPreferences.defaultSoundSequence.toSet(), az.split('').toSet());
      expect(LearningPreferences.defaultSoundSequence, hasLength(26));
    });

    test('older saves (s a t p i n m, m first) keep their order and gain the rest', () {
      final old = LearningPreferences.fromJson({'soundSequence': ['s', 'a', 't', 'p', 'i', 'n', 'm']});
      expect(old.soundSequence, LearningPreferences.defaultSoundSequence);
      final mFirst = LearningPreferences.fromJson({'soundSequence': ['m', 's', 'a', 't', 'p', 'i', 'n']});
      expect(mFirst.soundSequence.take(7).join(), 'msatpin');
      expect(mFirst.soundSequence, hasLength(26));
      final junk = LearningPreferences.fromJson({'soundSequence': ['zz', 'b', 'b', '']});
      expect(junk.soundSequence.first, 'b');
      expect(junk.soundSequence, hasLength(26));
    });
  });

  group('planning', () {
    for (final l in az.split('')) {
      test('lesson for $l only uses games that can run, without look-alike distractors', () {
        const prefs = LearningPreferences(readiness: Readiness.growing, tracingEnabled: true);
        final seq = prefs.soundSequence;
        final introduced = seq.take(seq.indexOf(l) + 1).toSet()..addAll(['b', 'd', 'p', 'q']);
        for (final avail in [bundled(), bundled(wordAudio: false)]) {
          final plan = LessonPlanner(avail).plan(letterId: l, prefs: prefs, introduced: introduced, recentGames: const []);
          final games = plan.steps.where((s) => s.kind == LessonStepKind.activity).map((s) => s.gameType!).toList();
          expect(games.length, greaterThanOrEqualTo(2), reason: '$l $games');
          expect(games.every((g) => avail.forGame(g, l, introduced: introduced).available), isTrue, reason: '$l $games');
          expect(plan.steps.last.kind, LessonStepKind.completion);
          expect(plan.distractorLetterIds.any((d) => ContentCatalog.lookAlike(d, l)), isFalse, reason: '$l ${plan.distractorLetterIds}');
          if (l == 'x') expect(games, isNot(anyOf(contains(GameType.feedMonster), contains(GameType.safari))));
        }
      });
    }

    test('guided opens finished sounds and the next one; free play opens all', () {
      const guided = LearningPreferences();
      expect(LessonPlanner.isOpen(guided, {}, 's'), isTrue);
      expect(LessonPlanner.isOpen(guided, {}, 'a'), isFalse);
      expect(LessonPlanner.isOpen(guided, {'s'}, 'a'), isTrue);
      expect(LessonPlanner.isOpen(guided, {'s', 'z'}, 'z'), isTrue);
      expect(LessonPlanner.isOpen(const LearningPreferences(mode: PlayMode.freePlay), {}, 'q'), isTrue);
      expect(LessonPlanner.nextSound(guided, az.split('').toSet()), isNull);
      expect(LessonPlanner.isOpen(guided, az.split('').toSet(), 'q'), isTrue);
    });
  });

  group('beginning-sound games', () {
    for (final l in ['c', 'k', 'q']) {
      testWidgets('Feed the Monster for $l never offers another /k/ sound as a wrong answer', (tester) async {
        await setScreen(tester, const Size(390, 844));
        final app = await TestApp.create();
        await app.learners.updatePreferences((p) => p.copyWith(readiness: Readiness.growing));
        await tester.pumpWidget(app.wrap(buildGame(
          GameSpec(type: GameType.feedMonster, letters: [l], distractors: const ['c', 'k', 'q', 's', 'a'], showIntroDemo: false),
          (_) {},
        )));
        await tester.pump();
        final e = tester.state<GameState>(find.byWidgetPredicate((w) => w is GameWidget)).engine;
        for (final r in e.rounds) {
          for (final id in r.choices.where((id) => id != r.answer)) {
            expect(['c', 'k', 'q'], isNot(contains(ContentCatalog.wordsById[id]!.letterId)), reason: '$l round offers $id');
          }
        }
        e.exit();
        await settleFor(tester, const Duration(seconds: 1));
      });
    }
  });

  group('every letter’s lesson plays through to the sticker', () {
    for (final growing in [false, true]) {
      for (final l in az.split('')) {
        testWidgets('$l (${growing ? 'growing, tracing on' : 'starting'})', (tester) async {
          await setScreen(tester, const Size(390, 844));
          final app = await TestApp.create();
          if (growing) {
            await app.learners.updatePreferences((p) => p.copyWith(
                readiness: Readiness.growing, tracingEnabled: true, letterCase: LetterCaseMode.lowercaseThenUppercase));
          }
          late BuildContext ctx;
          await tester.pumpWidget(app.wrap(Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          })));
          final plan = planLesson(ctx, l);
          await tester.pumpWidget(app.wrap(LessonScreen(plan: plan)));
          await tester.pump();
          expect(find.text('Meet the sound'), findsOneWidget);
          await playLessonThrough(tester);
          await settleFor(tester, const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(app.progress.lessonCompleted(l), isTrue);
          expect(find.text('New sticker!'), findsOneWidget);
          final played = app.progress.data.attempts.where((a) => a.context == ActivityContext.guidedLesson).map((a) => a.gameType).toSet();
          expect(played.length, plan.steps.where((s) => s.kind == LessonStepKind.activity).length, reason: '$played');
          expect(app.progress.validCheckpoint(), isNull);
          await settleFor(tester, const Duration(seconds: 1));
        });
      }
    }
  });

  group('parent settings stay in sync', () {
    const feedPlan = LessonPlan(letterId: 's', distractorLetterIds: [], steps: [
      LessonStep(LessonStepKind.introduction),
      LessonStep(LessonStepKind.pictureDiscovery),
      LessonStep(LessonStepKind.activity, gameType: GameType.feedMonster),
      LessonStep(LessonStepKind.completion),
    ]);

    test('changing readiness, tracing or letter case drops the saved lesson; other changes keep it', () async {
      final app = await TestApp.create();
      await app.progress.saveCheckpoint(feedPlan, 1);
      await app.learners.updatePreferences((p) => p.copyWith(reminderMinutes: 10, mode: PlayMode.freePlay));
      expect(app.progress.validCheckpoint(), isNotNull);
      for (final change in <LearningPreferences Function(LearningPreferences)>[
        (p) => p.copyWith(readiness: Readiness.growing),
        (p) => p.copyWith(tracingEnabled: true),
        (p) => p.copyWith(letterCase: LetterCaseMode.lowercaseThenUppercase),
      ]) {
        await app.progress.saveCheckpoint(feedPlan, 1);
        await app.learners.updatePreferences(change);
        expect(app.progress.validCheckpoint(), isNull);
      }
      await app.progress.flush();
    });

    testWidgets('Keep going starts a fresh lesson when a saved game can no longer run', (tester) async {
      await setScreen(tester, const Size(390, 844));
      final app = await TestApp.create();
      await app.progress.saveCheckpoint(feedPlan, 2);
      await app.settings.update((s) => s.copyWith(deviceVoiceForWords: false));
      await tester.pumpWidget(app.wrap(const HomeTab()));
      await tester.pump();
      await tester.tap(find.text('Keep going'));
      await tester.pumpAndSettle();
      expect(find.text('Meet the sound'), findsOneWidget);
      final cp = app.progress.validCheckpoint()!;
      expect(cp.stepIndex, 0);
      expect(cp.plan.steps.any((s) => s.gameType == GameType.feedMonster || s.gameType == GameType.safari), isFalse);
    });

    testWidgets('Sound Path shows all 26 letters; guided keeps later ones waiting', (tester) async {
      await setScreen(tester, const Size(390, 844));
      final app = await TestApp.create();
      await tester.pumpWidget(app.wrap(const SoundPathScreen()));
      await tester.pump();
      for (final l in ['s', 'm', 'x', 'q']) {
        await tester.scrollUntilVisible(find.bySemanticsLabel(RegExp('^sound $l\\b')), 200, scrollable: find.byType(Scrollable).first);
      }
      expect(find.text('Continue with s'), findsOneWidget);
    });

    testWidgets('letter book offers Play only for open letters, and follows the mode setting', (tester) async {
      await setScreen(tester, const Size(390, 844));
      final app = await TestApp.create();
      await tester.pumpWidget(app.wrap(const LetterBookScreen(startIndex: 18))); // s
      await tester.pumpAndSettle();
      expect(find.text('Play with s'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next letter'));
      await tester.pumpAndSettle();
      expect(find.text('Play with t'), findsNothing);
      await app.learners.updatePreferences((p) => p.copyWith(mode: PlayMode.freePlay));
      await tester.pumpAndSettle();
      expect(find.text('Play with t'), findsOneWidget);
      await tester.tap(find.text('Play with t'));
      await tester.pumpAndSettle();
      expect(find.text('Meet the sound'), findsOneWidget);
      expect(app.progress.validCheckpoint()?.plan.letterId, 't');
    });

    for (final size in const [Size(360, 640), Size(411, 731), Size(390, 844)]) {
      testWidgets('letter book fits Play on screen without scrolling at $size', (tester) async {
        await setScreen(tester, size);
        final app = await TestApp.create();
        await tester.pumpWidget(app.wrap(const LetterBookScreen(startIndex: 18)));
        await tester.pumpAndSettle();
        final play = tester.getRect(find.text('Play with s'));
        final next = tester.getRect(find.bySemanticsLabel('Next letter'));
        expect(play.bottom, lessThan(next.top), reason: 'Play button is hidden behind the arrows');
      });

      testWidgets('all discovery pictures show above the button at $size', (tester) async {
        await setScreen(tester, size);
        final app = await TestApp.create();
        await tester.pumpWidget(app.wrap(const LessonScreen(
            startStep: 1,
            plan: LessonPlan(letterId: 's', distractorLetterIds: [], steps: [
              LessonStep(LessonStepKind.introduction),
              LessonStep(LessonStepKind.pictureDiscovery),
              LessonStep(LessonStepKind.completion),
            ]))));
        await tester.pumpAndSettle();
        final button = tester.getRect(find.text('Play with s'));
        for (final w in ['sun', 'sock', 'snake']) {
          expect(tester.getRect(find.text(w)).bottom, lessThan(button.top), reason: '$w is hidden');
        }
      });
    }

    testWidgets('Games tab shows word games once the device voice finishes starting', (tester) async {
      await setScreen(tester, const Size(390, 844));
      final app = await TestApp.create(deviceVoice: false);
      await tester.pumpWidget(app.wrap(const GamesCatalogue()));
      await tester.pump();
      expect(find.bySemanticsLabel('Feed the Monster'), findsNothing);
      app.driver.voiceAvailable = true;
      await app.audio.refreshDeviceVoice();
      await tester.pump();
      expect(find.bySemanticsLabel('Feed the Monster'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Sound Safari')), findsOneWidget);
    });

    testWidgets('progress is recorded against the active learner after switching', (tester) async {
      final app = await TestApp.create();
      final first = app.learners.active.id;
      await app.progress.recordExposure(Targets.letter('b'), 'test');
      final other = await app.learners.addLearner('Sam', 'owl');
      await app.learners.switchTo(other.id);
      expect(app.progress.learnerId, other.id);
      expect(app.progress.pathStatus('b'), PathStatus.newSound);
      await app.learners.switchTo(first);
      expect(app.progress.pathStatus('b'), PathStatus.explored);
      await app.progress.flush();
      await app.learners.flush();
    });
  });
}
