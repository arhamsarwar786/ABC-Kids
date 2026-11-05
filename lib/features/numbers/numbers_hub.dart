import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/art/art_kit.dart';
import '../../core/design/art/word_art.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/content/stickers.dart';
import '../../data/models/content.dart';
import '../../state/progress_store.dart';
import '../games/game_framework.dart';
import '../games/games_catalogue.dart';

/// Numbers hub: explorer (1–10 with audio) and Count and Match.
class NumbersHub extends StatelessWidget {
  const NumbersHub({super.key});

  @override
  Widget build(BuildContext context) {
    return ChildScaffold(
      title: 'Numbers',
      leading: const [BackChildButton()],
      scrollable: true,
      body: Column(children: [
        HubCard(
          title: 'Explore numbers',
          subtitle: 'Look and listen, 1 to 10',
          color: AppTokens.yellow,
          art: Text('123',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTokens.blueDeep), textScaler: TextScaler.noScaling),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NumberExplorer())),
        ),
        const SizedBox(height: 12),
        HubCard(
          title: 'Count and Match',
          subtitle: 'Count, then find the number',
          color: AppTokens.mint,
          art: Art(WordArt.countingObject('apple'), size: 56),
          onTap: () => openFreePlay(context, const GameSpec(type: GameType.countMatch, letters: ['1'])),
        ),
      ]),
    );
  }
}

class NumberExplorer extends StatefulWidget {
  const NumberExplorer({super.key});
  @override
  State<NumberExplorer> createState() => _NumberExplorerState();
}

class _NumberExplorerState extends State<NumberExplorer> {
  int _n = 1;
  final Set<int> _seen = {};
  late final AudioCoordinator audio;
  late final ProgressStore progress;

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioCoordinator>();
    progress = context.read<ProgressStore>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(1));
  }

  @override
  void dispose() {
    audio.stopNarration();
    super.dispose();
  }

  void _show(int n) {
    setState(() => _n = n);
    if (_seen.add(n)) progress.recordExposure(Targets.number(n), 'numbers.explorer');
    audio.playAsset(AudioManifest.byId(AudioManifest.numberNameId(n)));
    if (_seen.length == 10) {
      progress.award(StickerCatalog.numbersExplorerAwardId, StickerCatalog.numbersExplorer.id, 'Explored numbers 1 to 10');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = audio.assetPlayable(AudioManifest.byId(AudioManifest.numberNameId(_n)));
    return ChildScaffold(
      title: 'Explore numbers',
      leading: const [BackChildButton()],
      trailing: [
        if (hasAudio)
          AudioReplayButton(onPressed: () => audio.playAsset(AudioManifest.byId(AudioManifest.numberNameId(_n))), label: 'Hear the number')
      ],
      body: LayoutBuilder(builder: (context, c) {
        final obj = math.min(48.0, c.maxWidth / 7);
        return Column(children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(children: [
                  Semantics(
                    label: 'number $_n',
                    child: Text('$_n',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                            fontFamily: AppTokens.letterFont,
                            fontWeight: FontWeight.w700,
                            fontSize: math.min(140, c.maxHeight * 0.3),
                            color: AppTokens.purple,
                            height: 1)),
                  ),
                  const SizedBox(height: 8),
                  ExcludeSemantics(
                    child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
                      for (var i = 0; i < _n; i++) Art(const StarArt(), size: obj),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (var i = 1; i <= 10; i++)
              SizedBox(
                width: 60,
                height: 60,
                child: LetterTile(
                  letter: '$i',
                  fontSize: 28,
                  color: i == _n ? AppTokens.lavender : AppTokens.surface,
                  state: i == _n ? TileState.selected : TileState.normal,
                  semanticsLabel: 'number $i',
                  onTap: () => _show(i),
                ),
              ),
          ]),
          const SizedBox(height: 8),
        ]);
      }),
    );
  }
}
