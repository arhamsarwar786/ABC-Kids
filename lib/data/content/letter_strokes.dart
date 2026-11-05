import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../models/content.dart';

/// Lowercase a–z geometry used by Build Letter (pieces) and Magic Trail
/// (stroke order). Box is 1×1, y downwards; x-height 0.40, baseline 0.75.
///
/// Status is [ReviewStatus.unverified]: paths follow common UK print
/// formation but must be checked by a teacher before release.
class LetterStrokeLibrary {
  static List<Offset> _arc(double cx, double cy, double r, double fromDeg, double toDeg, {int steps = 18}) {
    return List.generate(steps + 1, (i) {
      final a = (fromDeg + (toDeg - fromDeg) * i / steps) * math.pi / 180;
      return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
    });
  }

  static List<Offset> _line(Offset a, Offset b, {int steps = 8}) =>
      List.generate(steps + 1, (i) => Offset.lerp(a, b, i / steps)!);

  static LetterStroke _path(List<Offset> pts, String group) => LetterStroke(StrokeKind.path, pts, group);

  static final Map<String, LetterStrokes> all = {
    // s: one stroke, top-right round to the left, then curve back.
    's': LetterStrokes([
      _path([
        ..._arc(0.5, 0.49, 0.09, -20, -270),
        ..._arc(0.5, 0.66, 0.09, -90, 150).skip(1),
      ], 's'),
    ]),
    // a: round anticlockwise, then the stick down on the right.
    'a': LetterStrokes([
      _path(_arc(0.47, 0.575, 0.16, -30, -390), 'a-round'),
      _path(_line(const Offset(0.64, 0.40), const Offset(0.64, 0.75)), 'a-stick'),
    ]),
    // t: down with a little curl, then the cross bar.
    't': LetterStrokes([
      _path([
        ..._line(const Offset(0.45, 0.20), const Offset(0.45, 0.66)),
        ..._arc(0.55, 0.66, 0.10, 180, 90).skip(1),
      ], 't-down'),
      _path(_line(const Offset(0.30, 0.40), const Offset(0.62, 0.40)), 't-bar'),
    ]),
    // p: down past the line, then back up and round.
    'p': LetterStrokes([
      _path(_line(const Offset(0.34, 0.40), const Offset(0.34, 0.97)), 'p-stem'),
      _path([
        const Offset(0.34, 0.50),
        ..._arc(0.50, 0.575, 0.16, -150, 150),
      ], 'p-bowl'),
    ]),
    // i: down, then the dot.
    'i': LetterStrokes([
      _path(_line(const Offset(0.5, 0.40), const Offset(0.5, 0.75)), 'i-stem'),
      const LetterStroke(StrokeKind.dot, [Offset(0.5, 0.26)], 'i-dot'),
    ]),
    // n: down, back up, over the hill and down.
    'n': LetterStrokes([
      _path(_line(const Offset(0.33, 0.40), const Offset(0.33, 0.75)), 'stem'),
      _path([
        ..._arc(0.50, 0.56, 0.17, -175, -5),
        ..._line(const Offset(0.67, 0.56), const Offset(0.67, 0.75)).skip(1),
      ], 'n-hill'),
    ]),
    // m: down, then two equal hills.
    'm': LetterStrokes([
      _path(_line(const Offset(0.20, 0.40), const Offset(0.20, 0.75)), 'stem'),
      _path([
        ..._arc(0.35, 0.55, 0.15, -175, -5),
        ..._line(const Offset(0.50, 0.55), const Offset(0.50, 0.75)).skip(1),
      ], 'm-hill'),
      _path([
        ..._arc(0.65, 0.55, 0.15, -175, -5),
        ..._line(const Offset(0.80, 0.55), const Offset(0.80, 0.75)).skip(1),
      ], 'm-hill'),
    ]),
    // b: tall stick down, then back up and round.
    'b': LetterStrokes([
      _path(_line(const Offset(0.34, 0.20), const Offset(0.34, 0.75), steps: 12), 'b-stem'),
      _path([
        const Offset(0.34, 0.50),
        ..._arc(0.50, 0.575, 0.16, -150, 150),
      ], 'b-bowl'),
    ]),
    // c: start at the top right and curl round to the left.
    'c': LetterStrokes([
      _path(_arc(0.52, 0.575, 0.16, -40, -320, steps: 20), 'c'),
    ]),
    // d: round anticlockwise, then the tall stick down on the right.
    'd': LetterStrokes([
      _path(_arc(0.47, 0.575, 0.16, -30, -390), 'd-round'),
      _path(_line(const Offset(0.64, 0.20), const Offset(0.64, 0.75), steps: 12), 'd-stick'),
    ]),
    // e: across the middle, then round and open.
    'e': LetterStrokes([
      _path([
        ..._line(const Offset(0.34, 0.575), const Offset(0.66, 0.575)),
        ..._arc(0.50, 0.575, 0.16, 0, -315, steps: 20).skip(1),
      ], 'e'),
    ]),
    // f: over the top and down, then the cross bar.
    'f': LetterStrokes([
      _path([
        ..._arc(0.56, 0.30, 0.10, -20, -180, steps: 10),
        ..._line(const Offset(0.46, 0.30), const Offset(0.46, 0.75), steps: 10).skip(1),
      ], 'f-down'),
      _path(_line(const Offset(0.32, 0.43), const Offset(0.62, 0.43)), 'f-bar'),
    ]),
    // g: round anticlockwise, then down below the line with a hook.
    'g': LetterStrokes([
      _path(_arc(0.47, 0.575, 0.16, -30, -390), 'g-round'),
      _path([
        ..._line(const Offset(0.64, 0.40), const Offset(0.64, 0.86), steps: 10),
        ..._arc(0.53, 0.86, 0.11, 0, 160, steps: 10).skip(1),
      ], 'g-hook'),
    ]),
    // h: tall stick down, back up, over the hill and down.
    'h': LetterStrokes([
      _path(_line(const Offset(0.33, 0.20), const Offset(0.33, 0.75), steps: 12), 'h-stem'),
      _path([
        ..._arc(0.50, 0.56, 0.17, -175, -5),
        ..._line(const Offset(0.67, 0.56), const Offset(0.67, 0.75)).skip(1),
      ], 'h-hill'),
    ]),
    // j: down below the line with a hook, then the dot.
    'j': LetterStrokes([
      _path([
        ..._line(const Offset(0.56, 0.40), const Offset(0.56, 0.86), steps: 10),
        ..._arc(0.45, 0.86, 0.11, 0, 160, steps: 10).skip(1),
      ], 'j-hook'),
      const LetterStroke(StrokeKind.dot, [Offset(0.56, 0.26)], 'j-dot'),
    ]),
    // k: tall stick down, then in and out.
    'k': LetterStrokes([
      _path(_line(const Offset(0.36, 0.20), const Offset(0.36, 0.75), steps: 12), 'k-stem'),
      _path([
        ..._line(const Offset(0.64, 0.40), const Offset(0.37, 0.60)),
        ..._line(const Offset(0.37, 0.60), const Offset(0.66, 0.75)).skip(1),
      ], 'k-kick'),
    ]),
    // l: one tall stick down.
    'l': LetterStrokes([
      _path(_line(const Offset(0.5, 0.20), const Offset(0.5, 0.75), steps: 12), 'l'),
    ]),
    // o: start at the top and go all the way round.
    'o': LetterStrokes([
      _path(_arc(0.5, 0.575, 0.16, -90, -450, steps: 24), 'o'),
    ]),
    // q: round anticlockwise, then down below the line.
    'q': LetterStrokes([
      _path(_arc(0.47, 0.575, 0.16, -30, -390), 'q-round'),
      _path(_line(const Offset(0.64, 0.40), const Offset(0.64, 0.97), steps: 12), 'q-tail'),
    ]),
    // r: down, back up and over.
    'r': LetterStrokes([
      _path(_line(const Offset(0.38, 0.40), const Offset(0.38, 0.75)), 'r-stem'),
      _path(_arc(0.53, 0.56, 0.15, -175, -50, steps: 10), 'r-over'),
    ]),
    // u: down, round and up, then the stick down.
    'u': LetterStrokes([
      _path([
        ..._line(const Offset(0.33, 0.40), const Offset(0.33, 0.58), steps: 4),
        ..._arc(0.50, 0.58, 0.17, 180, 0).skip(1),
        ..._line(const Offset(0.67, 0.58), const Offset(0.67, 0.40), steps: 4).skip(1),
      ], 'u-cup'),
      _path(_line(const Offset(0.67, 0.40), const Offset(0.67, 0.75)), 'u-stick'),
    ]),
    // v: down to the point and back up.
    'v': LetterStrokes([
      _path([
        ..._line(const Offset(0.32, 0.40), const Offset(0.50, 0.75)),
        ..._line(const Offset(0.50, 0.75), const Offset(0.68, 0.40)).skip(1),
      ], 'v'),
    ]),
    // w: down, up, down, up.
    'w': LetterStrokes([
      _path([
        ..._line(const Offset(0.20, 0.40), const Offset(0.33, 0.75), steps: 6),
        ..._line(const Offset(0.33, 0.75), const Offset(0.50, 0.48), steps: 6).skip(1),
        ..._line(const Offset(0.50, 0.48), const Offset(0.67, 0.75), steps: 6).skip(1),
        ..._line(const Offset(0.67, 0.75), const Offset(0.80, 0.40), steps: 6).skip(1),
      ], 'w'),
    ]),
    // x: one slope down, then the other.
    'x': LetterStrokes([
      _path(_line(const Offset(0.34, 0.40), const Offset(0.66, 0.75)), 'x-down'),
      _path(_line(const Offset(0.66, 0.40), const Offset(0.34, 0.75)), 'x-back'),
    ]),
    // y: short slope in, then the long slope down below the line.
    'y': LetterStrokes([
      _path(_line(const Offset(0.34, 0.40), const Offset(0.51, 0.68)), 'y-in'),
      _path(_line(const Offset(0.68, 0.40), const Offset(0.40, 0.97), steps: 12), 'y-down'),
    ]),
    // z: across, slide down, across.
    'z': LetterStrokes([
      _path([
        ..._line(const Offset(0.34, 0.40), const Offset(0.66, 0.40), steps: 6),
        ..._line(const Offset(0.66, 0.40), const Offset(0.34, 0.75), steps: 8).skip(1),
        ..._line(const Offset(0.34, 0.75), const Offset(0.66, 0.75), steps: 6).skip(1),
      ], 'z'),
    ]),
  };
}
