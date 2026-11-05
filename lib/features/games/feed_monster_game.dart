import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/art/art_kit.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../../data/models/learner.dart';
import '../../engine/activity_engine.dart';
import '../../state/progress_store.dart';
import 'game_framework.dart';

/// Feed the Monster: choose the picture whose word begins with the letter's
/// sound. Tap a picture to hear its word; feed by dragging it to the mouth or
/// by tapping it and then the monster. Beginning-sound evidence.
class FeedMonsterGame extends GameWidget {
  const FeedMonsterGame({super.key, required super.spec, required super.onFinished});
  @override
  State<FeedMonsterGame> createState() => _FeedMonsterState();
}

class _FeedMonsterState extends GameState<FeedMonsterGame> {
  String? _selected;
  bool _hovering = false;

  @override
  String get title => 'Feed the Monster';

  @override
  bool get supportsIntroDemo => true;

  @override
  List<EngineRound> buildRounds() {
    final n = prefs.readiness == Readiness.starting ? 4 : 5;
    return List.generate(n, (i) {
      final letter = widget.spec.letters[i % widget.spec.letters.length];
      final (target, others) = wordChoices(letter, choiceCountFor(i) - 1);
      final choices = [target.id, ...others.map((w) => w.id)]..shuffle(random);
      return EngineRound(targetId: Targets.letter(letter), answer: target.id, choices: choices, payload: letter);
    });
  }

  String get _letter => engine.round.payload as String;

  @override
  SkillDomain domainFor(EngineRound round) => SkillDomain.beginningSound;

  @override
  String instructionFor(EngineRound round) => 'Feed me!';

  @override
  Future<bool> playPrompt(EngineRound round, PromptReason reason) async {
    _selected = null;
    final avail = availabilityOf(context);
    if (avail.phonemeAvailable(round.payload as String)) return playPhoneme(round.payload as String);
    if (reason == PromptReason.first && engine.roundIndex == 0) {
      await sayInstruction('Feed me the picture that starts like my letter!');
    }
    return true;
  }

  void _listen(WordExample w) => audio.playWord(w);

  void _feed(String wordId) {
    setState(() => _selected = null);
    engine.choose(wordId);
  }

  @override
  Widget? buildIntroDemo(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Art(MonsterArt(mouth: 0.9, happy: true), size: 170),
        const SizedBox(height: 12),
        Text('I’m hungry!', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Tap a picture to hear it.\nDrag it to my mouth, or tap it and then tap me.',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
      ]);

  @override
  Widget buildBoard(BuildContext context) {
    final happy = engine.feedback == FeedbackKind.correct;
    return LayoutBuilder(builder: (context, c) {
      final monsterSize = math.min(200.0, c.maxHeight * 0.42);
      final cardArt = math.min(84.0, c.maxHeight * 0.16);
      return Column(children: [
        DragTarget<String>(
          onWillAcceptWithDetails: (_) {
            setState(() => _hovering = true);
            return true;
          },
          onLeave: (_) => setState(() => _hovering = false),
          onAcceptWithDetails: (d) {
            setState(() => _hovering = false);
            _feed(d.data);
          },
          builder: (context, _, _) => Semantics(
            button: _selected != null,
            label: _selected == null ? 'monster with letter $_letter' : 'feed the monster',
            child: GestureDetector(
              onTap: _selected == null ? null : () => _feed(_selected!),
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                AnimatedScale(
                  scale: _hovering || happy ? 1.06 : 1,
                  duration: motion(context, const Duration(milliseconds: 200)),
                  child: Art(MonsterArt(mouth: _hovering || _selected != null ? 1 : 0.5, happy: happy), size: monsterSize),
                ),
                Positioned(
                  right: -6,
                  top: 0,
                  child: SizedBox(width: 64, height: 64, child: LetterTile(letter: _letter, color: AppTokens.yellow, fontSize: 40)),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ChoiceWrap(children: [
            for (final id in engine.visibleChoices)
              _FoodCard(
                word: ContentCatalog.wordsById[id]!,
                artSize: cardArt,
                state: _selected == id ? TileState.selected : tileStateFor(id),
                onTap: () {
                  setState(() => _selected = id);
                  _listen(ContentCatalog.wordsById[id]!);
                },
                onListen: () => _listen(ContentCatalog.wordsById[id]!),
              ),
          ]),
        ),
      ]);
    });
  }
}

class _FoodCard extends StatelessWidget {
  final WordExample word;
  final double artSize;
  final TileState state;
  final VoidCallback onTap;
  final VoidCallback onListen;
  const _FoodCard({required this.word, required this.artSize, required this.state, required this.onTap, required this.onListen});

  @override
  Widget build(BuildContext context) {
    final tile = SizedBox(
      width: artSize + 48,
      child: PictureTile(word: word, artSize: artSize, state: state, onTap: onTap, onListen: onListen),
    );
    return Draggable<String>(
      data: word.id,
      feedback: Material(type: MaterialType.transparency, child: WordPicture(word, size: artSize)),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}
