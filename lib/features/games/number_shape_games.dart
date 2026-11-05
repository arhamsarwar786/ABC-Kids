import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/art/art_kit.dart';
import '../../core/design/art/word_art.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/models/content.dart';
import '../../data/models/learner.dart';
import '../../engine/activity_engine.dart';
import '../../state/progress_store.dart';
import '../../core/design/components/scaffolds.dart';
import 'game_framework.dart';

/// Count and Match: count a group of objects (1–10) and pick the numeral
/// from 2–3 choices. Number evidence only.
class CountMatchGame extends GameWidget {
  const CountMatchGame({super.key, required super.spec, required super.onFinished});
  @override
  State<CountMatchGame> createState() => _CountState();
}

class _CountState extends GameState<CountMatchGame> {
  @override
  String get title => 'Count and Match';

  @override
  SceneTheme get scene => SceneTheme.sunset;

  @override
  List<EngineRound> buildRounds() {
    final maxN = prefs.readiness == Readiness.starting ? 5 : 10;
    final targets = (List.generate(maxN, (i) => i + 1)..shuffle(random)).take(prefs.readiness == Readiness.starting ? 4 : 5).toList();
    return [
      for (var i = 0; i < targets.length; i++)
        () {
          final n = targets[i];
          final others = (List.generate(10, (k) => k + 1)
            ..remove(n)
            ..shuffle(random));
          // Prefer nearby numbers so counting matters, but keep them distinct.
          others.sort((a, b) => (a - n).abs().compareTo((b - n).abs()));
          final picks = others.take(choiceCountFor(i) - 1).toList();
          final choices = ['$n', ...picks.map((x) => '$x')]..shuffle(random);
          return EngineRound(
            targetId: Targets.number(n),
            answer: '$n',
            choices: choices,
            payload: WordArt.countingObjects[random.nextInt(WordArt.countingObjects.length)],
          );
        }(),
    ];
  }

  @override
  SkillDomain domainFor(EngineRound round) => SkillDomain.number;

  @override
  String instructionFor(EngineRound round) => 'How many?';

  @override
  bool get hasReplay => false;

  @override
  Future<bool> playPrompt(EngineRound round, PromptReason reason) async {
    if (reason == PromptReason.first && engine.roundIndex == 0) await sayInstruction('How many?');
    return true;
  }

  @override
  Widget buildBoard(BuildContext context) {
    final n = int.parse(engine.round.answer);
    return LayoutBuilder(builder: (context, c) {
      final objSize = math.min(64.0, math.min(c.maxWidth / 5.5, c.maxHeight / 6));
      return Column(children: [
        Semantics(
          label: '$n objects to count',
          excludeSemantics: true,
          child: SoftBox(
            child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < n; i++) Art(WordArt.countingObject(engine.round.payload as String), size: objSize),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ChoiceWrap(children: [
            for (var i = 0; i < engine.visibleChoices.length; i++)
              SizedBox(
                width: 100,
                height: 100,
                child: LetterTile(
                  letter: engine.visibleChoices[i],
                  color: pastelFor(i),
                  fontSize: 52,
                  semanticsLabel: 'number ${engine.visibleChoices[i]}',
                  state: tileStateFor(engine.visibleChoices[i]),
                  onTap: () => engine.choose(engine.visibleChoices[i]),
                ),
              ),
          ]),
        ),
      ]);
    });
  }
}

class SoftBox extends StatelessWidget {
  final Widget child;
  const SoftBox({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTokens.surface, borderRadius: BorderRadius.circular(AppTokens.radius), border: Border.all(color: AppTokens.outline)),
        child: child,
      );
}

/// Shape names used for display and the device voice.
const Map<ShapeKind, String> shapeNames = {
  ShapeKind.circle: 'circle',
  ShapeKind.square: 'square',
  ShapeKind.triangle: 'triangle',
  ShapeKind.rectangle: 'rectangle',
};

const List<Color> shapeColors = [Color(0xFFFF8A80), Color(0xFF6FB1F0), Color(0xFF6CC9A0), Color(0xFFFFC857), Color(0xFF9C7BEA)];

/// Shape games. [GameType.shapeMatch]: find the identical shape (colours vary
/// independently so colour is never the cue). [GameType.shapeName]: find the
/// named shape. Separate evidence domains.
class ShapeGame extends GameWidget {
  const ShapeGame({super.key, required super.spec, required super.onFinished});
  @override
  State<ShapeGame> createState() => _ShapeState();
}

class _ShapeState extends GameState<ShapeGame> {
  bool get _naming => widget.spec.type == GameType.shapeName;

  @override
  String get title => _naming ? 'Find the Shape' : 'Shape Match';

  @override
  SceneTheme get scene => SceneTheme.sky;

  @override
  bool get hasReplay => _naming;

  @override
  List<EngineRound> buildRounds() {
    final kinds = ShapeKind.values.toList();
    final n = prefs.readiness == Readiness.starting ? 4 : 5;
    return List.generate(n, (i) {
      final target = kinds[(i + random.nextInt(kinds.length)) % kinds.length];
      final others = kinds.where((k) => k != target).toList()..shuffle(random);
      final choices = [target, ...others.take(choiceCountFor(i) - 1)].map((k) => k.name).toList()..shuffle(random);
      // Colour per choice, chosen independently of shape; the target shown at
      // the top gets its own colour too.
      final colors = {
        for (final c in [...choices, '_target']) c: shapeColors[random.nextInt(shapeColors.length)]
      };
      return EngineRound(targetId: Targets.shape(target.name), answer: target.name, choices: choices, payload: colors);
    });
  }

  ShapeKind _kind(String name) => ShapeKind.values.firstWhere((k) => k.name == name);

  @override
  SkillDomain domainFor(EngineRound round) => _naming ? SkillDomain.shapeNaming : SkillDomain.shapeMatching;

  @override
  String instructionFor(EngineRound round) => _naming ? 'Find the ${shapeNames[_kind(round.answer)]}' : 'Find the same shape';

  @override
  Future<bool> playPrompt(EngineRound round, PromptReason reason) async {
    if (_naming) {
      // The name is always shown as text too, so a missing voice is not a
      // dead end; the prompt never blocks.
      await audio.speak('Find the ${shapeNames[_kind(round.answer)]}');
      return true;
    }
    if (reason == PromptReason.first && engine.roundIndex == 0) await sayInstruction('Find the same shape.');
    return true;
  }

  @override
  Widget buildBoard(BuildContext context) {
    final colors = engine.round.payload as Map<String, Color>;
    return LayoutBuilder(builder: (context, c) {
      final size = math.min(120.0, c.maxWidth / 3.4);
      return Column(children: [
        if (!_naming)
          Semantics(
            label: 'Target: ${shapeNames[_kind(engine.round.answer)]}',
            child: Art(ShapeArt(_kind(engine.round.answer), colors['_target']!), size: math.min(120, c.maxHeight * 0.28)),
          ),
        if (!_naming) const SizedBox(height: 12),
        Expanded(
          child: ChoiceWrap(children: [
            for (final name in engine.visibleChoices)
              Semantics(
                button: true,
                label: shapeNames[_kind(name)],
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () {
                    audio.playEffect(Effect.tap);
                    engine.choose(name);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: tileDecoration(AppTokens.surface, tileStateFor(name)),
                    child: Art(ShapeArt(_kind(name), colors[name]!), size: size),
                  ),
                ),
              ),
          ]),
        ),
      ]);
    });
  }
}
