/// Data-driven learning content: letters, words, audio assets, activities.
library;

import 'dart:ui' show Offset;

/// What a recording is supposed to contain. Sound, letter name and word audio
/// are always distinct assets and are never substituted for one another.
enum AudioKind { phoneme, letterName, word, numberName, shapeName, music, effect }

/// Review state of an audio asset.
///
/// * [reviewed]: a person listened and confirmed the content. Required for
///   any phonics (phoneme) use.
/// * [unverified]: file exists but its spoken content has not been confirmed.
/// * [missing]: no file is bundled.
/// * [generated]: synthesised by this project (effects only, never speech).
enum ReviewStatus { reviewed, unverified, missing, generated }

class AudioAsset {
  final String id;
  final AudioKind kind;

  /// Asset path relative to the bundle root, e.g. `assets/audio/...`.
  final String? path;
  final ReviewStatus status;

  /// Accent pack this recording belongs to.
  final String accentPackId;
  final String note;

  const AudioAsset({
    required this.id,
    required this.kind,
    required this.path,
    required this.status,
    this.accentPackId = 'bundled-unverified',
    this.note = '',
  });

  bool get hasFile => path != null && status != ReviewStatus.missing;

  /// Phoneme audio may only be used for phonics when a person reviewed it.
  bool get usableForPhonics => kind == AudioKind.phoneme && status == ReviewStatus.reviewed && hasFile;
}

/// How a letter's sound is taught. Letters with several common sounds state
/// which one is taught first and which are deliberately deferred.
class SoundPolicy {
  final String taughtSound; // e.g. '/m/'
  final List<String> deferredSounds;
  final String note;
  const SoundPolicy(this.taughtSound, {this.deferredSounds = const [], this.note = ''});
}

/// Simple picture for a word. Emoji are placeholders until illustrations exist.
class PictureRef {
  final String emoji;
  final String description;
  const PictureRef(this.emoji, this.description);
}

class WordExample {
  final String id;
  final String text;
  final String letterId;

  /// Sound the word begins with, matched against [SoundPolicy.taughtSound].
  final String beginningSound;
  final PictureRef picture;

  /// Recorded word audio id, or null. Without it the device voice may be used
  /// for whole words only (never isolated sounds) if the parent enables it.
  final String? audioId;

  const WordExample({
    required this.id,
    required this.text,
    required this.letterId,
    required this.beginningSound,
    required this.picture,
    this.audioId,
  });
}

enum StrokeKind { path, dot }

/// One stroke of a letter in a 1×1 box (y grows downwards).
/// x-height top ≈ 0.40, baseline ≈ 0.75, descender ≈ 0.98, ascender ≈ 0.15.
class LetterStroke {
  final StrokeKind kind;
  final List<Offset> points;

  /// Pieces with the same group have identical geometry (up to translation),
  /// so Build Letter accepts them in either matching slot.
  final String shapeGroup;
  const LetterStroke(this.kind, this.points, this.shapeGroup);

  Offset get start => points.first;
}

class LetterStrokes {
  final List<LetterStroke> strokes;

  /// Stroke order and paths must be reviewed by a teacher before release.
  final ReviewStatus status;
  const LetterStrokes(this.strokes, {this.status = ReviewStatus.unverified});
}

class LetterContent {
  final String id; // stable, lowercase letter
  final String lower;
  final String upper;
  final SoundPolicy soundPolicy;
  final String phonemeAudioId;
  final String letterNameAudioId;
  final List<String> wordIds;
  final LetterStrokes? strokes;

  const LetterContent({
    required this.id,
    required this.lower,
    required this.upper,
    required this.soundPolicy,
    required this.phonemeAudioId,
    required this.letterNameAudioId,
    this.wordIds = const [],
    this.strokes,
  });
}

enum GameType { pop, feedMonster, safari, parking, buildLetter, magicTrail, countMatch, shapeMatch, shapeName }

/// Skill evidence domains. They are recorded and reported separately.
enum SkillDomain {
  exposure,
  soundLetter,
  letterName,
  beginningSound,
  wordPicture,
  visualMatching,
  caseMatching,
  construction,
  tracing,
  number,
  shapeMatching,
  shapeNaming,
}

extension SkillDomainText on SkillDomain {
  String get label => switch (this) {
        SkillDomain.exposure => 'Explored',
        SkillDomain.soundLetter => 'Sound to letter',
        SkillDomain.letterName => 'Letter recordings (unverified)',
        SkillDomain.beginningSound => 'Beginning sounds',
        SkillDomain.wordPicture => 'Word to picture',
        SkillDomain.visualMatching => 'Letter shape matching (visual)',
        SkillDomain.caseMatching => 'Upper/lower case matching (visual)',
        SkillDomain.construction => 'Building letters',
        SkillDomain.tracing => 'Tracing',
        SkillDomain.number => 'Counting and numbers',
        SkillDomain.shapeMatching => 'Shape matching',
        SkillDomain.shapeNaming => 'Shape names',
      };

  /// Only these domains count as phonics evidence.
  bool get isPhonics =>
      this == SkillDomain.soundLetter || this == SkillDomain.beginningSound;
}

/// Static description of a game and what it needs to run honestly.
class ActivityDefinition {
  final GameType type;
  final String title;
  final String childPrompt;
  final String parentDescription;
  final String emoji;
  final bool needsPhonemeAudio;
  final bool needsWordAudio;
  final bool needsStrokes;

  /// Needs at least one other introduced sound as a distractor.
  final bool needsIntroducedDistractor;
  final bool optional;

  const ActivityDefinition({
    required this.type,
    required this.title,
    required this.childPrompt,
    required this.parentDescription,
    required this.emoji,
    this.needsPhonemeAudio = false,
    this.needsWordAudio = false,
    this.needsStrokes = false,
    this.needsIntroducedDistractor = false,
    this.optional = false,
  });
}
