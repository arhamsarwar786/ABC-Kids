import '../models/content.dart';
import 'audio_manifest.dart';
import 'letter_strokes.dart';

/// Versioned, data-driven content. Bump [version] when ids or lesson-relevant
/// content changes; stored checkpoints from another version are re-validated.
class ContentCatalog {
  static const String version = '2026.11.2';

  static const Map<String, SoundPolicy> _policies = {
    'a': SoundPolicy('/a/', deferredSounds: ['/ai/', '/ar/'], note: 'Short a as in ant first.'),
    'b': SoundPolicy('/b/'),
    'c': SoundPolicy('/k/', deferredSounds: ['/s/'], note: 'Hard c as in cat first.'),
    'd': SoundPolicy('/d/'),
    'e': SoundPolicy('/e/', deferredSounds: ['/ee/'], note: 'Short e as in egg first.'),
    'f': SoundPolicy('/f/'),
    'g': SoundPolicy('/g/', deferredSounds: ['/j/'], note: 'Hard g as in goat first.'),
    'h': SoundPolicy('/h/'),
    'i': SoundPolicy('/i/', deferredSounds: ['/ie/'], note: 'Short i as in insect first.'),
    'j': SoundPolicy('/j/'),
    'k': SoundPolicy('/k/'),
    'l': SoundPolicy('/l/'),
    'm': SoundPolicy('/m/'),
    'n': SoundPolicy('/n/'),
    'o': SoundPolicy('/o/', deferredSounds: ['/oa/', '/oo/'], note: 'Short o as in octopus first.'),
    'p': SoundPolicy('/p/'),
    'q': SoundPolicy('/kw/', note: 'Taught with u (qu).'),
    'r': SoundPolicy('/r/'),
    's': SoundPolicy('/s/', deferredSounds: ['/z/'], note: 'Unvoiced s as in sun first.'),
    't': SoundPolicy('/t/'),
    'u': SoundPolicy('/u/', deferredSounds: ['/oo/', '/yoo/'], note: 'Short u as in umbrella first.'),
    'v': SoundPolicy('/v/'),
    'w': SoundPolicy('/w/'),
    'x': SoundPolicy('/ks/', note: 'Usually at the end of words (fox).'),
    'y': SoundPolicy('/y/', deferredSounds: ['/ee/', '/ie/'], note: 'Consonant y as in yes first.'),
    'z': SoundPolicy('/z/'),
  };

