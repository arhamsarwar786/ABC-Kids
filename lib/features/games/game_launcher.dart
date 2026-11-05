import 'package:flutter/widgets.dart';

import '../../data/models/content.dart';
import 'build_letter_game.dart';
import 'feed_monster_game.dart';
import 'game_framework.dart';
import 'magic_trail_game.dart';
import 'number_shape_games.dart';
import 'parking_game.dart';
import 'pop_game.dart';
import 'safari_game.dart';

Widget buildGame(GameSpec spec, void Function(GameResult) onFinished, {Key? key}) {
  return switch (spec.type) {
    GameType.pop => PopGame(key: key, spec: spec, onFinished: onFinished),
    GameType.feedMonster => FeedMonsterGame(key: key, spec: spec, onFinished: onFinished),
    GameType.safari => SafariGame(key: key, spec: spec, onFinished: onFinished),
    GameType.parking => ParkingGame(key: key, spec: spec, onFinished: onFinished),
    GameType.buildLetter => BuildLetterGame(key: key, spec: spec, onFinished: onFinished),
    GameType.magicTrail => MagicTrailGame(key: key, spec: spec, onFinished: onFinished),
    GameType.countMatch => CountMatchGame(key: key, spec: spec, onFinished: onFinished),
    GameType.shapeMatch || GameType.shapeName => ShapeGame(key: key, spec: spec, onFinished: onFinished),
  };
}
