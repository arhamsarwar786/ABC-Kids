import '../models/content.dart';
import 'content_catalog.dart';

class StickerDef {
  final String id;
  final String emoji;
  final String name;
  const StickerDef(this.id, this.emoji, this.name);
}

/// Built-in stickers and the deterministic award ids that make awarding
/// idempotent (the same achievement can never produce two stickers).
class StickerCatalog {
  static String lessonAwardId(String letterId) => 'lesson:$letterId';
  static String gameAwardId(GameType t) => 'game:${t.name}';
  static const String numbersExplorerAwardId = 'numbers:explorer';
  static const String shapesExplorerAwardId = 'shapes:explorer';

  static StickerDef forLesson(String letterId) {
    final words = ContentCatalog.pictureWordsFor(letterId);
    final emoji = words.isEmpty ? '⭐' : words.first.picture.emoji;
    return StickerDef('lesson-$letterId', emoji, 'Sound $letterId');
  }

  static StickerDef forGame(GameType t) {
    final def = ContentCatalog.activities[t];
    return switch (t) {
      GameType.countMatch => const StickerDef('game-countMatch', '🔢', 'Counting'),
      GameType.shapeMatch => const StickerDef('game-shapeMatch', '🔷', 'Shape match'),
      GameType.shapeName => const StickerDef('game-shapeName', '🔺', 'Shape names'),
      _ => StickerDef('game-${t.name}', def?.emoji ?? '🎈', def?.title ?? 'Game'),
    };
  }

  static const StickerDef legacyStar = StickerDef('legacy-star', '🌟', 'Star from before');
  static const StickerDef numbersExplorer = StickerDef('numbers-explorer', '🧮', 'Number explorer');
  static const StickerDef shapesExplorer = StickerDef('shapes-explorer', '🟣', 'Shape explorer');

  static StickerDef byId(String stickerId) {
    if (stickerId == legacyStar.id) return legacyStar;
    if (stickerId == numbersExplorer.id) return numbersExplorer;
    if (stickerId == shapesExplorer.id) return shapesExplorer;
    if (stickerId.startsWith('lesson-')) return forLesson(stickerId.substring(7));
    if (stickerId.startsWith('game-')) {
      final name = stickerId.substring(5);
      for (final t in GameType.values) {
        if (t.name == name) return forGame(t);
      }
    }
    return StickerDef(stickerId, '⭐', 'Sticker');
  }
}
