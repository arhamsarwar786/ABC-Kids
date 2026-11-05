import '../data/content/audio_manifest.dart';
import '../data/content/content_catalog.dart';
import '../data/models/content.dart';

enum PopMode { phoneme, visual }

class GameAvailability {
  final bool available;

  /// Parent-facing explanation when unavailable or running in an alternate mode.
  final String note;
  final PopMode? popMode;
  const GameAvailability(this.available, {this.note = '', this.popMode});
}

/// Decides honestly what can run, based on what is really bundled and
/// reviewed. Pure and synchronous so it can be unit tested.
class ContentAvailability {
  final bool Function(AudioAsset? asset) assetPlayable;
  final bool wordAudio;

  const ContentAvailability({required this.assetPlayable, required this.wordAudio});

  bool phonemeAvailable(String letterId) {
    final l = ContentCatalog.letter(letterId);
    final a = AudioManifest.byId(l?.phonemeAudioId);
    return a != null && a.usableForPhonics && assetPlayable(a);
  }

  bool letterRecordingAvailable(String letterId) {
    final l = ContentCatalog.letter(letterId);
    return assetPlayable(AudioManifest.byId(l?.letterNameAudioId));
  }

  bool strokesAvailable(String letterId) => ContentCatalog.letter(letterId)?.strokes != null;

  GameAvailability forGame(GameType t, String letterId, {required Set<String> introduced}) {
    final others = introduced.where((x) => x != letterId).toList();
    switch (t) {
      case GameType.pop:
        if (phonemeAvailable(letterId) && others.any(phonemeAvailable)) {
          return const GameAvailability(true, popMode: PopMode.phoneme);
        }
        return const GameAvailability(true,
            popMode: PopMode.visual,
            note: 'Runs as “Pop the Letter” (visual matching): reviewed sound recordings are not bundled.');
      case GameType.feedMonster:
      case GameType.safari:
        if (ContentCatalog.wordsFor(letterId).isEmpty) {
          return const GameAvailability(false, note: 'No picture words for this letter yet.');
        }
        if (!wordAudio) {
          return const GameAvailability(false,
              note: 'Needs word audio: no word recordings are bundled and the device voice is off or unavailable.');
        }
        return const GameAvailability(true);
      case GameType.parking:
        return const GameAvailability(true);
      case GameType.buildLetter:
      case GameType.magicTrail:
        return strokesAvailable(letterId)
            ? const GameAvailability(true)
            : const GameAvailability(false, note: 'Letter shape data not authored for this letter yet.');
      case GameType.countMatch:
      case GameType.shapeMatch:
        return const GameAvailability(true);
      case GameType.shapeName:
        return wordAudio
            ? const GameAvailability(true)
            : const GameAvailability(true, note: 'Shape names shown as text only: device voice is off.');
    }
  }
}
