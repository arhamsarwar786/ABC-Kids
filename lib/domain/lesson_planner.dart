import 'dart:math';

import '../data/content/content_catalog.dart';
import '../data/models/content.dart';
import '../data/models/learner.dart';
import '../data/models/progress.dart';
import 'availability.dart';

/// Builds a guided lesson for one sound:
/// introduction → picture discovery → 2–3 games → completion.
///
/// Game choice considers availability (real assets), readiness (2 games when
/// starting, 3 when growing), evidence (weaker phonics evidence first),
/// variety (recently played games are de-prioritised) and the tracing
/// preference. Distractor letters come only from sounds already introduced.
class LessonPlanner {
  final ContentAvailability availability;
  final Random random;
  LessonPlanner(this.availability, {Random? random}) : random = random ?? Random();

  static const List<GameType> lessonGames = [
    GameType.feedMonster,
    GameType.safari,
    GameType.pop,
    GameType.parking,
    GameType.buildLetter,
    GameType.magicTrail,
  ];

  LessonPlan plan({
    required String letterId,
    required LearningPreferences prefs,
    required Set<String> introduced,
    required List<GameType> recentGames,
    ProgressLabel Function(SkillDomain d)? labelFor,
  }) {
    // Distractors: the introduced sounds nearest before this one in the
    // sequence (then after it), skipping mirror-image letters such as b/d.
    final seq = prefs.soundSequence;
    final at = seq.indexOf(letterId);
    final nearby = at < 0
        ? seq
        : [...seq.take(at).toList().reversed, ...seq.skip(at + 1)];
    final distractors = [
      for (final l in nearby)
        if (l != letterId && introduced.contains(l) && !ContentCatalog.lookAlike(l, letterId)) l,
    ].take(2).toList();

    final wanted = prefs.readiness == Readiness.starting ? 2 : 3;
    final recent = recentGames.length > 4 ? recentGames.sublist(recentGames.length - 4) : recentGames;

    bool isPhonics(GameType t) =>
        t == GameType.feedMonster ||
        t == GameType.safari ||
        (t == GameType.pop && availability.forGame(t, letterId, introduced: introduced).popMode == PopMode.phoneme);

    // Higher penalty the more recently a game was played.
    double recency(GameType t) {
      final i = recent.lastIndexOf(t);
      return i < 0 ? 0 : 4 + i / recent.length;
    }

    final jitter = {for (final t in lessonGames) t: random.nextDouble() * 0.5};
    double score(GameType t) {
      var s = 0.0;
      if (isPhonics(t)) s += 3;
      if (t == GameType.buildLetter) s += 1.5;
      final bs = labelFor?.call(SkillDomain.beginningSound);
      if (isPhonics(t) && bs != ProgressLabel.recognisedIndependently) s += 1;
      return s - recency(t) + jitter[t]!;
    }

    final candidates = [
      for (final t in lessonGames)
        if (t != GameType.magicTrail && availability.forGame(t, letterId, introduced: introduced).available) t,
    ]..sort((a, b) => score(b).compareTo(score(a)));

    // Always include one phonics-evidence game when one is available: the
    // least recently played. Remaining places go by score.
    final phonics = candidates.where(isPhonics).toList()..sort((a, b) => recency(a).compareTo(recency(b)));
    final ordered = [if (phonics.isNotEmpty) phonics.first, ...candidates.where((t) => phonics.isEmpty || t != phonics.first)];
    final chosen = ordered.take(wanted).toList();
    // Tracing is optional, offered last and skippable, never replacing phonics.
    final traceOk = prefs.tracingEnabled &&
        availability.forGame(GameType.magicTrail, letterId, introduced: introduced).available &&
        !recent.contains(GameType.magicTrail);
    if (traceOk && chosen.length < 3) chosen.add(GameType.magicTrail);

    final steps = <LessonStep>[
      const LessonStep(LessonStepKind.introduction),
      const LessonStep(LessonStepKind.pictureDiscovery),
      for (final t in chosen) LessonStep(LessonStepKind.activity, gameType: t, level: _level(t, prefs, labelFor)),
      const LessonStep(LessonStepKind.completion),
    ];
    return LessonPlan(letterId: letterId, distractorLetterIds: distractors, steps: steps);
  }

  int _level(GameType t, LearningPreferences prefs, ProgressLabel Function(SkillDomain d)? labelFor) {
    switch (t) {
      case GameType.safari:
        // Start with word–picture; move to beginning sound once words are familiar.
        final wp = labelFor?.call(SkillDomain.wordPicture) ?? ProgressLabel.notStarted;
        return prefs.readiness == Readiness.growing || wp != ProgressLabel.notStarted ? 1 : 0;
      case GameType.parking:
        final vm = labelFor?.call(SkillDomain.visualMatching) ?? ProgressLabel.notStarted;
        return prefs.letterCase == LetterCaseMode.lowercaseThenUppercase && vm != ProgressLabel.notStarted ? 1 : 0;
      default:
        return 0;
    }
  }

  /// Whether a lesson for [letterId] may be opened. Free play opens every
  /// letter; guided opens finished sounds and the next one.
  static bool isOpen(LearningPreferences prefs, Set<String> completedLessons, String letterId) {
    if (!ContentCatalog.hasLessonContent(letterId)) return false;
    if (prefs.mode == PlayMode.freePlay || completedLessons.contains(letterId)) return true;
    final next = nextSound(prefs, completedLessons);
    if (next == null) return true;
    final seq = prefs.soundSequence;
    return seq.indexOf(letterId) <= seq.indexOf(next);
  }

  /// The next sound in the guided sequence that has not completed a lesson.
  static String? nextSound(LearningPreferences prefs, Set<String> completedLessons) {
    for (final l in prefs.soundSequence) {
      if (ContentCatalog.hasLessonContent(l) && !completedLessons.contains(l)) return l;
    }
    return null;
  }
}
