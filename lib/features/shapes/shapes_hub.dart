import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/art/art_kit.dart';
import '../../core/design/art/word_art.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/stickers.dart';
import '../../data/models/content.dart';
import '../../state/progress_store.dart';
import '../games/game_framework.dart';
import '../games/games_catalogue.dart';
import '../games/number_shape_games.dart';

/// Shapes hub: explorer, Shape Match (identical shapes) and Find the Shape
/// (named shapes). Progress is kept apart from letters and numbers.
class ShapesHub extends StatelessWidget {
  const ShapesHub({super.key});

  @override
  Widget build(BuildContext context) {
    return ChildScaffold(
      title: 'Shapes',
      leading: const [BackChildButton()],
      scrollable: true,
      body: Column(children: [
        HubCard(
          title: 'Explore shapes',
          subtitle: 'Circle, square, triangle, rectangle',
          color: AppTokens.blue,
          art: const Art(ShapeArt(ShapeKind.circle, Color(0xFFFF8A80)), size: 52),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShapeExplorer())),
        ),
        const SizedBox(height: 12),
        HubCard(
          title: 'Shape Match',
          subtitle: 'Find the same shape',
          color: AppTokens.mint,
          art: const Art(ShapeArt(ShapeKind.square, Color(0xFFFFC857)), size: 52),
          onTap: () => openFreePlay(context, const GameSpec(type: GameType.shapeMatch, letters: ['shape'])),
        ),
        const SizedBox(height: 12),
        HubCard(
          title: 'Find the Shape',
          subtitle: 'Listen for the shape name',
          color: AppTokens.lavender,
          art: const Art(ShapeArt(ShapeKind.triangle, Color(0xFF6FB1F0)), size: 52),
          onTap: () => openFreePlay(context, const GameSpec(type: GameType.shapeName, letters: ['shape'])),
        ),
      ]),
    );
  }
}

class ShapeExplorer extends StatefulWidget {
  const ShapeExplorer({super.key});
  @override
  State<ShapeExplorer> createState() => _ShapeExplorerState();
}

class _ShapeExplorerState extends State<ShapeExplorer> {
  ShapeKind _kind = ShapeKind.circle;
  int _color = 0;
  final Set<ShapeKind> _seen = {};
  late final AudioCoordinator audio;
  late final ProgressStore progress;

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioCoordinator>();
    progress = context.read<ProgressStore>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(ShapeKind.circle));
  }

  @override
  void dispose() {
    audio.stopNarration();
    super.dispose();
  }

  void _show(ShapeKind k) {
    setState(() {
      _kind = k;
      _color = (_color + 1) % shapeColors.length;
    });
    if (_seen.add(k)) progress.recordExposure(Targets.shape(k.name), 'shapes.explorer');
    audio.speak(shapeNames[k]!);
    if (_seen.length == ShapeKind.values.length) {
      progress.award(StickerCatalog.shapesExplorerAwardId, StickerCatalog.shapesExplorer.id, 'Explored four shapes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ChildScaffold(
      title: 'Explore shapes',
      leading: const [BackChildButton()],
      trailing: [if (audio.deviceVoiceUsable) AudioReplayButton(onPressed: () => audio.speak(shapeNames[_kind]!), label: 'Hear the name')],
      body: Column(children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Art(ShapeArt(_kind, shapeColors[_color]), size: 200, label: shapeNames[_kind]),
                const SizedBox(height: 12),
                Text(shapeNames[_kind]!, style: t.displaySmall),
              ]),
            ),
          ),
        ),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          for (final k in ShapeKind.values)
            Semantics(
              button: true,
              label: shapeNames[k],
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => _show(k),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: tileDecoration(AppTokens.surface, k == _kind ? TileState.selected : TileState.normal),
                  child: Art(ShapeArt(k, shapeColors[(k.index + 2) % shapeColors.length]), size: 64),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }
}
