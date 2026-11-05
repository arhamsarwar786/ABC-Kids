import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/settings_tiles.dart';
import '../../data/models/learner.dart';
import '../../state/learner_store.dart';

/// Per-learner learning preferences. Each option changes app behaviour:
/// mode → which path sounds are open; readiness → choices and rounds;
/// reminder → break reminder; letter case → Parking case level in lessons;
/// tracing → whether Magic Trail joins lessons; sequence → the sound path.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  static final _sequences = <(String, List<String>)>[
    ('Phonics order (default)', LearningPreferences.defaultSoundSequence),
    ('m first', LearningPreferences.completeSequence(const ['m'])),
    ('A to Z', 'abcdefghijklmnopqrstuvwxyz'.split('')),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearnerStore>();
    final p = store.preferences;
    void set(LearningPreferences Function(LearningPreferences) f) => store.updatePreferences(f);
    final seqLabel =
        _sequences.firstWhere((s) => s.$2.join() == p.soundSequence.join(), orElse: () => (p.soundSequence.join(' '), p.soundSequence)).$1;
    return ParentScaffold(
      title: 'Learning preferences',
      children: [
        Text('For ${store.active.nickname}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SettingsChoiceTile<PlayMode>(
          title: 'Sound path',
          subtitle: 'Guided opens sounds in order. Free play lets every sound be chosen.',
          value: p.mode,
          options: const [(PlayMode.guided, 'Guided'), (PlayMode.freePlay, 'Free play')],
          onChanged: (v) => set((x) => x.copyWith(mode: v)),
        ),
        SettingsChoiceTile<Readiness>(
          title: 'Readiness',
          subtitle: 'Starting: 2 choices for longer and 2 lesson games. Growing: up to 3 choices and 3 lesson games.',
          value: p.readiness,
          options: const [(Readiness.starting, 'Starting'), (Readiness.growing, 'Growing')],
          onChanged: (v) => set((x) => x.copyWith(readiness: v)),
        ),
        SettingsChoiceTile<int>(
          title: 'Break reminder',
          subtitle: 'A gentle reminder at a natural pause. Play is never stopped.',
          value: p.reminderMinutes,
          options: [for (final m in LearningPreferences.reminderOptions) (m, m == 0 ? 'Off' : '$m min')],
          onChanged: (v) => set((x) => x.copyWith(reminderMinutes: v)),
        ),
        SettingsChoiceTile<LetterCaseMode>(
          title: 'Letter case',
          subtitle: 'Lessons teach small letters first. Adding big letters unlocks the “big and small” parking level in lessons.',
          value: p.letterCase,
          options: const [(LetterCaseMode.lowercaseOnly, 'Small letters'), (LetterCaseMode.lowercaseThenUppercase, 'Small, then big')],
          onChanged: (v) => set((x) => x.copyWith(letterCase: v)),
        ),
        SettingsSwitchTile(
          title: 'Include tracing in lessons',
          subtitle: 'Magic Trail is optional and can always be skipped.',
          value: p.tracingEnabled,
          onChanged: (v) => set((x) => x.copyWith(tracingEnabled: v)),
        ),
        SettingsChoiceTile<String>(
          title: 'Sound order',
          subtitle: 'All 26 letters, one lesson each: ${p.soundSequence.join(' ')}. Finished lessons stay finished.',
          value: seqLabel,
          options: [for (final s in _sequences) (s.$1, s.$1)],
          onChanged: (v) => set((x) => x.copyWith(soundSequence: _sequences.firstWhere((s) => s.$1 == v).$2)),
        ),
        SettingsChoiceTile<String>(
          title: 'Voice / accent',
          subtitle: 'Only one recording set is bundled, and its accent has not been verified. More packs will appear here when they exist.',
          value: p.accentPackId,
          options: const [(LearningPreferences.defaultAccentPackId, 'Bundled recordings (unverified)')],
          onChanged: (v) => set((x) => x.copyWith(accentPackId: v)),
        ),
      ],
    );
  }
}
