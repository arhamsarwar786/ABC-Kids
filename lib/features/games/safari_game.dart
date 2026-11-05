import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../../data/models/learner.dart';
import '../../engine/activity_engine.dart';
import '../../state/progress_store.dart';
import '../../core/design/components/scaffolds.dart';
import 'game_framework.dart';

/// Sound Safari.
/// Level 0 (word–picture): hear a word, find its picture. The word audio is
/// essential: if it cannot play, the engine shows retry / another activity.
/// Level 1 (beginning sound): find the picture that starts like the letter.
class SafariGame extends GameWidget {
  const SafariGame({super.key, required super.spec, required super.onFinished});
  @override
  State<SafariGame> createState() => _SafariState();
}

class _SafariState extends GameState<SafariGame> {
  bool get _wordLevel => widget.spec.level == 0;

  @override
  String get title => _wordLevel ? 'Sound Safari · Words' : 'Sound Safari · First sounds';

  @override
  SceneTheme get scene => SceneTheme.sunset;

  @override
  List<EngineRound> buildRounds() {
    final n = prefs.readiness == Readiness.starting ? 4 : 5;
    return List.generate(n, (i) {
      final letter = widget.spec.letters[i % widget.spec.letters.length];
      final (target, others) = wordChoices(letter, choiceCountFor(i) - 1);
      final choices = [target.id, ...others.map((w) => w.id)]..shuffle(random);
      return EngineRound(
        targetId: _wordLevel ? Targets.word(target.id) : Targets.letter(letter),
        answer: target.id,
        choices: choices,
        payload: letter,
      );
    });
  }

  @override
  SkillDomain domainFor(EngineRound round) => _wordLevel ? SkillDomain.wordPicture : SkillDomain.beginningSound;

  @override
  String instructionFor(EngineRound round) => _wordLevel ? 'Find it!' : 'Which one starts like this?';

  @override
  Future<bool> playPrompt(EngineRound round, PromptReason reason) async {
    if (_wordLevel) {
      final r = await audio.playWord(ContentCatalog.wordsById[round.answer]!);
      return r == PlayResult.played || r == PlayResult.cancelled;
    }
    final letter = round.payload as String;
    if (availabilityOf(context).phonemeAvailable(letter)) return playPhoneme(letter);
    if (reason == PromptReason.first && engine.roundIndex == 0) {
      await sayInstruction('Which one starts like this letter?');
    }
    return true;
  }

  @override
  Widget buildBoard(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final art = math.min(96.0, c.maxHeight * 0.2);
      return Stack(children: [
        const Positioned(
            left: 0, right: 0, bottom: 0, height: 140, child: Opacity(opacity: 0.8, child: CustomPaint(painter: SafariSceneArt()))),
        Column(children: [
          if (!_wordLevel)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                  width: 84, height: 84, child: LetterTile(letter: engine.round.payload as String, color: AppTokens.yellow, fontSize: 50)),
            ),
          Expanded(
            child: ChoiceWrap(children: [
              for (final id in engine.visibleChoices)
                SizedBox(
                  width: art + 44,
                  child: PictureTile(
                    word: ContentCatalog.wordsById[id]!,
                    artSize: art,
                    state: tileStateFor(id),
                    onTap: () => engine.choose(id),
                    onListen: _wordLevel ? null : () => audio.playWord(ContentCatalog.wordsById[id]!),
                    forceCaption: false,
                  ),
                ),
            ]),
          ),
        ]),
      ]);
    });
  }
}
