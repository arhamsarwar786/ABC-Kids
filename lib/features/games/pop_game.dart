import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/art/characters.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/models/content.dart';
import '../../data/models/learner.dart';
import '../../domain/availability.dart';
import '../../engine/activity_engine.dart';
import '../../state/progress_store.dart';
import '../../core/design/components/scaffolds.dart';
import 'game_framework.dart';
import '../../core/design/app_icons.dart';

/// Pop the Sound. With reviewed phoneme recordings: hear a sound, pop its
/// letter (sound–letter evidence). Otherwise: "Pop the Letter", a visual
/// matching game recorded as visual matching only.
class PopGame extends GameWidget {
  const PopGame({super.key, required super.spec, required super.onFinished});
  @override
  State<PopGame> createState() => _PopGameState();
}

class _PopGameState extends GameState<PopGame> with SingleTickerProviderStateMixin {
  late final PopMode mode = availabilityOf(context)
          .forGame(GameType.pop, widget.spec.letters.first, introduced: {...widget.spec.distractors, ...widget.spec.letters}).popMode ??
      PopMode.visual;
  late final AnimationController _float;

  @override
  void initState() {
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    super.initState();
  }

  @override
  String get title => mode == PopMode.phoneme ? 'Pop the Sound' : 'Pop the Letter';

  @override
  SceneTheme get scene => SceneTheme.ocean;

  @override
  bool get supportsIntroDemo => true;

  @override
  List<EngineRound> buildRounds() {
    final n = prefs.readiness == Readiness.starting ? 4 : 5;
    final avail = availabilityOf(context);
    final pool = mode == PopMode.phoneme ? widget.spec.distractors.where(avail.phonemeAvailable).toList() : null;
    return List.generate(n, (i) {
      final target = widget.spec.letters[i % widget.spec.letters.length];
      final choices = [target, ...pickDistractors(target, choiceCountFor(i) - 1, pool: pool)]..shuffle(random);
      return EngineRound(targetId: Targets.letter(target), answer: target, choices: choices, payload: random.nextDouble());
    });
  }

  @override
  SkillDomain domainFor(EngineRound round) => mode == PopMode.phoneme ? SkillDomain.soundLetter : SkillDomain.visualMatching;

  @override
  String instructionFor(EngineRound round) => mode == PopMode.phoneme ? 'Pop the sound' : 'Pop the same letter';

  @override
  Future<bool> playPrompt(EngineRound round, PromptReason reason) async {
    if (mode == PopMode.phoneme) return playPhoneme(round.answer);
    if (reason == PromptReason.first && engine.roundIndex == 0) await sayInstruction('Pop the same letter!');
    return true;
  }

  @override
  bool get hasReplay => mode == PopMode.phoneme;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget? buildIntroDemo(BuildContext context) {
    final target = widget.spec.letters.first;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(mode == PopMode.phoneme ? 'Listen to the sound…' : 'Look at the letter…', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      Stack(clipBehavior: Clip.none, children: [
        _Bubble(letter: target, color: AppTokens.coral, size: 150, onTap: null),
        const Positioned(right: -10, bottom: -10, child: Icon(AppIcons.tap, size: 56, color: AppTokens.purple)),
      ]),
      const SizedBox(height: 16),
      Text('…then tap the matching bubble.', style: Theme.of(context).textTheme.titleLarge),
    ]);
  }

  @override
  Widget buildBoard(BuildContext context) {
    final still = reduceMotion(context);
    final round = engine.round;
    return LayoutBuilder(builder: (context, c) {
      final size = math.min(170.0, math.min(c.maxWidth / 2.2, c.maxHeight / 2.6));
      final bubbles = [
        for (var i = 0; i < engine.visibleChoices.length; i++)
          _floating(
            still: still,
            phase: i * 1.7 + (round.payload as double) * 3,
            child: _Bubble(
              letter: engine.visibleChoices[i],
              color: pastelFor(i + engine.roundIndex),
              size: size,
              state: tileStateFor(engine.visibleChoices[i]),
              popped: engine.feedback == FeedbackKind.correct && engine.visibleChoices[i] == round.answer,
              onTap: () {
                audio.playEffect(Effect.pop);
                engine.choose(engine.visibleChoices[i]);
              },
            ),
          ),
      ];
      return Column(children: [
        if (mode == PopMode.visual) ...[
          Semantics(label: 'Find the letter ${round.answer}', child: LetterCharacter(round.answer, size: math.min(110, c.maxHeight / 4))),
          const SizedBox(height: 8),
        ],
        Expanded(child: ChoiceWrap(spacing: 18, children: bubbles)),
      ]);
    });
  }

  Widget _floating({required bool still, required double phase, required Widget child}) {
    if (still) return child;
    return AnimatedBuilder(
      animation: _float,
      builder: (_, w) => Transform.translate(offset: Offset(0, 6 * math.sin(_float.value * 2 * math.pi + phase)), child: w),
      child: child,
    );
  }
}

class _Bubble extends StatelessWidget {
  final String letter;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final TileState state;
  final bool popped;
  const _Bubble(
      {required this.letter,
      required this.color,
      required this.size,
      required this.onTap,
      this.state = TileState.normal,
      this.popped = false});

  @override
  Widget build(BuildContext context) {
    final ring = switch (state) {
      TileState.hinted => AppTokens.purple,
      TileState.correct => AppTokens.success,
      TileState.gentleWrong => AppTokens.gentle,
      _ => Colors.transparent,
    };
    return Semantics(
      button: onTap != null,
      label: 'bubble with letter $letter',
      excludeSemantics: true,
      child: AnimatedScale(
        scale: popped ? 1.15 : 1,
        duration: motion(context, const Duration(milliseconds: 250)),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 5)),
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(child: CustomPaint(painter: BubbleArt(color))),
              Text(letter,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                      fontFamily: AppTokens.letterFont,
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.48,
                      color: AppTokens.navy,
                      height: 1.1)),
            ]),
          ),
        ),
      ),
    );
  }
}