  static const List<WordExample> words = [
    WordExample(id: 'w_sun', text: 'sun', letterId: 's', beginningSound: '/s/', picture: PictureRef('☀️', 'a smiling sun')),
    WordExample(id: 'w_sock', text: 'sock', letterId: 's', beginningSound: '/s/', picture: PictureRef('🧦', 'a pair of socks')),
    WordExample(id: 'w_snake', text: 'snake', letterId: 's', beginningSound: '/s/', picture: PictureRef('🐍', 'a green snake')),
    WordExample(id: 'w_ant', text: 'ant', letterId: 'a', beginningSound: '/a/', picture: PictureRef('🐜', 'an ant')),
    WordExample(id: 'w_apple', text: 'apple', letterId: 'a', beginningSound: '/a/', picture: PictureRef('🍎', 'a red apple')),
    WordExample(id: 'w_alligator', text: 'alligator', letterId: 'a', beginningSound: '/a/', picture: PictureRef('🐊', 'an alligator')),
    WordExample(id: 'w_tiger', text: 'tiger', letterId: 't', beginningSound: '/t/', picture: PictureRef('🐯', 'a tiger')),
    WordExample(id: 'w_tomato', text: 'tomato', letterId: 't', beginningSound: '/t/', picture: PictureRef('🍅', 'a tomato')),
    WordExample(id: 'w_tent', text: 'tent', letterId: 't', beginningSound: '/t/', picture: PictureRef('⛺', 'a tent')),
    WordExample(id: 'w_pear', text: 'pear', letterId: 'p', beginningSound: '/p/', picture: PictureRef('🍐', 'a green pear')),
    WordExample(id: 'w_pizza', text: 'pizza', letterId: 'p', beginningSound: '/p/', picture: PictureRef('🍕', 'a slice of vegetable pizza')),
    WordExample(id: 'w_penguin', text: 'penguin', letterId: 'p', beginningSound: '/p/', picture: PictureRef('🐧', 'a penguin')),
    WordExample(id: 'w_insect', text: 'insect', letterId: 'i', beginningSound: '/i/', picture: PictureRef('🐞', 'a ladybird insect')),
    WordExample(id: 'w_ink', text: 'ink', letterId: 'i', beginningSound: '/i/', picture: PictureRef('🖋️', 'a pen with ink')),
    WordExample(id: 'w_nose', text: 'nose', letterId: 'n', beginningSound: '/n/', picture: PictureRef('👃', 'a nose')),
    WordExample(id: 'w_nut', text: 'nut', letterId: 'n', beginningSound: '/n/', picture: PictureRef('🥜', 'a peanut')),
    WordExample(id: 'w_net', text: 'net', letterId: 'n', beginningSound: '/n/', picture: PictureRef('🥅', 'a net')),
    WordExample(id: 'w_moon', text: 'moon', letterId: 'm', beginningSound: '/m/', picture: PictureRef('🌙', 'the moon')),
    WordExample(id: 'w_mouse', text: 'mouse', letterId: 'm', beginningSound: '/m/', picture: PictureRef('🐭', 'a mouse')),
    WordExample(id: 'w_monkey', text: 'monkey', letterId: 'm', beginningSound: '/m/', picture: PictureRef('🐒', 'a monkey')),
    WordExample(id: 'w_ball', text: 'ball', letterId: 'b', beginningSound: '/b/', picture: PictureRef('⚽', 'a ball')),
    WordExample(id: 'w_banana', text: 'banana', letterId: 'b', beginningSound: '/b/', picture: PictureRef('🍌', 'a banana')),
    WordExample(id: 'w_bus', text: 'bus', letterId: 'b', beginningSound: '/b/', picture: PictureRef('🚌', 'a yellow bus')),
    WordExample(id: 'w_cat', text: 'cat', letterId: 'c', beginningSound: '/k/', picture: PictureRef('🐱', 'a cat')),
    WordExample(id: 'w_cup', text: 'cup', letterId: 'c', beginningSound: '/k/', picture: PictureRef('☕', 'a blue cup')),
    WordExample(id: 'w_duck', text: 'duck', letterId: 'd', beginningSound: '/d/', picture: PictureRef('🦆', 'a duck')),
    WordExample(id: 'w_door', text: 'door', letterId: 'd', beginningSound: '/d/', picture: PictureRef('🚪', 'a wooden door')),
    WordExample(id: 'w_egg', text: 'egg', letterId: 'e', beginningSound: '/e/', picture: PictureRef('🥚', 'an egg')),
    WordExample(id: 'w_envelope', text: 'envelope', letterId: 'e', beginningSound: '/e/', picture: PictureRef('✉️', 'an envelope')),
    WordExample(id: 'w_fish', text: 'fish', letterId: 'f', beginningSound: '/f/', picture: PictureRef('🐟', 'a fish')),
    WordExample(id: 'w_flower', text: 'flower', letterId: 'f', beginningSound: '/f/', picture: PictureRef('🌸', 'a pink flower')),
    WordExample(id: 'w_goat', text: 'goat', letterId: 'g', beginningSound: '/g/', picture: PictureRef('🐐', 'a goat')),
    WordExample(id: 'w_grapes', text: 'grapes', letterId: 'g', beginningSound: '/g/', picture: PictureRef('🍇', 'a bunch of grapes')),
    WordExample(id: 'w_hat', text: 'hat', letterId: 'h', beginningSound: '/h/', picture: PictureRef('👒', 'a hat')),
    WordExample(id: 'w_house', text: 'house', letterId: 'h', beginningSound: '/h/', picture: PictureRef('🏠', 'a house')),
    WordExample(id: 'w_igloo', text: 'igloo', letterId: 'i', beginningSound: '/i/', picture: PictureRef('🧊', 'an igloo')),
    WordExample(id: 'w_jug', text: 'jug', letterId: 'j', beginningSound: '/j/', picture: PictureRef('🫖', 'a jug')),
    WordExample(id: 'w_jam', text: 'jam', letterId: 'j', beginningSound: '/j/', picture: PictureRef('🍓', 'a jar of strawberry jam')),
    WordExample(id: 'w_kite', text: 'kite', letterId: 'k', beginningSound: '/k/', picture: PictureRef('🪁', 'a kite')),
    WordExample(id: 'w_key', text: 'key', letterId: 'k', beginningSound: '/k/', picture: PictureRef('🔑', 'a gold key')),
    WordExample(id: 'w_lion', text: 'lion', letterId: 'l', beginningSound: '/l/', picture: PictureRef('🦁', 'a lion')),
    WordExample(id: 'w_leaf', text: 'leaf', letterId: 'l', beginningSound: '/l/', picture: PictureRef('🍃', 'a green leaf')),
    WordExample(id: 'w_octopus', text: 'octopus', letterId: 'o', beginningSound: '/o/', picture: PictureRef('🐙', 'an octopus')),
    WordExample(id: 'w_olive', text: 'olive', letterId: 'o', beginningSound: '/o/', picture: PictureRef('🫒', 'two green olives')),
    WordExample(id: 'w_quilt', text: 'quilt', letterId: 'q', beginningSound: '/kw/', picture: PictureRef('🟪', 'a patchwork quilt')),
    WordExample(id: 'w_queen', text: 'queen', letterId: 'q', beginningSound: '/kw/', picture: PictureRef('👑', 'a smiling queen with a crown')),
    WordExample(id: 'w_rainbow', text: 'rainbow', letterId: 'r', beginningSound: '/r/', picture: PictureRef('🌈', 'a rainbow')),
    WordExample(id: 'w_rocket', text: 'rocket', letterId: 'r', beginningSound: '/r/', picture: PictureRef('🚀', 'a rocket')),
    WordExample(id: 'w_umbrella', text: 'umbrella', letterId: 'u', beginningSound: '/u/', picture: PictureRef('☂️', 'an umbrella')),
    WordExample(id: 'w_up', text: 'up', letterId: 'u', beginningSound: '/u/', picture: PictureRef('🎈', 'a balloon going up')),
    WordExample(id: 'w_van', text: 'van', letterId: 'v', beginningSound: '/v/', picture: PictureRef('🚐', 'a van')),
    WordExample(id: 'w_vase', text: 'vase', letterId: 'v', beginningSound: '/v/', picture: PictureRef('🏺', 'a vase of flowers')),
    WordExample(id: 'w_whale', text: 'whale', letterId: 'w', beginningSound: '/w/', picture: PictureRef('🐳', 'a whale')),
    WordExample(id: 'w_watermelon', text: 'watermelon', letterId: 'w', beginningSound: '/w/', picture: PictureRef('🍉', 'a slice of watermelon')),
    WordExample(id: 'w_yoyo', text: 'yo-yo', letterId: 'y', beginningSound: '/y/', picture: PictureRef('🪀', 'a yo-yo')),
    WordExample(id: 'w_yoghurt', text: 'yoghurt', letterId: 'y', beginningSound: '/y/', picture: PictureRef('🥛', 'a pot of yoghurt')),
    WordExample(id: 'w_zebra', text: 'zebra', letterId: 'z', beginningSound: '/z/', picture: PictureRef('🦓', 'a zebra')),
    WordExample(id: 'w_zip', text: 'zip', letterId: 'z', beginningSound: '/z/', picture: PictureRef('🤐', 'a zip on a blue bag')),
  ];

