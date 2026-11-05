import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/art/art_kit.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/art/word_art.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/celebration.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/components/chunky.dart';
import '../../core/design/components/feedback.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../data/content/stickers.dart';
import '../../data/models/content.dart';
import '../../data/models/learner.dart';
import '../../data/models/progress.dart';
import '../../domain/availability.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';
import '../lesson/lesson_steps.dart';
import '../stickers/sticker_art.dart';
import 'game_framework.dart';
import 'game_launcher.dart';
import '../../core/design/app_icons.dart';

Widget gameArt(GameType t, {double size = 64}) => switch (t) {
      GameType.pop => Art(const BubbleArt(Color(0xFFF58FC0)), size: size),
      GameType.feedMonster => Art(const MonsterArt(happy: true), size: size),
      GameType.safari => Art(WordArt.forWord('w_monkey')!, size: size),
      GameType.parking =>
        SizedBox(width: size, height: size, child: FittedBox(child: CarArt(label: 'a', color: const Color(0xFF9C7BEA), width: size))),
      GameType.buildLetter => SizedBox(width: size, height: size, child: FittedBox(child: LetterCharacter('m', size: size, face: false))),
      GameType.magicTrail => Art(const StarArt(color: Color(0xFF9C7BEA)), size: size),
      GameType.countMatch => Art(WordArt.countingObject('apple'), size: size),
      GameType.shapeMatch || GameType.shapeName => Art(const ShapeArt(ShapeKind.triangle, Color(0xFF6FB1F0)), size: size),
    };

/// Games tab: the six letter and sound games.
class GamesCatalogue extends StatelessWidget {
  const GamesCatalogue({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LearnerStore>();
    // Re-check when the device voice becomes available or is switched off.
    context.watch<AudioCoordinator>();
    final colors = [AppTokens.lavender, AppTokens.mint, AppTokens.yellow, AppTokens.blue, AppTokens.coral, AppTokens.purpleSoft];
    final avail = availabilityOf(context);
    // Games that cannot run honestly (e.g. no word audio) are simply not shown;
    // grown-ups see why in Content status.
    final games = [
      for (final def in ContentCatalog.activities.values)
        if (avail.forGame(def.type, 'm', introduced: const {}).available) def,
    ];
    return ChildScaffold(
      title: 'Games',
      scene: SceneTheme.sky,
      body: GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          // Taller cards when text is enlarged, so titles never overflow.
          childAspectRatio: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 0.62 : 0.92,
        ),
        itemCount: games.length,
        itemBuilder: (context, i) {
          final def = games[i];
          final a = avail.forGame(def.type, 'm', introduced: const {});
          final title = def.type == GameType.pop && a.popMode == PopMode.visual ? 'Pop the Letter' : def.title;
          return Entrance(
            index: i,
            child: Semantics(
              button: true,
              label: title,
              excludeSemantics: true,
              child: Chunky(
                color: colors[i % colors.length],
                gradient: AppTokens.fill(colors[i % colors.length]),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                onTap: () => startFreePlay(context, def.type),
                child: _GameCardBody(def: def, title: title),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GameCardBody extends StatelessWidget {
  final ActivityDefinition def;
  final String title;
  const _GameCardBody({required this.def, required this.title});

  static String _tag(GameType t) => switch (t) {
        GameType.pop || GameType.parking => 'Letters',
        GameType.feedMonster => 'Sounds',
        GameType.safari => 'Words',
        GameType.buildLetter => 'Build',
        GameType.magicTrail => 'Tracing',
        _ => 'Play',
      };

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(10)),
              child: Text(_tag(def.type),
                  style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTokens.purple, fontSize: 13),
                  textScaler: TextScaler.noScaling),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: FittedBox(child: gameArt(def.type, size: 90))),
          const SizedBox(height: 6),
          Text(title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
        ]),
      );
}

/// Starts a game straight away with familiar sounds and a level chosen from
/// the learner's preferences, so toddlers have nothing to set up.
void startFreePlay(BuildContext context, GameType type) {
  final prefs = context.read<LearnerStore>().preferences;
  final progress = context.read<ProgressStore>();
  final letters = recommendedLetters(context, type);
  final growing = prefs.readiness == Readiness.growing;
  final level = switch (type) {
    GameType.safari => growing ? 1 : 0,
    GameType.parking => growing && prefs.letterCase == LetterCaseMode.lowercaseThenUppercase ? 1 : 0,
    _ => 0,
  };
  openFreePlay(
    context,
    GameSpec(
      type: type,
      letters: letters,
      distractors: progress.introducedLetters().where((l) => !letters.contains(l)).toList(),
      level: level,
      context: ActivityContext.freePlay,
      showIntroDemo: !progress.recentGames.contains(type),
    ),
  );
}

/// Recommended familiar sounds: introduced letters first, else the start of
/// the learner's sequence.
List<String> recommendedLetters(BuildContext context, GameType t) {
  final prefs = context.read<LearnerStore>().preferences;
  final introduced = context.read<ProgressStore>().introducedLetters();
  bool fits(String l) => switch (t) {
        GameType.buildLetter || GameType.magicTrail => ContentCatalog.letter(l)?.strokes != null,
        GameType.feedMonster || GameType.safari => ContentCatalog.wordsFor(l).isNotEmpty,
        _ => ContentCatalog.letter(l) != null,
      };
  final familiar = prefs.soundSequence.where((l) => introduced.contains(l) && fits(l)).toList();
  final base = familiar.isNotEmpty ? familiar : prefs.soundSequence.where(fits).take(3).toList();
  return base.length > 3 ? base.sublist(base.length - 3) : base;
}

/// Runs a free-play game, then shows completion with replay options.
void openFreePlay(BuildContext context, GameSpec spec) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => FreePlayRunner(spec: spec)));
}

