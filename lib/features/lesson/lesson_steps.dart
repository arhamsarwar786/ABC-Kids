import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/art/art_kit.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/components/celebration.dart';
import '../../core/design/components/feedback.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../games/game_framework.dart';
import '../../core/design/app_icons.dart';

/// "Meet the Sound": lowercase first, uppercase for comparison, one picture.
/// The sound plays only from a reviewed phoneme recording. Without one, the
/// screen asks a grown-up to say the sound together; it never substitutes the
/// letter-name recording.
class SoundIntroStep extends StatefulWidget {
  final LetterContent letter;
  final VoidCallback onNext;
  final VoidCallback onExit;
  const SoundIntroStep({super.key, required this.letter, required this.onNext, required this.onExit});

  @override
  State<SoundIntroStep> createState() => _SoundIntroStepState();
}

class _SoundIntroStepState extends State<SoundIntroStep> {
  late final AudioCoordinator audio;
  late final bool phoneme;
  late final WordExample word;
  String? _message;

  @override
  void initState() {
    super.initState();
    audio = context.read<AudioCoordinator>();
    phoneme = availabilityOf(context).phonemeAvailable(widget.letter.id);
    word = ContentCatalog.pictureWordsFor(widget.letter.id).first;
  }

  Future<void> _hearSound() async {
    final r = await audio.playAsset(AudioManifest.byId(widget.letter.phonemeAudioId));
    if (mounted && r == PlayResult.failed) setState(() => _message = 'The sound didn’t play. Check the volume and try again.');
  }

  Future<void> _hearWord() async {
    final r = await audio.playWord(word);
    if (!mounted) return;
    setState(() => _message = r == PlayResult.unavailable
        ? 'Word audio is off. A grown-up can turn on the device voice in settings.'
        : r == PlayResult.failed
            ? 'The word didn’t play. Try again.'
            : null);
  }

