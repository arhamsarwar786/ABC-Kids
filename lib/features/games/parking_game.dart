import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/art/characters.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/models/content.dart';
import '../../data/models/learner.dart';
import '../../engine/activity_engine.dart';
import '../../state/progress_store.dart';
import '../../core/design/components/scaffolds.dart';
import 'game_framework.dart';
import '../../core/design/app_icons.dart';

/// Letter Parking. Level 0: identical lowercase letters. Level 1: uppercase
/// car to lowercase garage. Both are visual matching, recorded separately and
/// never counted as phonics evidence. Drag the car, or tap a garage.
class ParkingGame extends GameWidget {
  const ParkingGame({super.key, required super.spec, required super.onFinished});
  @override
  State<ParkingGame> createState() => _ParkingState();
}

class _ParkingState extends GameState<ParkingGame> {
  bool get _caseLevel => widget.spec.level == 1;
  String? _hoverGarage;

  @override
  String get title => _caseLevel ? 'Letter Parking · Big and small' : 'Letter Parking';

  @override
  SceneTheme get scene => SceneTheme.town;

  @override
  bool get hasReplay => false;

  @override
  bool get supportsIntroDemo => true;

  @override
  List<EngineRound> buildRounds() {
    final n = prefs.readiness == Readiness.starting ? 4 : 5;
    return List.generate(n, (i) {
      final letter = widget.spec.letters[i % widget.spec.letters.length];
      final choices = [letter, ...pickDistractors(letter, choiceCountFor(i) - 1)]..shuffle(random);
      return EngineRound(targetId: Targets.letter(letter), answer: letter, choices: choices, payload: random.nextInt(5));
    });
  }

  @override
  SkillDomain domainFor(EngineRound round) => _caseLevel ? SkillDomain.caseMatching : SkillDomain.visualMatching;

  @override
  String instructionFor(EngineRound round) => _caseLevel ? 'Park with the small letter' : 'Park the car';

  @override
  Future<bool> playPrompt(EngineRound round, PromptReason reason) async {
    if (reason == PromptReason.first && engine.roundIndex == 0) {
      await sayInstruction('Park the car in the same letter!');
    }
    return true;
  }

  String get _carLabel => _caseLevel ? engine.round.answer.toUpperCase() : engine.round.answer;

  @override
  Widget? buildIntroDemo(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GarageArt(label: 'm', color: AppTokens.blueDeep, width: 110, highlight: true),
        ]),
        const Icon(AppIcons.up, size: 48, color: AppTokens.purple),
        CarArt(label: _caseLevel ? 'M' : 'm', color: const Color(0xFF9C7BEA), width: 130),
        const SizedBox(height: 12),
        Text('Drive each car into its garage.', style: Theme.of(context).textTheme.titleLarge),
      ]);

  @override
  Widget buildBoard(BuildContext context) {
    final carColor =
        const [Color(0xFF9C7BEA), Color(0xFF6FB1F0), Color(0xFFFF8A80), Color(0xFF6CC9A0), Color(0xFFFFC857)][engine.round.payload as int];
    return LayoutBuilder(builder: (context, c) {
      final count = engine.visibleChoices.length;
      final gw = math.min(130.0, (c.maxWidth - 16 * (count - 1)) / count);
      final car = CarArt(label: _carLabel, color: carColor, width: math.min(150, c.maxWidth * 0.4));
      final parked = engine.feedback == FeedbackKind.correct;
      return Column(children: [
        Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.center, children: [
          for (final g in engine.visibleChoices)
            DragTarget<String>(
              onWillAcceptWithDetails: (_) {
                setState(() => _hoverGarage = g);
                return true;
              },
              onLeave: (_) => setState(() => _hoverGarage = null),
              onAcceptWithDetails: (_) {
                setState(() => _hoverGarage = null);
                engine.choose(g);
              },
              builder: (context, _, _) => Semantics(
                button: true,
                label: 'garage with letter $g',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => engine.choose(g),
                  child: GarageArt(
                    label: g,
                    color: AppTokens.blueDeep,
                    width: gw,
                    highlight: _hoverGarage == g || tileStateFor(g) == TileState.hinted,
                    filled: parked && g == engine.round.answer,
                  ),
                ),
              ),
            ),
        ]),
        const Spacer(),
        AnimatedOpacity(
          opacity: parked ? 0 : 1,
          duration: motion(context, const Duration(milliseconds: 300)),
          child: Semantics(
            label: 'car with letter $_carLabel. Drag to a garage.',
            child: Draggable<String>(
              data: engine.round.answer,
              feedback: Material(type: MaterialType.transparency, child: car),
              childWhenDragging: Opacity(opacity: 0.3, child: car),
              child: car,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ]);
    });
  }
}
