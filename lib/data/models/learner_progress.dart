import 'content.dart';
import 'progress.dart';

/// Everything stored for one learner. Persisted as a single key so a write is
/// all-or-nothing for that learner.
class LearnerProgressData {
  static const int schemaVersion = 1;
  static const int maxStoredAttempts = 400;

  final String learnerId;
  final List<ActivityAttempt> attempts;
  final Map<String, SkillProgress> skills;
  final Map<String, StickerAward> stickers;
  final Set<String> completedLessons;

  /// Recently played game types, newest last, used for variety.
  final List<GameType> recentGames;
  SessionCheckpoint? checkpoint;

  /// Stars earned in the original app (full count, never truncated).
  int legacyStars;

  LearnerProgressData({
    required this.learnerId,
    List<ActivityAttempt>? attempts,
    Map<String, SkillProgress>? skills,
    Map<String, StickerAward>? stickers,
    Set<String>? completedLessons,
    List<GameType>? recentGames,
    this.checkpoint,
    this.legacyStars = 0,
  })  : attempts = attempts ?? [],
        skills = skills ?? {},
        stickers = stickers ?? {},
        completedLessons = completedLessons ?? {},
        recentGames = recentGames ?? [];

  void addAttempt(ActivityAttempt a) {
    attempts.add(a);
    if (attempts.length > maxStoredAttempts) {
      attempts.removeRange(0, attempts.length - maxStoredAttempts);
    }
    final key = SkillProgress.keyFor(a.domain, a.targetId);
    skills.putIfAbsent(key, () => SkillProgress(a.domain, a.targetId)).apply(a);
  }

  /// Returns true only when the award is new.
  bool award(StickerAward s) {
    if (stickers.containsKey(s.id)) return false;
    stickers[s.id] = s;
    return true;
  }

  void notePlayed(GameType t) {
    recentGames.add(t);
    if (recentGames.length > 12) recentGames.removeAt(0);
  }

  Map<String, dynamic> toJson() => {
        'schema': schemaVersion,
        'learnerId': learnerId,
        'attempts': attempts.map((a) => a.toJson()).toList(),
        'skills': skills.values.map((s) => s.toJson()).toList(),
        'stickers': stickers.values.map((s) => s.toJson()).toList(),
        'completedLessons': completedLessons.toList(),
        'recentGames': recentGames.map((g) => g.name).toList(),
        'checkpoint': checkpoint?.toJson(),
        'legacyStars': legacyStars,
      };

  /// Lenient parse: invalid entries are dropped individually, so one bad
  /// record never loses the rest. [droppedEntries] reports how many.
  static LearnerProgressData fromJson(String learnerId, Map<String, dynamic> j, {void Function(int)? droppedEntries}) {
    var dropped = 0;
    for (final k in const ['attempts', 'skills', 'stickers', 'completedLessons', 'recentGames']) {
      if (j[k] != null && j[k] is! List) dropped++;
    }
    final data = LearnerProgressData(learnerId: learnerId);
    for (final raw in _list(j['attempts'])) {
      final a = ActivityAttempt.tryFromJson(raw);
      a == null ? dropped++ : data.attempts.add(a);
    }
    for (final raw in _list(j['skills'])) {
      final s = SkillProgress.tryFromJson(raw);
      s == null ? dropped++ : data.skills[s.key] = s;
    }
    for (final raw in _list(j['stickers'])) {
      final s = StickerAward.tryFromJson(raw);
      s == null ? dropped++ : data.stickers[s.id] = s;
    }
    data.completedLessons.addAll(_list(j['completedLessons']).whereType<String>());
    for (final name in _list(j['recentGames']).whereType<String>()) {
      for (final t in GameType.values) {
        if (t.name == name) data.recentGames.add(t);
      }
    }
    if (j['checkpoint'] != null) {
      data.checkpoint = SessionCheckpoint.tryFromJson(j['checkpoint']);
      if (data.checkpoint == null) dropped++;
    }
    final stars = j['legacyStars'];
    data.legacyStars = stars is int && stars > 0 ? stars : 0;
    droppedEntries?.call(dropped);
    return data;
  }
}

List<Object?> _list(Object? v) => v is List ? v : const [];