class FreePlayRunner extends StatefulWidget {
  final GameSpec spec;
  const FreePlayRunner({super.key, required this.spec});
  @override
  State<FreePlayRunner> createState() => _FreePlayRunnerState();
}

class _FreePlayRunnerState extends State<FreePlayRunner> {
  int _run = 0;
  bool? _newSticker;
  bool _done = false;

  Future<void> _finished(GameResult r) async {
    if (r.exited) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (r.endedEarly) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (ctx) => GoodbyeScreen(
          onHome: () => Navigator.of(ctx).popUntil((route) => route.isFirst),
          onPlayAgain: () => Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder: (_) => FreePlayRunner(spec: widget.spec))),
        ),
      ));
      return;
    }
    final progress = context.read<ProgressStore>();
    final def = StickerCatalog.forGame(widget.spec.type);
    final isNew = await progress.award(StickerCatalog.gameAwardId(widget.spec.type), def.id, 'Finished ${def.name}');
    if (mounted) {
      setState(() {
        _newSticker = isNew;
        _done = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return buildGame(
          GameSpec(
            type: widget.spec.type,
            letters: widget.spec.letters,
            distractors: widget.spec.distractors,
            level: widget.spec.level,
            context: widget.spec.context,
            showIntroDemo: widget.spec.showIntroDemo && _run == 0,
          ),
          _finished,
          key: ValueKey(_run));
    }
    final def = StickerCatalog.forGame(widget.spec.type);
    final t = Theme.of(context).textTheme;
    return Stack(children: [
      ChildScaffold(
        scene: SceneTheme.sunset,
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          PrimaryButton(
              label: 'Play again',
              icon: AppIcons.replay,
              expand: true,
              onPressed: () => setState(() {
                    _run++;
                    _done = false;
                  })),
          const SizedBox(height: 10),
          SecondaryButton(label: 'More games', icon: AppIcons.games, expand: true, onPressed: () => Navigator.of(context).pop()),
          const SizedBox(height: 10),
          SecondaryButton(
              label: 'Home', icon: AppIcons.home, expand: true, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ]),
        scrollable: true,
        body: Column(children: [
          const SizedBox(height: 16),
          Semantics(header: true, child: Text('Great playing!', style: t.displaySmall)),
          Sunburst(
            size: 260,
            child: PopIn(
                delay: const Duration(milliseconds: 200), child: StickerBadge(art: StickerArtView(def.id), label: def.name, size: 140)),
          ),
          RewardPill(text: _newSticker == true ? 'New sticker!' : 'You played ${def.name} again.'),
        ]),
      ),
      if (_newSticker == true) const Positioned.fill(child: ConfettiBurst()),
    ]);
  }
}
