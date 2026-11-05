import 'package:flutter/foundation.dart';

import '../data/content/content_catalog.dart';
import '../data/models/content.dart';
import '../data/models/learner.dart';
import '../data/models/learner_progress.dart';
import '../data/models/progress.dart';
import '../data/storage/app_storage.dart';
import 'learner_store.dart';

/// Target id helpers so domains share a consistent namespace.
class Targets {
  static String letter(String id) => 'letter:$id';
  static String word(String id) => 'word:$id';
  static String number(int n) => 'number:$n';
  static String shape(String id) => 'shape:$id';
}

enum PathStatus { newSound, explored, practising }

/// Evidence, stickers and checkpoints for the active learner.
class ProgressStore extends ChangeNotifier {
  final AppStorage _storage;
  final LearnerStore _learners;
  final ProgressCriteria criteria;
  late LearnerProgressData _data;
  late LearningPreferences _prefs;
  Future<void> _writes = Future.value();
  final List<String> checkpointRecoveries = [];

  ProgressStore(this._storage, this._learners, {this.criteria = const ProgressCriteria()}) {
    _data = _storage.loadProgress(_learners.active.id);
    _prefs = _learners.preferences;
    _learners.addListener(_onLearnerChanged);
  }

  void _onLearnerChanged() {
    final id = _learners.active.id;
    final before = _prefs;
    _prefs = _learners.preferences;
    if (id != _data.learnerId) {
      _data = _storage.loadProgress(id);
      notifyListeners();
    } else if (_reshapesLessons(before, _prefs) && _data.checkpoint != null) {
      // A grown-up changed how lessons are built: the saved lesson was
      // planned with the old settings, so the next lesson starts fresh.
      checkpointRecoveries.add('learning preferences changed');
      clearCheckpoint();
    }
  }

  static bool _reshapesLessons(LearningPreferences a, LearningPreferences b) =>
      a.readiness != b.readiness || a.tracingEnabled != b.tracingEnabled || a.letterCase != b.letterCase;

  @override
  void dispose() {
    _learners.removeListener(_onLearnerChanged);
    super.dispose();
  }

  String get learnerId => _data.learnerId;
  LearnerProgressData get data => _data;

  Future<void> _persist() {
    final snapshot = _data;
    return _writes = _writes.then((_) => _storage.saveProgress(snapshot)).catchError((Object e) {
      debugPrint('ProgressStore write failed: $e');
    });
  }

  Future<void> flush() => _writes;

  // ---------------------------------------------------------------- attempts

  Future<ActivityAttempt> record({
    required String activityId,
    required GameType? gameType,
    required SkillDomain domain,
    required String targetId,
    required AttemptOutcome outcome,
    required ActivityContext context,
    int hintsUsed = 0,
    int retries = 0,
    bool demonstrationShown = false,
  }) async {
    final a = ActivityAttempt(
      id: _storage.newId('att'),
      learnerId: _data.learnerId,
      activityId: activityId,
      gameType: gameType,
      contentVersion: ContentCatalog.version,
      domain: domain,
      targetId: targetId,
      outcome: outcome,
      hintsUsed: hintsUsed,
      retries: retries,
      demonstrationShown: demonstrationShown,
      context: context,
      completedAt: DateTime.now(),
    );
    _data.addAttempt(a);
    notifyListeners();
    await _persist();
    return a;
  }

  Future<void> recordExposure(String targetId, String activityId) => record(
        activityId: activityId,
        gameType: null,
        domain: SkillDomain.exposure,
        targetId: targetId,
        outcome: AttemptOutcome.exposure,
        context: ActivityContext.explorer,
      );

  SkillProgress? skill(SkillDomain d, String targetId) => _data.skills[SkillProgress.keyFor(d, targetId)];

  ProgressLabel label(SkillDomain d, String targetId) =>
      skill(d, targetId)?.label(criteria) ?? ProgressLabel.notStarted;

  List<SkillProgress> skillsForTarget(String targetId) =>
      _data.skills.values.where((s) => s.targetId == targetId).toList();

