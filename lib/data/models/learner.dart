/// Local learner profiles and per-learner learning preferences.
///
/// Profiles hold only a nickname and a built-in avatar id: no date of birth,
/// email, photo or any account identifier.
library;

enum PlayMode { guided, freePlay }

/// How many choices a learner sees and how quickly rounds get harder.
enum Readiness { starting, growing }

enum LetterCaseMode { lowercaseOnly, lowercaseThenUppercase }

class LearningPreferences {
  final PlayMode mode;
  final Readiness readiness;

  /// Gentle active-time reminder in minutes. 0 disables the reminder.
  final int reminderMinutes;
  final LetterCaseMode letterCase;
  final bool tracingEnabled;

  /// Accent pack id. Only packs that actually exist in the bundle may be chosen.
  final String accentPackId;

  /// Guided sound sequence (letter ids, e.g. 's').
  final List<String> soundSequence;

  const LearningPreferences({
    this.mode = PlayMode.guided,
    this.readiness = Readiness.starting,
    this.reminderMinutes = 5,
    this.letterCase = LetterCaseMode.lowercaseOnly,
    this.tracingEnabled = false,
    this.accentPackId = defaultAccentPackId,
    this.soundSequence = defaultSoundSequence,
  });

  static const String defaultAccentPackId = 'bundled-unverified';
  /// Common UK phonics order covering every letter (q comes last, as “qu”).
  static const List<String> defaultSoundSequence = [
    's', 'a', 't', 'p', 'i', 'n', 'm', 'd', 'g', 'o', 'c', 'k', 'e',
    'u', 'r', 'h', 'b', 'f', 'l', 'j', 'v', 'w', 'x', 'y', 'z', 'q',
  ];

  /// Keeps the stored order of known letters (no repeats) and adds any
  /// missing letters in the default order, so every learner's path covers
  /// a–z. Older saves held only s a t p i n m; their order is kept.
  static List<String> completeSequence(List<String> seq) {
    final out = <String>[];
    for (final l in seq) {
      if (defaultSoundSequence.contains(l) && !out.contains(l)) out.add(l);
    }
    for (final l in defaultSoundSequence) {
      if (!out.contains(l)) out.add(l);
    }
    return out;
  }
  static const List<int> reminderOptions = [0, 5, 10, 15, 20];

  LearningPreferences copyWith({
    PlayMode? mode,
    Readiness? readiness,
    int? reminderMinutes,
    LetterCaseMode? letterCase,
    bool? tracingEnabled,
    String? accentPackId,
    List<String>? soundSequence,
  }) {
    return LearningPreferences(
      mode: mode ?? this.mode,
      readiness: readiness ?? this.readiness,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      letterCase: letterCase ?? this.letterCase,
      tracingEnabled: tracingEnabled ?? this.tracingEnabled,
      accentPackId: accentPackId ?? this.accentPackId,
      soundSequence: soundSequence == null ? this.soundSequence : completeSequence(soundSequence),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'readiness': readiness.name,
        'reminderMinutes': reminderMinutes,
        'letterCase': letterCase.name,
        'tracingEnabled': tracingEnabled,
        'accentPackId': accentPackId,
        'soundSequence': soundSequence,
      };

  factory LearningPreferences.fromJson(Map<String, dynamic> j) {
    const d = LearningPreferences();
    final rawSeq = j['soundSequence'];
    final seq = rawSeq is List ? rawSeq.whereType<String>().toList() : null;
    final minutes = j['reminderMinutes'];
    return LearningPreferences(
      mode: _enumOr(PlayMode.values, j['mode'], d.mode),
      readiness: _enumOr(Readiness.values, j['readiness'], d.readiness),
      reminderMinutes: minutes is int && minutes >= 0 ? minutes : d.reminderMinutes,
      letterCase: _enumOr(LetterCaseMode.values, j['letterCase'], d.letterCase),
      tracingEnabled: j['tracingEnabled'] is bool ? j['tracingEnabled'] as bool : d.tracingEnabled,
      accentPackId: j['accentPackId'] is String ? j['accentPackId'] as String : d.accentPackId,
      soundSequence: (seq == null || seq.isEmpty) ? d.soundSequence : completeSequence(seq),
    );
  }
}

/// Built-in avatars. Ids are stable and stored; emoji are display only.
class Avatar {
  final String id;
  final String emoji;
  final String label;
  const Avatar(this.id, this.emoji, this.label);

  static const List<Avatar> all = [
    Avatar('fox', '🦊', 'Fox'),
    Avatar('owl', '🦉', 'Owl'),
    Avatar('bear', '🐻', 'Bear'),
    Avatar('frog', '🐸', 'Frog'),
    Avatar('panda', '🐼', 'Panda'),
    Avatar('rabbit', '🐰', 'Rabbit'),
    Avatar('cat', '🐱', 'Cat'),
    Avatar('whale', '🐳', 'Whale'),
  ];

  static Avatar byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);
}

class LearnerProfile {
  final String id;
  final String nickname;
  final String avatarId;
  final DateTime createdAt;
  final bool isGuest;
  final LearningPreferences preferences;

  const LearnerProfile({
    required this.id,
    required this.nickname,
    required this.avatarId,
    required this.createdAt,
    this.isGuest = false,
    this.preferences = const LearningPreferences(),
  });

  static const int maxNicknameLength = 20;

  /// Trims, collapses whitespace and caps nickname length.
  static String cleanNickname(String raw) {
    final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length > maxNicknameLength ? t.substring(0, maxNicknameLength) : t;
  }

  LearnerProfile copyWith({
    String? nickname,
    String? avatarId,
    bool? isGuest,
    LearningPreferences? preferences,
  }) {
    return LearnerProfile(
      id: id,
      nickname: nickname ?? this.nickname,
      avatarId: avatarId ?? this.avatarId,
      createdAt: createdAt,
      isGuest: isGuest ?? this.isGuest,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'avatarId': avatarId,
        'createdAt': createdAt.toIso8601String(),
        'isGuest': isGuest,
        'preferences': preferences.toJson(),
      };

  /// Returns null if required fields are missing, so callers can recover.
  static LearnerProfile? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = raw.cast<String, dynamic>();
    final id = j['id'];
    final nickname = j['nickname'];
    if (id is! String || id.isEmpty || nickname is! String) return null;
    final prefs = j['preferences'];
    return LearnerProfile(
      id: id,
      nickname: nickname,
      avatarId: j['avatarId'] is String ? j['avatarId'] as String : Avatar.all.first.id,
      createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
      isGuest: j['isGuest'] == true,
      preferences: prefs is Map
          ? LearningPreferences.fromJson(prefs.cast<String, dynamic>())
          : const LearningPreferences(),
    );
  }
}

T _enumOr<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