  /// x has no picture words that start with its sound, so it has pictures
  /// where x comes at the end instead. They are shown with an “x is at the
  /// end” note and never used in beginning-sound games.
  static const List<WordExample> endSoundWords = [
    WordExample(id: 'w_box', text: 'box', letterId: 'x', beginningSound: '/b/', picture: PictureRef('📦', 'a box')),
    WordExample(id: 'w_fox', text: 'fox', letterId: 'x', beginningSound: '/f/', picture: PictureRef('🦊', 'a fox')),
  ];

  static final Map<String, WordExample> wordsById = {
    for (final w in [...words, ...endSoundWords]) w.id: w,
  };

  /// Pictures for a letter's lesson and letter book: words that start with
  /// its sound, or for x the words where it comes at the end.
  static List<WordExample> pictureWordsFor(String letterId) {
    final own = wordsFor(letterId);
    return own.isNotEmpty ? own : [for (final w in endSoundWords) if (w.letterId == letterId) w];
  }

  /// Picture word shown for a letter in the A–Z explorer.
  static WordExample alphabetWordFor(String letterId) {
    final pics = pictureWordsFor(letterId);
    if (pics.isEmpty) throw ArgumentError('No picture for $letterId');
    return pics.first;
  }

  /// True when the letter's sound is not at the start of its picture word.
  static bool soundNotAtStart(WordExample w) => letter(w.letterId)?.soundPolicy.taughtSound != w.beginningSound;

