import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/audio_manifest.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../../domain/lesson_planner.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';
import '../lesson/lesson_screen.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/components/motion.dart';

/// All 26 letters as big “Aa” tiles. Tapping one opens a letter book that
/// can be flipped through from A to Z.
class AlphabetScreen extends StatelessWidget {
  /// Shown as a bottom tab (no back button) rather than a pushed page.
  final bool asTab;
  const AlphabetScreen({super.key, this.asTab = false});

  @override
  Widget build(BuildContext context) {
    return ChildScaffold(
      title: 'ABC',
      scene: SceneTheme.sky,
      leading: asTab ? const [] : const [BackChildButton()],
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 110, mainAxisSpacing: 12, crossAxisSpacing: 12),
        itemCount: ContentCatalog.letters.length,
        itemBuilder: (context, i) {
          final l = ContentCatalog.letters[i];
          return Entrance(
              index: i ~/ 4,
              child: LetterTile(
                letter: '${l.upper}${l.lower}',
                fontSize: 40,
                semanticsLabel: 'letter ${l.upper}',
                color: AppTokens.pastels[i % AppTokens.pastels.length],
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LetterBookScreen(startIndex: i))),
              ));
        },
      ),
    );
  }
}

/// One page per letter: big letter, a picture, and simple listen buttons.
/// Swipe or use the big arrows to go to the next or previous letter.
class LetterBookScreen extends StatefulWidget {
  final int startIndex;
  const LetterBookScreen({super.key, this.startIndex = 0});
  @override
  State<LetterBookScreen> createState() => _LetterBookScreenState();
}

class _LetterBookScreenState extends State<LetterBookScreen> {
  late final PageController _pages = PageController(initialPage: widget.startIndex);
  late final AudioCoordinator _audio;
  late final ProgressStore _progress;
  late int _index = widget.startIndex;

  List<LetterContent> get _letters => ContentCatalog.letters;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AudioCoordinator>();
    _progress = context.read<ProgressStore>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seen(_index));
  }

  @override
  void dispose() {
    _audio.stopNarration();
    _pages.dispose();
    super.dispose();
  }

  void _seen(int i) {
    if (mounted) _progress.recordExposure(Targets.letter(_letters[i].id), 'explore.letters');
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _letters.length) return;
    _pages.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final l = _letters[_index];
    return ChildScaffold(
      title: '${l.upper} ${l.lower}',
      scene: SceneTheme.sky,
      leading: const [BackChildButton()],
      bottom: Row(children: [
        ChildIconButton(icon: AppIcons.back, label: 'Previous letter', size: 72, onPressed: _index > 0 ? () => _go(-1) : null),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${_index + 1} / ${_letters.length}', style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        ChildIconButton(
          icon: AppIcons.forward,
          label: 'Next letter',
          size: 72,
          onPressed: _index < _letters.length - 1 ? () => _go(1) : null,
        ),
      ]),
      body: PageView.builder(
        controller: _pages,
        itemCount: _letters.length,
        onPageChanged: (i) {
          _audio.stopNarration();
          setState(() => _index = i);
          _seen(i);
        },
        itemBuilder: (context, i) => _LetterPage(letter: _letters[i], audio: _audio),
      ),
    );
  }
}

class _LetterPage extends StatelessWidget {
  final LetterContent letter;
  final AudioCoordinator audio;
  const _LetterPage({required this.letter, required this.audio});

  @override
  Widget build(BuildContext context) {
    final word = ContentCatalog.alphabetWordFor(letter.id);
    final nameRecording = AudioManifest.byId(letter.letterNameAudioId);
    final hasName = audio.assetPlayable(nameRecording);
    final t = Theme.of(context).textTheme;
    final prefs = context.watch<LearnerStore>().preferences;
    final canPlay = LessonPlanner.isOpen(prefs, context.watch<ProgressStore>().data.completedLessons, letter.id);
    return LayoutBuilder(builder: (context, c) {
      // Sized so the letters, picture and both buttons fit without
      // scrolling on 16:9 phones; very short screens still scroll.
      final big = math.min(150.0, c.maxHeight * 0.22);
      return SingleChildScrollView(
        child: Column(children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              LetterCharacter(letter.upper, size: big, face: false),
              const SizedBox(width: 16),
              LetterCharacter(letter.lower, size: big),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 190,
            child: PictureTile(
              word: word,
              artSize: math.min(120, c.maxHeight * 0.17),
              forceCaption: true,
              onTap: () => audio.playWord(word),
              onListen: audio.wordAudioAvailable(word) ? () => audio.playWord(word) : null,
            ),
          ),
          if (ContentCatalog.soundNotAtStart(word)) ...[
            const SizedBox(height: 8),
            Text('${letter.lower} is at the end of “${word.text}”', style: t.bodyLarge, textAlign: TextAlign.center),
          ],
          if (hasName) ...[
            const SizedBox(height: 14),
            SecondaryButton(
              label: 'Hear the letter name',
              icon: AppIcons.sayTogether,
              onPressed: () => audio.playAsset(nameRecording),
            ),
          ],
          if (canPlay) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Play with ${letter.lower}',
              icon: AppIcons.play,
              onPressed: () => openLesson(context, planLesson(context, letter.id)),
            ),
          ],
        ]),
      );
    });
  }
}