  @override
  void dispose() {
    audio.stopNarration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.letter;
    return ChildScaffold(
      title: 'Meet the sound',
      scene: SceneTheme.sky,
      leading: [BackChildButton(onPressed: widget.onExit)],
      trailing: [if (phoneme) AudioReplayButton(onPressed: _hearSound, label: 'Hear the sound')],
      bottom: PrimaryButton(label: 'Let’s play', icon: AppIcons.forward, onPressed: widget.onNext, expand: true),
      scrollable: true,
      body: LayoutBuilder(builder: (context, c) {
        final big = math.min(200.0, c.maxWidth * 0.42);
        return Column(children: [
          // Same font size for both cases, so the real size relationship shows
          // (for s, S is simply the taller one). Lowercase comes first.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Semantics(label: 'small letter ${l.lower}', child: LetterCharacter(l.lower, size: big)),
              const SizedBox(width: 20),
              Semantics(
                  label: 'big letter ${l.upper}', child: Opacity(opacity: 0.85, child: LetterCharacter(l.upper, size: big, face: false))),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(width: 180, child: PictureTile(word: word, artSize: 110, forceCaption: true, onTap: _hearWord, onListen: _hearWord)),
          const SizedBox(height: 16),
          if (phoneme)
            PrimaryButton(label: 'Hear the sound', icon: AppIcons.listen, onPressed: _hearSound)
          else
            SoftCard(
              color: AppTokens.yellow.withValues(alpha: 0.5),
              child: Row(children: [
                const Icon(AppIcons.sayTogether, color: AppTokens.yellowDeep, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Grown-up: say the sound ${l.soundPolicy.taughtSound} together, like at the '
                    '${ContentCatalog.soundNotAtStart(word) ? 'end' : 'start'} of “${word.text}”.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ]),
            ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(_message!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ]);
      }),
    );
  }
}

/// "Listen & Discover": 2–3 pictures that begin with the sound; tap to hear.
class PictureDiscoveryStep extends StatelessWidget {
  final LetterContent letter;
  final VoidCallback onNext;
  final VoidCallback onExit;
  const PictureDiscoveryStep({super.key, required this.letter, required this.onNext, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioCoordinator>();
    final words = ContentCatalog.pictureWordsFor(letter.id).take(3).toList();
    final atEnd = words.isNotEmpty && ContentCatalog.soundNotAtStart(words.first);
    final canHear = words.every(audio.wordAudioAvailable);
    return ChildScaffold(
      title: 'Listen and discover',
      scene: SceneTheme.meadow,
      leading: [BackChildButton(onPressed: onExit)],
      bottom: PrimaryButton(label: 'Play with ${letter.lower}', icon: AppIcons.forward, onPressed: onNext, expand: true),
      scrollable: true,
      body: Column(children: [
        LetterCharacter(letter.lower, size: 130),
        const SizedBox(height: 8),
        Text(canHear ? 'Tap each picture to hear it' : 'Look at the pictures together',
            style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        if (atEnd)
          Text('${letter.lower} is at the end of these words', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 14),
        // All pictures in one row where possible, so none hides below the button.
        LayoutBuilder(builder: (context, c) {
          final tile = math.min(150.0, (c.maxWidth - 14 * (words.length - 1)) / words.length);
          return Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
            for (final w in words)
              SizedBox(
                width: math.max(tile, 88),
                child: PictureTile(
                  word: w,
                  artSize: math.max(tile, 88) * 0.62,
                  forceCaption: true,
                  onTap: canHear ? () => audio.playWord(w) : null,
                  onListen: canHear ? () => audio.playWord(w) : null,
                ),
              ),
          ]);
        }),
        if (!canHear) ...[
          const SizedBox(height: 14),
          Text('Word audio is off. A grown-up can read the words aloud, or turn on the device voice in settings.',
              style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}

/// Lesson complete with an idempotent sticker. Wording never claims mastery.
class LessonCompleteStep extends StatelessWidget {
  final LetterContent letter;
  final bool newSticker;
  final Widget stickerArt;
  final String? nextLetter;
  final VoidCallback? onNextSound;
  final VoidCallback onFinish;
  const LessonCompleteStep({
    super.key,
    required this.letter,
    required this.newSticker,
    required this.stickerArt,
    required this.nextLetter,
    required this.onNextSound,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Stack(children: [
      ChildScaffold(
        scene: SceneTheme.sunset,
        scrollable: true,
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          if (onNextSound != null && nextLetter != null)
            PrimaryButton(label: 'Next sound: $nextLetter', icon: AppIcons.forward, onPressed: onNextSound, expand: true),
          const SizedBox(height: 10),
          SecondaryButton(label: 'Finish for now', icon: AppIcons.home, onPressed: onFinish, expand: true),
        ]),
        body: Column(children: [
          const SizedBox(height: 8),
          Bob(child: LetterCharacter(letter.lower, size: 96, cheer: true)),
          Semantics(header: true, child: Text('You did it!', style: t.displaySmall)),
          const SizedBox(height: 4),
          Text('You listened and played with ${letter.lower}.', style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Sunburst(
            size: 250,
            child: PopIn(
                delay: const Duration(milliseconds: 250), child: StickerBadge(art: stickerArt, label: 'Sound ${letter.lower}', size: 140)),
          ),
          RewardPill(text: newSticker ? 'New sticker!' : 'You already have this sticker'),
        ]),
      ),
      const Positioned.fill(child: ConfettiBurst()),
    ]);
  }
}

/// Golden pill announcing a reward.
class RewardPill extends StatelessWidget {
  final String text;
  const RewardPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFC94A)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: AppTokens.glow(AppTokens.yellow),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(AppIcons.star, color: Color(0xFF8A5A00), size: 22),
          const SizedBox(width: 6),
          Flexible(
              child: Text(text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF5C3B00)), textAlign: TextAlign.center)),
        ]),
      );
}

/// "See you soon": calm finish with Home and Play again.
class GoodbyeScreen extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onPlayAgain;
  const GoodbyeScreen({super.key, required this.onHome, required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ChildScaffold(
      scene: SceneTheme.night,
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        PrimaryButton(label: 'Home', icon: AppIcons.home, onPressed: onHome, expand: true),
        const SizedBox(height: 10),
        SecondaryButton(label: 'Play again', icon: AppIcons.replay, onPressed: onPlayAgain, expand: true),
      ]),
      body: Center(
        child: SingleChildScrollView(
          child: Column(children: [
            Semantics(header: true, child: Text('Great playing!', style: t.displaySmall, textAlign: TextAlign.center)),
            const SizedBox(height: 8),
            Text('See you next time!', style: t.titleLarge),
            const SizedBox(height: 20),
            const Bob(
              amplitude: 4,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Art(MascotArt(sleepy: true), size: 130),
                Art(MascotArt(bear: true, sleepy: true), size: 130),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