  /// Lowercase letters that are mirror or flipped copies of each other.
  /// Toddlers are not asked to tell these apart.
  static const Set<String> _lookAlikes = {'bd', 'pq', 'bp', 'dq', 'nu', 'mw'};

  static bool lookAlike(String a, String b) => _lookAlikes.contains('$a$b') || _lookAlikes.contains('$b$a');

  static final List<LetterContent> letters = [
    for (final l in 'abcdefghijklmnopqrstuvwxyz'.split(''))
      LetterContent(
        id: l,
        lower: l,
        upper: l.toUpperCase(),
        soundPolicy: _policies[l]!,
        phonemeAudioId: AudioManifest.phonemeId(l),
        letterNameAudioId: AudioManifest.letterNameId(l),
        wordIds: [for (final w in words) if (w.letterId == l) w.id],
        strokes: LetterStrokeLibrary.all[l],
      ),
  ];

  static final Map<String, LetterContent> lettersById = {for (final l in letters) l.id: l};

  static LetterContent? letter(String id) => lettersById[id];

  static List<WordExample> wordsFor(String letterId) =>
      [for (final w in words) if (w.letterId == letterId) w];

  /// Letters that have enough content for a guided lesson: pictures to
  /// meet and discover, and letter shapes for building.
  static bool hasLessonContent(String letterId) {
    final l = lettersById[letterId];
    return l != null && l.strokes != null && pictureWordsFor(letterId).length >= 2;
  }

  static const Map<GameType, ActivityDefinition> activities = {
    GameType.pop: ActivityDefinition(
      type: GameType.pop,
      title: 'Pop the Sound',
      childPrompt: 'Listen, then pop the bubble with that sound.',
      parentDescription:
          'Hears a sound and pops the matching letter. Needs reviewed phoneme recordings; '
          'without them it runs as “Pop the Letter”, a visual letter-matching game that is not phonics evidence.',
      emoji: '🫧',
      needsPhonemeAudio: true,
      needsIntroducedDistractor: true,
    ),
    GameType.feedMonster: ActivityDefinition(
      type: GameType.feedMonster,
      title: 'Feed the Monster',
      childPrompt: 'Feed the monster a picture that starts with this sound.',
      parentDescription: 'Chooses pictures whose word begins with the target letter sound.',
      emoji: '👾',
      needsWordAudio: true,
    ),
    GameType.safari: ActivityDefinition(
      type: GameType.safari,
      title: 'Sound Safari',
      childPrompt: 'Find the picture.',
      parentDescription:
          'Level 1: hear a word and find its picture (word–picture). '
          'Level 2: find the picture that starts with the letter sound (beginning sound). Recorded separately.',
      emoji: '🔭',
      needsWordAudio: true,
    ),
    GameType.parking: ActivityDefinition(
      type: GameType.parking,
      title: 'Letter Parking',
      childPrompt: 'Park each car in the garage with the same letter.',
      parentDescription:
          'Matches identical lowercase letters, then upper/lower case pairs. Visual matching only, not phonics evidence.',
      emoji: '🚗',
    ),
    GameType.buildLetter: ActivityDefinition(
      type: GameType.buildLetter,
      title: 'Build a Letter',
      childPrompt: 'Put the pieces in the letter shape.',
      parentDescription: 'Assembles a letter from pieces that fit its outline.',
      emoji: '🧩',
      needsStrokes: true,
    ),
    GameType.magicTrail: ActivityDefinition(
      type: GameType.magicTrail,
      title: 'Magic Trail',
      childPrompt: 'Follow the trail from the green dot.',
      parentDescription: 'Optional tracing following stroke order. Can be skipped and never blocks lessons.',
      emoji: '✨',
      needsStrokes: true,
      optional: true,
    ),
  };
}
