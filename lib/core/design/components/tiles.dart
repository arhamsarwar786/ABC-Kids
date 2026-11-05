import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/content.dart';
import '../../../state/progress_store.dart';
import '../../../state/settings_store.dart';
import '../art/art_kit.dart';
import '../art/characters.dart';
import '../art/word_art.dart';
import '../tokens.dart';
import 'chunky.dart';
import '../app_icons.dart';

enum TileState { normal, selected, correct, gentleWrong, hinted, dimmed }

BoxDecoration tileDecoration(Color color, TileState state) {
  final border = switch (state) {
    TileState.selected || TileState.hinted => Border.all(color: AppTokens.purple, width: 4),
    TileState.correct => Border.all(color: AppTokens.success, width: 4),
    TileState.gentleWrong => Border.all(color: AppTokens.gentle, width: 3),
    _ => Border.all(color: Colors.white, width: 3),
  };
  final lip = switch (state) {
    TileState.selected || TileState.hinted => AppTokens.purple,
    TileState.correct => AppTokens.success,
    TileState.gentleWrong => AppTokens.gentle,
    _ => color == AppTokens.surface ? AppTokens.outline : AppTokens.lipFor(color),
  };
  final dimmed = state == TileState.dimmed;
  return BoxDecoration(
    gradient: AppTokens.fill(dimmed ? color.withValues(alpha: 0.4) : color),
    borderRadius: BorderRadius.circular(AppTokens.radius),
    border: border,
    boxShadow: [
      BoxShadow(color: dimmed ? lip.withValues(alpha: 0.3) : lip, offset: const Offset(0, 5), blurRadius: 0),
      if (!dimmed) ...AppTokens.glow(color == AppTokens.surface ? AppTokens.lavender : color),
    ],
  );
}

/// Big tappable letter tile.
class LetterTile extends StatelessWidget {
  final String letter;
  final Color color;
  final VoidCallback? onTap;
  final TileState state;
  final String? semanticsLabel;
  final double fontSize;
  const LetterTile({
    super.key,
    required this.letter,
    required this.color,
    this.onTap,
    this.state = TileState.normal,
    this.semanticsLabel,
    this.fontSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticsLabel ?? 'letter $letter',
      selected: state == TileState.selected,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: AppTokens.childTarget, minHeight: AppTokens.childTarget),
        decoration: tileDecoration(color, state),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            onTap: onTap,
            child: Center(
              child: Text(letter,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                      fontFamily: AppTokens.letterFont,
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                      color: AppTokens.navy,
                      height: 1.1)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Picture card for a word, with an optional caption and replay button.
class PictureTile extends StatelessWidget {
  final WordExample word;
  final VoidCallback? onTap;
  final VoidCallback? onListen;
  final TileState state;
  final double artSize;
  final Color color;
  final bool forceCaption;
  const PictureTile({
    super.key,
    required this.word,
    this.onTap,
    this.onListen,
    this.state = TileState.normal,
    this.artSize = 88,
    this.color = AppTokens.surface,
    this.forceCaption = false,
  });

  @override
  Widget build(BuildContext context) {
    final captions = forceCaption || (context.watch<SettingsStore?>()?.settings.showCaptions ?? true);
    return Semantics(
      button: onTap != null,
      label: 'picture: ${word.text}',
      selected: state == TileState.selected,
      child: Container(
        decoration: tileDecoration(color, state),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                WordPicture(word, size: artSize),
                if (captions) ...[
                  const SizedBox(height: 4),
                  Text(word.text, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (onListen != null) ...[
                  const SizedBox(height: 6),
                  Semantics(
                    button: true,
                    label: 'Hear ${word.text}',
                    excludeSemantics: true,
                    child: Material(
                      color: AppTokens.purpleSoft,
                      shape: const StadiumBorder(side: BorderSide(color: AppTokens.lavender, width: 1.5)),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: onListen,
                        child: const SizedBox(
                          width: 64,
                          height: 44,
                          child: Icon(AppIcons.listen, color: AppTokens.purple, size: 26),
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom vector picture for a word (emoji only as a last-resort fallback).
class WordPicture extends StatelessWidget {
  final WordExample word;
  final double size;
  const WordPicture(this.word, {super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    final painter = WordArt.forWord(word.id);
    if (painter != null) return Art(painter, size: size);
    return SizedBox.square(
      dimension: size,
      child: Center(child: Text(word.picture.emoji, style: TextStyle(fontSize: size * 0.7), textScaler: TextScaler.noScaling)),
    );
  }
}

/// Compact pastel card used on Home and hubs.
class HubCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget art;
  final Color color;
  final VoidCallback onTap;
  final bool compact;
  const HubCard({
    super.key,
    required this.title,
    required this.art,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
      excludeSemantics: true,
      child: Chunky(
        color: color,
        gradient: AppTokens.fill(color),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 120 : 96),
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
          child: compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: text.titleLarge),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                        child: SizedBox(height: 44, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: art))),
                    const _Chevron(),
                  ]),
                ])
              : Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(title, style: text.titleLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: text.bodyMedium?.copyWith(color: AppTokens.navyMuted)),
                      ],
                    ]),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110, maxHeight: 72),
                    child: FittedBox(fit: BoxFit.scaleDown, child: art),
                  ),
                  const SizedBox(width: 6),
                  const _Chevron(),
                ]),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppTokens.softShadow),
        child: const Icon(AppIcons.chevronRight, color: AppTokens.purple, size: 20),
      );
}

/// One node on the Sound Path.
class PathNode extends StatelessWidget {
  final String letter;
  final PathStatus status;
  final bool current;
  final bool enabled;
  final VoidCallback? onTap;
  final double size;
  const PathNode({
    super.key,
    required this.letter,
    required this.status,
    this.current = false,
    this.enabled = true,
    this.onTap,
    this.size = 76,
  });

  @override
  Widget build(BuildContext context) {
    final (c, edge) = LetterColors.forLetter(letter);
    final statusText = switch (status) {
      PathStatus.newSound => 'new',
      PathStatus.explored => 'explored',
      PathStatus.practising => 'practising',
    };
    final bg = status == PathStatus.newSound ? AppTokens.surface : c.withValues(alpha: 0.25);
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: 'sound $letter, $statusText${current ? ', next to learn' : ''}${enabled ? '' : ', coming later'}',
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Chunky(
          circle: true,
          color: bg,
          gradient: status == PathStatus.newSound ? null : AppTokens.fill(c.withValues(alpha: 0.35)),
          lipColor: current ? AppTokens.purple : edge.withValues(alpha: 0.55),
          border: Border.all(color: current ? AppTokens.purple : Colors.white, width: current ? 4 : 3),
          onTap: enabled ? onTap : null,
          child: SizedBox.square(
            dimension: size,
            child: Stack(alignment: Alignment.center, children: [
              Text(letter,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                      fontFamily: AppTokens.letterFont, fontWeight: FontWeight.w700, fontSize: size * 0.5, color: edge, height: 1.1)),
              if (status != PathStatus.newSound)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(status == PathStatus.practising ? AppIcons.star : AppIcons.seen,
                        size: 16, color: status == PathStatus.practising ? AppTokens.yellowDeep : AppTokens.blueDeep),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
