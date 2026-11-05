import 'dart:math';

import 'package:abc_kids_learning/data/content/audio_manifest.dart';
import 'package:abc_kids_learning/data/content/content_catalog.dart';
import 'package:abc_kids_learning/data/content/letter_strokes.dart';
import 'package:abc_kids_learning/data/models/content.dart';
import 'package:abc_kids_learning/data/models/learner.dart';
import 'package:abc_kids_learning/data/models/progress.dart';
import 'package:abc_kids_learning/domain/active_time.dart';
import 'package:abc_kids_learning/domain/availability.dart';
import 'package:abc_kids_learning/domain/lesson_planner.dart';
import 'package:abc_kids_learning/features/games/magic_trail_game.dart';
import 'package:abc_kids_learning/features/parent/parent_gate.dart';
import 'package:flutter_test/flutter_test.dart';

ContentAvailability bundled({bool wordAudio = true}) =>
    ContentAvailability(assetPlayable: (a) => a != null && a.hasFile, wordAudio: wordAudio);

void main() {
  group('content honesty', () {
    test('no phoneme recording is marked reviewed or usable for phonics', () {
      for (final a in AudioManifest.all.values.where((a) => a.kind == AudioKind.phoneme)) {
        expect(a.usableForPhonics, isFalse, reason: a.id);
        expect(a.status, ReviewStatus.missing);
      }
    });

    test('bundled letter recordings are unverified letter names, never phonemes', () {
      final letters = AudioManifest.all.values.where((a) => a.path?.contains('abc_letter_sound') ?? false).toList();
      expect(letters, hasLength(26));
      for (final a in letters) {
        expect(a.kind, AudioKind.letterName);
        expect(a.status, ReviewStatus.unverified);
      }
    });

    test('sound, letter-name and word audio ids are distinct for each letter', () {
      for (final l in ContentCatalog.letters) {
        expect(l.phonemeAudioId, isNot(l.letterNameAudioId));
      }
    });

    test('guided sequence letters have lesson content and stroke data', () {
      for (final l in LearningPreferences.defaultSoundSequence) {
        expect(ContentCatalog.hasLessonContent(l), isTrue, reason: l);
        expect(LetterStrokeLibrary.all[l], isNotNull, reason: l);
        for (final w in ContentCatalog.wordsFor(l)) {
          expect(w.beginningSound, ContentCatalog.letter(l)!.soundPolicy.taughtSound);
        }
      }
    });

    test('stroke points stay inside the unit box', () {
      for (final e in LetterStrokeLibrary.all.entries) {
        for (final s in e.value.strokes) {
          for (final p in s.points) {
            expect(p.dx, inInclusiveRange(0, 1), reason: e.key);
            expect(p.dy, inInclusiveRange(0, 1), reason: e.key);
          }
        }
      }
    });
  });

  group('availability', () {
    test('Pop runs as visual "Pop the Letter" without reviewed phonemes', () {
      final a = bundled().forGame(GameType.pop, 'm', introduced: {'s', 'a'});
      expect(a.available, isTrue);
      expect(a.popMode, PopMode.visual);
    });

    test('word games are unavailable without word audio, with a reason', () {
      final a = bundled(wordAudio: false).forGame(GameType.safari, 'm', introduced: {});
      expect(a.available, isFalse);
      expect(a.note, isNotEmpty);
    });

    test('build/trace need stroke data', () {
      expect(bundled().forGame(GameType.buildLetter, 'm', introduced: {}).available, isTrue);
      expect(bundled().forGame(GameType.buildLetter, 'q', introduced: {}).available, isTrue);
      // Unknown letters (no shape data) are never offered.
      expect(bundled().forGame(GameType.buildLetter, '?', introduced: {}).available, isFalse);
    });
  });

  group('lesson planner', () {
    LessonPlan plan({
      String letter = 'm',
      LearningPreferences prefs = const LearningPreferences(),
      Set<String> introduced = const {},
      List<GameType> recent = const [],
      bool wordAudio = true,
      int seed = 1,
    }) =>
        LessonPlanner(bundled(wordAudio: wordAudio), random: Random(seed))
            .plan(letterId: letter, prefs: prefs, introduced: introduced, recentGames: recent);

    test('intro → discovery → 2–3 games → completion', () {
      final p = plan();
      expect(p.steps.first.kind, LessonStepKind.introduction);
      expect(p.steps[1].kind, LessonStepKind.pictureDiscovery);
      expect(p.steps.last.kind, LessonStepKind.completion);
      expect(p.activitySteps.length, inInclusiveRange(2, 3));
    });

    test('readiness changes the number of core games', () {
      final starting = plan(prefs: const LearningPreferences(tracingEnabled: false));
      final growing = plan(prefs: const LearningPreferences(readiness: Readiness.growing, tracingEnabled: false));
      expect(starting.activitySteps, hasLength(2));
      expect(growing.activitySteps, hasLength(3));
    });

    test('tracing is excluded when disabled and never replaces a phonics game', () {
      final off = plan(prefs: const LearningPreferences(tracingEnabled: false));
      expect(off.activitySteps.map((s) => s.gameType), isNot(contains(GameType.magicTrail)));
      final on = plan();
      final games = on.activitySteps.map((s) => s.gameType).toList();
      if (games.contains(GameType.magicTrail)) expect(games.last, GameType.magicTrail);
    });

    test('distractors come only from introduced sounds', () {
      expect(plan(introduced: {}).distractorLetterIds, isEmpty);
      final p = plan(introduced: {'s', 'a', 'z'});
      expect(p.distractorLetterIds, everyElement(isIn({'s', 'a'})));
    });

    test('without word audio, no word-dependent game is planned', () {
      final p = plan(wordAudio: false);
      final games = p.activitySteps.map((s) => s.gameType);
      expect(games, isNot(contains(GameType.safari)));
      expect(games, isNot(contains(GameType.feedMonster)));
      expect(p.activitySteps, isNotEmpty);
    });

    test('recently played games are de-prioritised for variety', () {
      final p = plan(recent: [GameType.feedMonster, GameType.safari], prefs: const LearningPreferences(tracingEnabled: false));
      expect(p.activitySteps.map((s) => s.gameType), isNot(containsAll([GameType.feedMonster, GameType.safari])));
    });

    test('nextSound follows the configured sequence', () {
      const prefs = LearningPreferences();
      expect(LessonPlanner.nextSound(prefs, {}), 's');
      expect(LessonPlanner.nextSound(prefs, {'s', 'a'}), 't');
      expect(LessonPlanner.nextSound(prefs, prefs.soundSequence.toSet()), isNull);
    });
  });

  group('progress labels', () {
    ActivityAttempt a(AttemptOutcome o, DateTime at) => ActivityAttempt(
          id: '$at$o',
          learnerId: 'l',
          activityId: 'pop',
          gameType: GameType.pop,
          contentVersion: 'v',
          domain: SkillDomain.soundLetter,
          targetId: 'letter:m',
          outcome: o,
          hintsUsed: 0,
          retries: 0,
          demonstrationShown: false,
          context: ActivityContext.freePlay,
          completedAt: at,
        );
    const c = ProgressCriteria();

    test('one correct answer is practising, never recognised', () {
      final s = SkillProgress(SkillDomain.soundLetter, 'letter:m')..apply(a(AttemptOutcome.correctFirstTry, DateTime(2026, 1, 1)));
      expect(s.label(c), ProgressLabel.practising);
    });

    test('demonstrations and assisted answers never count as independent', () {
      final s = SkillProgress(SkillDomain.soundLetter, 'letter:m');
      for (var d = 1; d <= 6; d++) {
        s.apply(a(AttemptOutcome.demonstrated, DateTime(2026, 1, d)));
        s.apply(a(AttemptOutcome.correctWithHint, DateTime(2026, 1, d)));
      }
      expect(s.independentCorrect, 0);
      expect(s.label(c), ProgressLabel.practising);
    });

    test('recognised needs enough first-try answers across days', () {
      final s = SkillProgress(SkillDomain.soundLetter, 'letter:m');
      for (var i = 0; i < 5; i++) {
        s.apply(a(AttemptOutcome.correctFirstTry, DateTime(2026, 1, 1, 10, i)));
      }
      expect(s.label(c), ProgressLabel.practising, reason: 'all on one day');
      s.apply(a(AttemptOutcome.correctFirstTry, DateTime(2026, 1, 2)));
      expect(s.label(c), ProgressLabel.recognisedIndependently);
    });

    test('exposure only is explored', () {
      final s = SkillProgress(SkillDomain.exposure, 'letter:m')..apply(a(AttemptOutcome.exposure, DateTime(2026)));
      expect(s.label(c), ProgressLabel.explored);
    });

    test('only sound-letter and beginning-sound are phonics domains', () {
      expect(SkillDomain.values.where((d) => d.isPhonics), [SkillDomain.soundLetter, SkillDomain.beginningSound]);
    });
  });

  group('tracing', () {
    final strokes = LetterStrokeLibrary.all['m']!.strokes;

    test('must start near the green dot', () {
      final t = TraceTracker(strokes);
      expect(t.begin(const Offset(0.9, 0.1)), isFalse);
      expect(t.begin(strokes.first.start), isTrue);
    });

    test('following each stroke in order completes the letter', () {
      final t = TraceTracker(strokes);
      for (final s in strokes) {
        expect(t.begin(s.start), isTrue);
        for (final p in s.points) {
          expect(t.move(p + const Offset(0.03, 0)), isTrue);
        }
        t.end();
      }
      expect(t.finished, isTrue);
      expect(t.done, hasLength(strokes.length));
    });

    test('wandering far away cancels the stroke gently', () {
      final t = TraceTracker(strokes);
      t.begin(strokes.first.start);
      t.move(strokes.first.points[2]);
      expect(t.move(const Offset(0.95, 0.05)), isFalse);
      expect(t.progress, 0);
      expect(t.strokeIndex, 0);
    });

    test('dot strokes complete with a tap', () {
      final i = LetterStrokeLibrary.all['i']!.strokes;
      final t = TraceTracker(i);
      t.begin(i[0].start);
      for (final p in i[0].points) {
        t.move(p);
      }
      expect(t.strokeIndex, 1);
      expect(t.begin(i[1].start), isTrue);
      expect(t.finished, isTrue);
    });
  });

  test('parent gate questions have one correct answer among four options', () {
    final r = Random(3);
    for (var i = 0; i < 200; i++) {
      final (prompt, answer, options) = ParentGate.question(r);
      expect(prompt, contains('times'));
      expect(options.toSet(), hasLength(4));
      expect(options.where((o) => o == answer), hasLength(1));
    }
  });

  test('active time counts only while running and reminds without a limit', () {
    var now = DateTime(2026, 1, 1, 9);
    final t = ActiveTimeTracker(now: () => now)..setMinutes(5);
    t.start();
    now = now.add(const Duration(minutes: 3));
    t.pause();
    now = now.add(const Duration(minutes: 30)); // backgrounded: not counted
    expect(t.reminderDue, isFalse);
    t.start();
    now = now.add(const Duration(minutes: 2));
    expect(t.reminderDue, isTrue);
    t.acknowledge();
    expect(t.reminderDue, isFalse);
    now = now.add(const Duration(minutes: 5));
    expect(t.reminderDue, isTrue);
    t.setMinutes(0);
    expect(t.reminderDue, isFalse);
  });
}
