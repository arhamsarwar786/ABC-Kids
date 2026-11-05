/// Evidence, progress labels, stickers, checkpoints and lesson plans.
library;

import 'content.dart';

enum AttemptOutcome {
  /// Correct with no wrong answer in the round.
  correctFirstTry,

  /// Correct after the prompt was replayed.
  correctAfterRetry,

  /// Correct after choices were reduced or a hint was shown.
  correctWithHint,

  /// The answer was shown to the learner. Never independent credit.
  demonstrated,

  /// A construction/tracing task finished without help.
  completed,

  /// A construction/tracing task finished with help.
  completedWithHelp,
  skipped,

  /// Saw or heard content (explorers, introductions).
  exposure,
}

extension AttemptOutcomeX on AttemptOutcome {
  bool get isIndependent =>
      this == AttemptOutcome.correctFirstTry || this == AttemptOutcome.completed;
  bool get isAssisted =>
      this == AttemptOutcome.correctAfterRetry ||
      this == AttemptOutcome.correctWithHint ||
      this == AttemptOutcome.completedWithHelp;
  bool get isPractice => this != AttemptOutcome.exposure && this != AttemptOutcome.skipped;
}

/// Guided lesson evidence is kept apart from free-play practice evidence.
enum ActivityContext { guidedLesson, freePlay, explorer }

class ActivityAttempt {
  final String id;
  final String learnerId;
  final String activityId;
  final GameType? gameType;
  final String contentVersion;
  final SkillDomain domain;
  final String targetId;
  final AttemptOutcome outcome;
  final int hintsUsed;
  final int retries;
  final bool demonstrationShown;
  final ActivityContext context;
  final DateTime completedAt;

  const ActivityAttempt({
    required this.id,
    required this.learnerId,
    required this.activityId,
    required this.gameType,
    required this.contentVersion,
    required this.domain,
    required this.targetId,
    required this.outcome,
    required this.hintsUsed,
    required this.retries,
    required this.demonstrationShown,
    required this.context,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'learnerId': learnerId,
        'activityId': activityId,
        'gameType': gameType?.name,
        'contentVersion': contentVersion,
        'domain': domain.name,
        'targetId': targetId,
        'outcome': outcome.name,
        'hintsUsed': hintsUsed,
        'retries': retries,
        'demo': demonstrationShown,
        'context': context.name,
        'completedAt': completedAt.toIso8601String(),
      };

  static ActivityAttempt? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = raw.cast<String, dynamic>();
    final domain = _byName(SkillDomain.values, j['domain']);
    final outcome = _byName(AttemptOutcome.values, j['outcome']);
    final at = DateTime.tryParse('${j['completedAt']}');
    if (j['id'] is! String || j['learnerId'] is! String || domain == null || outcome == null || at == null) {
      return null;
    }
    return ActivityAttempt(
      id: j['id'] as String,
      learnerId: j['learnerId'] as String,
      activityId: '${j['activityId'] ?? ''}',
      gameType: _byName(GameType.values, j['gameType']),
      contentVersion: '${j['contentVersion'] ?? ''}',
      domain: domain,
      targetId: '${j['targetId'] ?? ''}',
      outcome: outcome,
      hintsUsed: j['hintsUsed'] is int ? j['hintsUsed'] as int : 0,
      retries: j['retries'] is int ? j['retries'] as int : 0,
      demonstrationShown: j['demo'] == true,
      context: _byName(ActivityContext.values, j['context']) ?? ActivityContext.freePlay,
      completedAt: at,
    );
  }
}

/// Criteria for "recognised independently". Documented in
/// docs/redesign/ARCHITECTURE.md. A single answer can never satisfy them.
class ProgressCriteria {
  final int minIndependentCorrect;
  final int minDistinctDays;
  final int recentWindow;
  final double minRecentFirstTryRate;

  const ProgressCriteria({
    this.minIndependentCorrect = 4,
    this.minDistinctDays = 2,
    this.recentWindow = 5,
    this.minRecentFirstTryRate = 0.8,
  }) : assert(minIndependentCorrect >= 2);
}

enum ProgressLabel { notStarted, explored, practising, recognisedIndependently }

