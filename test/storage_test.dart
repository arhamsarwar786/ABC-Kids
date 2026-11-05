import 'dart:convert';

import 'package:abc_kids_learning/data/models/content.dart';
import 'package:abc_kids_learning/data/models/learner.dart';
import 'package:abc_kids_learning/data/models/progress.dart';
import 'package:abc_kids_learning/data/storage/app_storage.dart';
import 'package:abc_kids_learning/state/learner_store.dart';
import 'package:abc_kids_learning/state/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

Future<(AppStorage, SharedPreferences)> openWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final storage = await AppStorage.open(prefs);
  await storage.flushBackups();
  return (storage, prefs);
}

void main() {
  group('backup failure (review point 3)', backupFailureTests);

  group('migration from the original app', () {
    test('fresh install creates one guest learner and schema 1', () async {
      final (s, prefs) = await openWith({});
      expect(prefs.getInt(AppStorage.schemaKey), 1);
      final learners = s.loadLearners();
      expect(learners, hasLength(1));
      expect(learners.single.isGuest, isTrue);
      expect(s.loadDeviceSettings().firstRunComplete, isFalse);
    });

    test('legacy prefs are migrated and kept untouched', () async {
      final (s, prefs) = await openWith({
        'mute_sound': true,
        'onboarding_seen': true,
        'playback_speed': 1.5,
        'star_count': 3,
      });
      final d = s.loadDeviceSettings();
      expect(d.musicMuted, isTrue);
      expect(d.firstRunComplete, isTrue);
      final learner = s.loadLearners().single;
      expect(s.loadProgress(learner.id).legacyStars, 3);
      // Legacy keys are never removed or changed.
      expect(prefs.getInt('star_count'), 3);
      expect(prefs.getBool('mute_sound'), isTrue);
      expect(prefs.getDouble('playback_speed'), 1.5);
    });

    test('legacy star count is kept in full, not truncated', () async {
      final (s, _) = await openWith({'star_count': 1234});
      final learner = s.loadLearners().single;
      expect(s.loadProgress(learner.id).legacyStars, 1234);
    });

    test('re-opening is idempotent (no extra learners, stars not doubled)', () async {
      final (_, prefs) = await openWith({'star_count': 2});
      final again = await AppStorage.open(prefs);
      final learners = again.loadLearners();
      expect(learners, hasLength(1));
      expect(again.loadProgress(learners.single.id).legacyStars, 2);
    });
  });

  group('future schema (review point 1)', () {
    test('newer stored schema puts storage in read-only mode', () async {
      final original = {
        AppStorage.schemaKey: 99,
        AppStorage.deviceKey: '{"something":"new"}',
        AppStorage.learnersKey: '{"v2":true}',
      };
      final (s, prefs) = await openWith(original);
      expect(s.readOnly, isTrue);
      await s.saveDeviceSettings(s.loadDeviceSettings().copyWith(musicMuted: true));
      await s.saveLearner(s.newGuest());
      await s.saveLearnerIndex(const LearnerIndex(activeId: 'x', ids: ['x']));
      await s.flushBackups();
      for (final e in original.entries) {
        expect(prefs.get(e.key), e.value, reason: '${e.key} must not change');
      }
      expect(s.recoveredKeys, isEmpty);
    });

    test('learner store still provides a playable guest in read-only mode', () async {
      final (s, prefs) = await openWith({AppStorage.schemaKey: 99});
      final store = LearnerStore(s);
      expect(store.active.isGuest, isTrue);
      await store.updatePreferences((p) => p.copyWith(readiness: Readiness.growing));
      await store.flush();
      expect(prefs.getKeys().where((k) => k.startsWith('abc.learner.')), isEmpty);
    });
  });

  group('wrong types and malformed data (review points 2, 3, 5)', () {
    test('wrong-typed prefs values do not crash startup', () async {
      final (s, prefs) = await openWith({
        AppStorage.schemaKey: 'one', // wrong type
        AppStorage.deviceKey: 42, // wrong type
        AppStorage.learnersKey: '{"ids": 4, "activeId": 7}',
        'star_count': 'many',
      });
      expect(s.loadLearners(), hasLength(1));
      expect(prefs.getInt(AppStorage.schemaKey), 1);
      // Originals of malformed JSON keys are preserved.
      final recovered = s.recoveredKeys.map((k) => prefs.getString(k)).toList();
      expect(recovered, contains('42'));
      expect(recovered.any((r) => r!.contains('"ids":4')), isTrue);
    });

    test('profile with wrong-typed fields is recovered and preserved', () async {
      final raw = jsonEncode({
        'id': 'learner-a',
        'nickname': 'Mia',
        'preferences': {'soundSequence': {}, 'reminderMinutes': 'x', 'mode': 3},
      });
      final (s, _) = await openWith({
        AppStorage.schemaKey: 1,
        AppStorage.learnersKey: jsonEncode({'activeId': 'learner-a', 'ids': ['learner-a']}),
        AppStorage.learnerKey('learner-a'): raw,
      });
      final p = s.loadLearner('learner-a')!;
      expect(p.nickname, 'Mia');
      expect(p.preferences.soundSequence, LearningPreferences.defaultSoundSequence);
      expect(p.preferences.reminderMinutes, 5);
    });

    test('all profiles malformed: safe guest created, raw records retained', () async {
      const badA = '{"nickname": 5}';
      const badB = 'not json at all';
      final (s, prefs) = await openWith({
        AppStorage.schemaKey: 1,
        AppStorage.learnersKey: jsonEncode({'activeId': 'a', 'ids': ['a', 'b']}),
        AppStorage.learnerKey('a'): badA,
        AppStorage.learnerKey('b'): badB,
      });
      final learners = s.loadLearners();
      expect(learners, hasLength(1));
      expect(learners.single.isGuest, isTrue);
      // Original raw values remain in place and are also backed up.
      expect(prefs.getString(AppStorage.learnerKey('a')), badA);
      expect(prefs.getString(AppStorage.learnerKey('b')), badB);
      final backups = s.recoveredKeys.map(prefs.getString).toList();
      expect(backups, containsAll([badB]));
      expect(backups.any((b) => b!.contains('"nickname":5')), isTrue);
    });

    test('progress with wrong-typed collections keeps valid parts and a backup', () async {
      final (s0, _) = await openWith({});
      final id = s0.loadLearners().single.id;
      final prefs = s0.prefs;
      final raw = jsonEncode({
        'schema': 1,
        'attempts': {'not': 'a list'},
        'stickers': [
          {'id': 'lesson:m', 'stickerId': 'lesson-m', 'reason': 'r', 'awardedAt': '2026-01-01T00:00:00.000'},
          {'broken': true},
        ],
        'completedLessons': 'm',
        'legacyStars': 'x',
      });
      await prefs.setString(AppStorage.progressKey(id), raw);
      final s = await AppStorage.open(prefs);
      final data = s.loadProgress(id);
      expect(data.stickers.keys, ['lesson:m']);
      expect(data.attempts, isEmpty);
      expect(data.legacyStars, 0);
      expect(await s.flushBackups(), isTrue);
      expect(s.recoveredKeys.map(prefs.getString), contains(raw));
    });

    test('backup must be durable before the corrupt key is overwritten', () async {
      final (s0, _) = await openWith({});
      final prefs = s0.prefs;
      await prefs.setString(AppStorage.deviceKey, '{broken');
      final s = await AppStorage.open(prefs);
      s.loadDeviceSettings(); // triggers preservation
      await s.saveDeviceSettings(s.loadDeviceSettings());
      final backups = s.recoveredKeys.map(prefs.getString).toList();
      expect(backups, contains('{broken'));
      expect(jsonDecode(prefs.getString(AppStorage.deviceKey)!), isA<Map>());
    });
  });

  group('learner isolation, idempotency and checkpoints', () {
    test('deleting one learner removes only their data', () async {
      final (s, prefs) = await openWith({'mute_sound': true});
      final learners = LearnerStore(s);
      final progress = ProgressStore(s, learners);
      final first = learners.active;
      final second = await learners.addLearner('  Sam   Lee  ', 'owl');
      expect(second.nickname, 'Sam Lee');

      await progress.award('lesson:m', 'lesson-m', 'test');
      await learners.switchTo(second.id);
      await progress.award('lesson:s', 'lesson-s', 'test');
      expect(progress.stickers.map((x) => x.id), ['lesson:s']);
      await progress.flush();

      await learners.deleteLearner(second.id);
      await learners.flush();
      expect(prefs.containsKey(AppStorage.progressKey(second.id)), isFalse);
      expect(prefs.containsKey(AppStorage.learnerKey(second.id)), isFalse);
      expect(learners.active.id, first.id);
      expect(s.loadProgress(first.id).stickers.keys, ['lesson:m']);
      expect(s.loadDeviceSettings().musicMuted, isTrue);
    });

    test('late progress write cannot resurrect a deleted learner', () async {
      final (s, prefs) = await openWith({});
      final learners = LearnerStore(s);
      final other = await learners.addLearner('Ana', 'cat');
      await learners.flush();
      await s.deleteLearner(other.id);
      await s.saveProgress(s.loadProgress(other.id)..legacyStars = 9);
      expect(prefs.containsKey(AppStorage.progressKey(other.id)), isFalse);
    });

    test('sticker awards are idempotent', () async {
      final (s, _) = await openWith({});
      final learners = LearnerStore(s);
      final progress = ProgressStore(s, learners);
      expect(await progress.award('lesson:m', 'lesson-m', 'r'), isTrue);
      expect(await progress.award('lesson:m', 'lesson-m', 'r'), isFalse);
      await progress.flush();
      expect(s.loadProgress(learners.active.id).stickers, hasLength(1));
    });

    test('invalid checkpoint is cleared without touching progress', () async {
      final (s, _) = await openWith({});
      final learners = LearnerStore(s);
      final progress = ProgressStore(s, learners);
      await progress.award('lesson:s', 'lesson-s', 'r');
      const plan = LessonPlan(letterId: 'm', distractorLetterIds: [], steps: [
        LessonStep(LessonStepKind.introduction),
        LessonStep(LessonStepKind.activity, gameType: GameType.parking),
        LessonStep(LessonStepKind.completion),
      ]);
      await progress.saveCheckpoint(plan, 1);
      expect(progress.validCheckpoint(), isNotNull);
      await progress.saveCheckpoint(plan, 7); // out of range
      expect(progress.validCheckpoint(), isNull);
      expect(progress.checkpointRecoveries, isNotEmpty);
      expect(progress.stickers, hasLength(1));
      await progress.flush();
      expect(s.loadProgress(learners.active.id).checkpoint, isNull);
    });

    test('checkpoint round-trips through storage', () async {
      final (s, _) = await openWith({});
      final learners = LearnerStore(s);
      final progress = ProgressStore(s, learners);
      const plan = LessonPlan(letterId: 'm', distractorLetterIds: ['s'], steps: [
        LessonStep(LessonStepKind.introduction),
        LessonStep(LessonStepKind.activity, gameType: GameType.safari, level: 1),
        LessonStep(LessonStepKind.completion),
      ]);
      await progress.saveCheckpoint(plan, 1);
      await progress.flush();
      final cp = s.loadProgress(learners.active.id).checkpoint!;
      expect(cp.stepIndex, 1);
      expect(cp.plan.steps[1].gameType, GameType.safari);
      expect(cp.plan.steps[1].level, 1);
      expect(cp.plan.distractorLetterIds, ['s']);
    });
  });
}

/// Platform store whose writes to recovery keys fail.
class _FailingBackupStore extends InMemorySharedPreferencesStore {
  _FailingBackupStore(super.data) : super.withData();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key.contains('abc.recovered.')) return false;
    return super.setValue(valueType, key, value);
  }
}

void backupFailureTests() {
  test('failed backup blocks overwriting the corrupt key', () async {
    SharedPreferencesStorePlatform.instance = _FailingBackupStore({
      'flutter.${AppStorage.schemaKey}': 1,
      'flutter.${AppStorage.deviceKey}': '{broken',
    });
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.resetStatic();
    final prefs = await SharedPreferences.getInstance();
    final s = await AppStorage.open(prefs);
    s.loadDeviceSettings();
    expect(await s.flushBackups(), isFalse);
    await expectLater(s.saveDeviceSettings(s.loadDeviceSettings()), throwsStateError);
    expect(prefs.getString(AppStorage.deviceKey), '{broken');
  });
}
