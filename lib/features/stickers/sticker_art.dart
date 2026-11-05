import 'package:flutter/material.dart';

import '../../core/design/art/art_kit.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/art/word_art.dart';
import '../../data/content/content_catalog.dart';
import '../../data/content/stickers.dart';

/// Vector artwork for a sticker id.
class StickerArtView extends StatelessWidget {
  final String stickerId;
  final double size;
  const StickerArtView(this.stickerId, {super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    if (stickerId.startsWith('lesson-')) {
      final words = ContentCatalog.pictureWordsFor(stickerId.substring(7));
      final painter = words.isEmpty ? null : WordArt.forWord(words.first.id);
      return Art(painter ?? const StarArt(), size: size);
    }
    if (stickerId == StickerCatalog.numbersExplorer.id) return Art(const StarArt(color: Color(0xFF6FB1F0)), size: size);
    if (stickerId == StickerCatalog.shapesExplorer.id) return Art(const ShapeArt(ShapeKind.triangle, Color(0xFF9C7BEA)), size: size);
    if (stickerId.startsWith('game-')) {
      final name = stickerId.substring(5);
      return switch (name) {
        'pop' => Art(const BubbleArt(Color(0xFFDCD0F7)), size: size),
        'feedMonster' => Art(const MonsterArt(happy: true), size: size),
        'safari' => Art(const SafariSceneArt(), size: size),
        'parking' =>
          SizedBox.square(dimension: size, child: FittedBox(child: CarArt(label: 'a', color: const Color(0xFF6FB1F0), width: size))),
        'buildLetter' => Art(const StarArt(color: Color(0xFFFF8A80)), size: size),
        'magicTrail' => Art(const StarArt(color: Color(0xFF9C7BEA)), size: size),
        'countMatch' => Art(WordArt.countingObject('ball'), size: size),
        'shapeMatch' => Art(const ShapeArt(ShapeKind.circle, Color(0xFF6CC9A0)), size: size),
        'shapeName' => Art(const ShapeArt(ShapeKind.square, Color(0xFFFFC857)), size: size),
        _ => Art(const StarArt(), size: size),
      };
    }
    return Art(const StarArt(), size: size);
  }
}
