import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/art/art_kit.dart';
import '../../core/design/art/characters.dart';
import '../../core/design/components/buttons.dart';
import '../../core/design/components/motion.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/tokens.dart';
import '../../state/settings_store.dart';
import '../parent/parent_gate.dart';
import '../parent/learners_screen.dart';
import '../../core/design/app_icons.dart';

/// First launch. A local guest learner already exists, so Play starts at once;
/// parent setup is optional and behind the gate.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _play(BuildContext context) async {
    await context.read<SettingsStore>().update((s) => s.copyWith(firstRunComplete: true));
  }

  @override
  Widget build(BuildContext context) {
    return ChildScaffold(
      scene: SceneTheme.meadow,
      trailing: [
        ChildIconButton(
          icon: AppIcons.lock,
          label: 'Grown-ups: set up',
          onPressed: () async {
            if (await ParentGate.show(context) && context.mounted) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LearnersScreen()));
            }
          },
        ),
      ],
      bottom: PrimaryButton(label: 'Play', icon: AppIcons.play, onPressed: () => _play(context), expand: true),
      body: Center(
        child: SingleChildScrollView(
          child: Column(children: [
            Entrance(
              child: Semantics(
                header: true,
                label: 'ABC Kids',
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(children: [
                    LetterCharacter('A', size: 84, face: false),
                    LetterCharacter('B', size: 84, face: false),
                    LetterCharacter('C', size: 84, face: false),
                  ]),
                ),
              ),
            ),
            Text('Kids', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppTokens.purple)),
            const SizedBox(height: 24),
            const Entrance(
              index: 2,
              child: Bob(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    LetterCharacter('s', size: 90),
                    LetterCharacter('a', size: 120, cheer: true),
                    LetterCharacter('t', size: 90),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Entrance(
                index: 3,
                child: Text('Sounds, letters and play', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center)),
            const SizedBox(height: 8),
            const Entrance(index: 4, child: Art(MascotArt(), size: 100)),
          ]),
        ),
      ),
    );
  }
}