extension ProgressLabelText on ProgressLabel {
  String get text => switch (this) {
        ProgressLabel.notStarted => 'New',
        ProgressLabel.explored => 'Explored',
        ProgressLabel.practising => 'Practising',
        ProgressLabel.recognisedIndependently => 'Recognised independently',
      };
}

/// Aggregated evidence for one (domain, target) pair.
class SkillProgress {
  final SkillDomain domain;
  final String targetId;
  int exposures;
  int practiceAttempts;
  int independentCorrect;
  int assistedCorrect;
  int demonstrated;
  int guidedAttempts;
  int freePlayAttempts;

  /// First-try results of recent practice rounds, newest last.
  final List<bool> recentFirstTry;
  final Set<String> independentDays;
  DateTime? lastAt;

  SkillProgress(this.domain, this.targetId,
      {this.exposures = 0,
      this.practiceAttempts = 0,
      this.independentCorrect = 0,
      this.assistedCorrect = 0,
      this.demonstrated = 0,
      this.guidedAttempts = 0,
      this.freePlayAttempts = 0,
      List<bool>? recentFirstTry,
      Set<String>? independentDays,
      this.lastAt})
      : recentFirstTry = recentFirstTry ?? [],
        independentDays = independentDays ?? {};

  String get key => keyFor(domain, targetId);
  static String keyFor(SkillDomain d, String target) => '${d.name}|$target';

  void apply(ActivityAttempt a) {
    lastAt = a.completedAt;
    if (a.outcome == AttemptOutcome.exposure) {
      exposures++;
      return;
    }
    if (a.outcome == AttemptOutcome.skipped) return;
    practiceAttempts++;
    if (a.context == ActivityContext.guidedLesson) {
      guidedAttempts++;
    } else {
      freePlayAttempts++;
    }
    if (a.outcome.isIndependent) {
      independentCorrect++;
      final d = a.completedAt.toLocal();
      independentDays.add('${d.year}-${d.month}-${d.day}');
      if (independentDays.length > 60) independentDays.remove(independentDays.first);
    } else if (a.outcome.isAssisted) {
      assistedCorrect++;
    } else if (a.outcome == AttemptOutcome.demonstrated) {
      demonstrated++;
    }
    recentFirstTry.add(a.outcome.isIndependent);
    if (recentFirstTry.length > 20) recentFirstTry.removeAt(0);
  }

  ProgressLabel label(ProgressCriteria c) {
    if (practiceAttempts == 0) {
      return exposures > 0 ? ProgressLabel.explored : ProgressLabel.notStarted;
    }
    final recent = recentFirstTry.length > c.recentWindow
        ? recentFirstTry.sublist(recentFirstTry.length - c.recentWindow)
        : recentFirstTry;
    final rate = recent.isEmpty ? 0.0 : recent.where((b) => b).length / recent.length;
    final ok = independentCorrect >= c.minIndependentCorrect &&
        independentDays.length >= c.minDistinctDays &&
        recent.length >= c.recentWindow &&
        rate >= c.minRecentFirstTryRate;
    return ok ? ProgressLabel.recognisedIndependently : ProgressLabel.practising;
  }

  Map<String, dynamic> toJson() => {
        'domain': domain.name,
        'targetId': targetId,
        'exposures': exposures,
        'practice': practiceAttempts,
        'independent': independentCorrect,
        'assisted': assistedCorrect,
        'demonstrated': demonstrated,
        'guided': guidedAttempts,
        'free': freePlayAttempts,
        'recent': recentFirstTry,
        'days': independentDays.toList(),
        'lastAt': lastAt?.toIso8601String(),
      };

  static SkillProgress? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = raw.cast<String, dynamic>();
    final d = _byName(SkillDomain.values, j['domain']);
    if (d == null || j['targetId'] is! String) return null;
    int n(String k) => j[k] is int ? j[k] as int : 0;
    return SkillProgress(d, j['targetId'] as String,
        exposures: n('exposures'),
        practiceAttempts: n('practice'),
        independentCorrect: n('independent'),
        assistedCorrect: n('assisted'),
        demonstrated: n('demonstrated'),
        guidedAttempts: n('guided'),
        freePlayAttempts: n('free'),
        recentFirstTry: j['recent'] is List ? (j['recent'] as List).whereType<bool>().toList() : null,
        independentDays: j['days'] is List ? (j['days'] as List).whereType<String>().toSet() : null,
        lastAt: DateTime.tryParse('${j['lastAt']}'));
  }
}

