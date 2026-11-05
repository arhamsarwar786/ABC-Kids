import 'package:flutter/material.dart';

import '../art/art_kit.dart';
import '../art/characters.dart';
import '../tokens.dart';
import 'buttons.dart';
import 'celebration.dart';
import '../app_icons.dart';

/// Short instruction with a replay button. Text is always visible so the
/// activity stays usable when audio is unavailable.
class InstructionBanner extends StatelessWidget {
  final String text;
  final VoidCallback? onReplay;

  /// Keeps the replay button in place (disabled) while it can't be used, so
  /// the layout doesn't jump during feedback.
  final bool showReplay;
  const InstructionBanner({super.key, required this.text, this.onReplay, bool? showReplay}) : showReplay = showReplay ?? onReplay != null;

  @override
  Widget build(BuildContext context) {
    // Very large text can wrap to many lines; keep the board visible.
    final maxH = MediaQuery.sizeOf(context).height * 0.22;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.outline, width: 1.5),
        boxShadow: AppTokens.softShadow,
      ),
      child: Row(children: [
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH < 64 ? 64 : maxH),
            child: SingleChildScrollView(
              child: Semantics(
                liveRegion: true,
                child:
                    Text(text, style: Theme.of(context).textTheme.titleLarge, textAlign: showReplay ? TextAlign.start : TextAlign.center),
              ),
            ),
          ),
        ),
        if (showReplay) ...[const SizedBox(width: 12), AudioReplayButton(onPressed: onReplay, label: 'Hear it again')],
        if (!showReplay) const SizedBox(height: 48),
      ]),
    );
  }
}

/// Dots showing round progress (no scores).
class RoundProgress extends StatelessWidget {
  final int index;
  final int count;
  const RoundProgress({super.key, required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'round ${index + 1} of $count',
      excludeSemantics: true,
      child: StarTrack(index: index, count: count),
    );
  }
}

/// Calm, non-shaming feedback line.
class FeedbackBanner extends StatelessWidget {
  final bool correct;
  final String? text;
  const FeedbackBanner({super.key, required this.correct, this.text});

  @override
  Widget build(BuildContext context) {
    final msg = text ?? (correct ? 'Lovely!' : 'Let’s try again together');
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppTokens.fill(correct ? AppTokens.mint : AppTokens.yellow),
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: AppTokens.glow(correct ? AppTokens.mint : AppTokens.yellow),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(correct ? AppIcons.heart : AppIcons.hearing, color: correct ? AppTokens.mintDeep : AppTokens.yellowDeep),
          const SizedBox(width: 8),
          Flexible(child: Text(msg, style: Theme.of(context).textTheme.titleMedium)),
        ]),
      ),
    );
  }
}

/// Sticker disc.
class StickerBadge extends StatelessWidget {
  final Widget art;
  final String label;
  final double size;
  final bool empty;
  const StickerBadge({super.key, required this.art, required this.label, this.size = 96, this.empty = false});

  const StickerBadge.empty({super.key, this.size = 96})
      : art = const Icon(AppIcons.starOutline, color: AppTokens.outline, size: 40),
        label = 'empty sticker space',
        empty = true;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.14),
          decoration: BoxDecoration(
            color: empty ? AppTokens.ivory : null,
            gradient: empty ? null : const RadialGradient(colors: [Colors.white, Color(0xFFFFF3CC)]),
            shape: BoxShape.circle,
            border: Border.all(color: empty ? AppTokens.outline : const Color(0xFFFFC94A), width: empty ? 3 : 5),
            boxShadow: empty ? null : AppTokens.glow(AppTokens.yellow),
          ),
          child: FittedBox(child: art),
        ),
        if (!empty) ...[
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center, maxLines: 2),
        ],
      ]),
    );
  }
}

/// Recoverable problem: always offers a way forward.
class ErrorPanel extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onAlternative;
  final String alternativeLabel;
  const ErrorPanel({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.onAlternative,
    this.alternativeLabel = 'Do something else',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Art(MascotArt(bear: true), size: 120),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (onRetry != null) PrimaryButton(label: retryLabel, icon: AppIcons.refresh, onPressed: onRetry),
          if (onAlternative != null) ...[
            const SizedBox(height: 12),
            SecondaryButton(label: alternativeLabel, onPressed: onAlternative),
          ],
        ]),
      ),
    );
  }
}

/// Full-screen pause card. Resume is always explicit.
class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onFinish;
  const PauseOverlay({super.key, required this.onResume, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppTokens.ivory.withValues(alpha: 0.97),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.gutter(context)),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Art(MascotArt(), size: 120),
                  const SizedBox(height: 12),
                  Semantics(header: true, child: Text('Paused', style: Theme.of(context).textTheme.headlineMedium)),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Keep playing', icon: AppIcons.play, onPressed: onResume),
                  const SizedBox(height: 12),
                  SecondaryButton(label: 'Finish for now', icon: AppIcons.home, onPressed: onFinish),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
