import '../models/content.dart';

/// Every audio asset the app knows about, with its honest review status.
///
/// To add a human-reviewed phoneme recording: put `m.mp3` into
/// `assets/audio/phonemes/`, then change that letter's entry below to
/// [ReviewStatus.reviewed] and record who reviewed it in [AudioAsset.note].
/// Until then phoneme-dependent games use their documented alternate mode.
class AudioManifest {
  static const String bundledPack = 'bundled-unverified';

  static const String _letterNote =
      'Bundled with the original app. Spoken content not transcribed or listened to; '
      'acoustic analysis suggests letter names. Never used as phonics.';
  static const String _numberNote =
      'Bundled with the original app. Spoken content not transcribed or listened to.';

  static String phonemeId(String letter) => 'phoneme_$letter';
  static String letterNameId(String letter) => 'letter_name_$letter';
  static String numberNameId(int n) => 'number_name_$n';

  /// Letters with reviewed phoneme recordings. Empty: none have been reviewed.
  static const Set<String> reviewedPhonemes = {};

  static final Map<String, AudioAsset> all = {
    for (final l in 'abcdefghijklmnopqrstuvwxyz'.split('')) ...{
      phonemeId(l): AudioAsset(
        id: phonemeId(l),
        kind: AudioKind.phoneme,
        path: reviewedPhonemes.contains(l) ? 'assets/audio/phonemes/$l.mp3' : null,
        status: reviewedPhonemes.contains(l) ? ReviewStatus.reviewed : ReviewStatus.missing,
        note: reviewedPhonemes.contains(l) ? '' : 'No phoneme recording in the bundle.',
      ),
      letterNameId(l): AudioAsset(
        id: letterNameId(l),
        kind: AudioKind.letterName,
        path: 'assets/audio/abc_letter_sound/$l.mp3',
        status: ReviewStatus.unverified,
        note: _letterNote,
      ),
    },
    for (var n = 0; n <= 10; n++)
      numberNameId(n): AudioAsset(
        id: numberNameId(n),
        kind: AudioKind.numberName,
        path: 'assets/audio/0-to-10_counting/$n.mp3',
        status: ReviewStatus.unverified,
        note: _numberNote,
      ),
    'music_background': const AudioAsset(
      id: 'music_background',
      kind: AudioKind.music,
      path: 'assets/audio/background sound/bakgound_sound.mp3',
      status: ReviewStatus.unverified,
      note: 'Original background music (licence not documented in repo).',
    ),
    for (final e in Effect.values)
      'effect_${e.name}': AudioAsset(
        id: 'effect_${e.name}',
        kind: AudioKind.effect,
        path: 'assets/audio/effects/${e.file}.wav',
        status: ReviewStatus.generated,
        note: 'Synthesised tone generated for this project.',
      ),
  };

  static AudioAsset? byId(String? id) => id == null ? null : all[id];
}

enum Effect {
  pop('pop'),
  chime('chime'),
  softTry('soft_try'),
  celebrate('celebrate'),
  tap('tap');

  final String file;
  const Effect(this.file);
}