  PathStatus pathStatus(String letterId) {
    final skills = skillsForTarget(Targets.letter(letterId));
    if (skills.any((s) => s.practiceAttempts > 0)) return PathStatus.practising;
    if (skills.any((s) => s.exposures > 0) || _data.completedLessons.contains(letterId)) {
      return PathStatus.explored;
    }
    return PathStatus.newSound;
  }

  bool lessonCompleted(String letterId) => _data.completedLessons.contains(letterId);

  /// Letters introduced to this learner (explored or practised).
  Set<String> introducedLetters() => {
        for (final l in ContentCatalog.letters)
          if (pathStatus(l.id) != PathStatus.newSound) l.id,
      };

  List<ActivityAttempt> recentAttempts([int n = 20]) {
    final list = _data.attempts.where((a) => a.outcome != AttemptOutcome.exposure).toList();
    return list.reversed.take(n).toList();
  }

  // --------------------------------------------------------------- lessons

  Future<void> completeLesson(String letterId) async {
    _data.completedLessons.add(letterId);
    _data.checkpoint = null;
    notifyListeners();
    await _persist();
  }

  Future<void> notePlayed(GameType t) async {
    _data.notePlayed(t);
    await _persist();
  }

  List<GameType> get recentGames => List.unmodifiable(_data.recentGames);

  // ------------------------------------------------------------- stickers

  List<StickerAward> get stickers =>
      _data.stickers.values.toList()..sort((a, b) => a.awardedAt.compareTo(b.awardedAt));

  /// Idempotent: returns false when this award id already exists.
  Future<bool> award(String awardId, String stickerId, String reason) async {
    final isNew = _data.award(StickerAward(id: awardId, stickerId: stickerId, reason: reason, awardedAt: DateTime.now()));
    if (isNew) {
      notifyListeners();
      await _persist();
    }
    return isNew;
  }

  // ----------------------------------------------------------- checkpoints

  Future<void> saveCheckpoint(LessonPlan plan, int stepIndex) async {
    _data.checkpoint = SessionCheckpoint(
      learnerId: _data.learnerId,
      plan: plan,
      stepIndex: stepIndex,
      contentVersion: ContentCatalog.version,
      savedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> clearCheckpoint() async {
    if (_data.checkpoint == null) return;
    _data.checkpoint = null;
    notifyListeners();
    await _persist();
  }

  /// Returns a usable checkpoint or null. Invalid checkpoints are cleared
  /// (progress is untouched) and the reason is kept in [checkpointRecoveries].
  SessionCheckpoint? validCheckpoint() {
    final cp = _data.checkpoint;
    if (cp == null) return null;
    final reason = checkpointProblem(cp, _data.learnerId);
    if (reason == null) return cp;
    checkpointRecoveries.add(reason);
    _data.checkpoint = null;
    _persist();
    return null;
  }

  static String? checkpointProblem(SessionCheckpoint cp, String learnerId) {
    if (cp.learnerId != learnerId) return 'checkpoint belongs to another learner';
    if (!ContentCatalog.hasLessonContent(cp.plan.letterId)) return 'lesson content ${cp.plan.letterId} unavailable';
    if (cp.stepIndex < 0 || cp.stepIndex >= cp.plan.steps.length) return 'step ${cp.stepIndex} out of range';
    if (cp.plan.steps.last.kind != LessonStepKind.completion) return 'plan has no completion step';
    return null;
  }

  // --------------------------------------------------------------- resets

  /// Removes one learner's progress, stickers (including stars from before)
  /// and checkpoint. Their profile, preferences, other learners and device
  /// settings are kept.
  Future<void> resetLearner(String learnerId) async {
    await flush();
    if (learnerId == _data.learnerId) {
      _data = LearnerProgressData(learnerId: learnerId);
      notifyListeners();
      await _persist();
    } else {
      await _storage.saveProgress(LearnerProgressData(learnerId: learnerId));
    }
  }

  /// Summary of another learner's stored progress (for confirmations).
  LearnerProgressData peek(String learnerId) =>
      learnerId == _data.learnerId ? _data : _storage.loadProgress(learnerId);
}