class StickerAward {
  /// Deterministic id (e.g. `lesson:m`) so awarding twice is a no-op.
  final String id;
  final String stickerId;
  final String reason;
  final DateTime awardedAt;

  const StickerAward({required this.id, required this.stickerId, required this.reason, required this.awardedAt});

  Map<String, dynamic> toJson() =>
      {'id': id, 'stickerId': stickerId, 'reason': reason, 'awardedAt': awardedAt.toIso8601String()};

  static StickerAward? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = raw.cast<String, dynamic>();
    final at = DateTime.tryParse('${j['awardedAt']}');
    if (j['id'] is! String || j['stickerId'] is! String || at == null) return null;
    return StickerAward(id: j['id'] as String, stickerId: j['stickerId'] as String, reason: '${j['reason'] ?? ''}', awardedAt: at);
  }
}

enum LessonStepKind { introduction, pictureDiscovery, activity, completion }

class LessonStep {
  final LessonStepKind kind;
  final GameType? gameType;

  /// Game level, e.g. Safari 0 = word-picture, 1 = beginning sound.
  final int level;
  const LessonStep(this.kind, {this.gameType, this.level = 0});

  Map<String, dynamic> toJson() => {'kind': kind.name, 'game': gameType?.name, 'level': level};

  static LessonStep? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = _byName(LessonStepKind.values, raw['kind']);
    if (kind == null) return null;
    final game = _byName(GameType.values, raw['game']);
    if (kind == LessonStepKind.activity && game == null) return null;
    return LessonStep(kind, gameType: game, level: raw['level'] is int ? raw['level'] as int : 0);
  }
}

class LessonPlan {
  final String letterId;
  final List<String> distractorLetterIds;
  final List<LessonStep> steps;
  const LessonPlan({required this.letterId, required this.distractorLetterIds, required this.steps});

  List<LessonStep> get activitySteps => steps.where((s) => s.kind == LessonStepKind.activity).toList();

  Map<String, dynamic> toJson() => {
        'letterId': letterId,
        'distractors': distractorLetterIds,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  static LessonPlan? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final letter = raw['letterId'];
    final stepsRaw = raw['steps'];
    if (letter is! String || stepsRaw is! List) return null;
    final steps = <LessonStep>[];
    for (final s in stepsRaw) {
      final step = LessonStep.tryFromJson(s);
      if (step == null) return null;
      steps.add(step);
    }
    if (steps.isEmpty) return null;
    return LessonPlan(
      letterId: letter,
      distractorLetterIds: raw['distractors'] is List ? (raw['distractors'] as List).whereType<String>().toList() : const [],
      steps: steps,
    );
  }
}

/// A resumable point inside a guided lesson.
class SessionCheckpoint {
  static const int schemaVersion = 1;

  final String learnerId;
  final LessonPlan plan;
  final int stepIndex;
  final String contentVersion;
  final DateTime savedAt;

  const SessionCheckpoint({
    required this.learnerId,
    required this.plan,
    required this.stepIndex,
    required this.contentVersion,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'schema': schemaVersion,
        'learnerId': learnerId,
        'plan': plan.toJson(),
        'stepIndex': stepIndex,
        'contentVersion': contentVersion,
        'savedAt': savedAt.toIso8601String(),
      };

  static SessionCheckpoint? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    if (raw['schema'] != schemaVersion) return null;
    final plan = LessonPlan.tryFromJson(raw['plan']);
    final idx = raw['stepIndex'];
    final at = DateTime.tryParse('${raw['savedAt']}');
    if (plan == null || idx is! int || raw['learnerId'] is! String || at == null) return null;
    return SessionCheckpoint(
      learnerId: raw['learnerId'] as String,
      plan: plan,
      stepIndex: idx,
      contentVersion: '${raw['contentVersion'] ?? ''}',
      savedAt: at,
    );
  }
}

T? _byName<T extends Enum>(List<T> values, Object? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
