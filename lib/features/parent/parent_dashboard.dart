import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/settings_tiles.dart';
import '../../core/design/tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../../data/models/learner.dart';
import '../../data/models/progress.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';
import 'device_settings_screen.dart';
import 'info_screens.dart';
import 'learners_screen.dart';
import 'preferences_screen.dart';
import 'progress_details_screen.dart';
import '../../core/design/app_icons.dart';

/// Parent dashboard (behind the gate): active learner, recent activity,
/// sounds and skills, and all settings.
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});
  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final learner = context.watch<LearnerStore>().active;
    final progress = context.watch<ProgressStore>();
    final t = Theme.of(context).textTheme;
    final seq = learner.preferences.soundSequence;
    final explored = seq.where((l) => progress.pathStatus(l) != PathStatus.newSound).toList();
    final practising = seq.where((l) => progress.pathStatus(l) == PathStatus.practising).toList();
    final recognised = [
      for (final l in seq)
        if (progress.label(SkillDomain.soundLetter, Targets.letter(l)) == ProgressLabel.recognisedIndependently ||
            progress.label(SkillDomain.beginningSound, Targets.letter(l)) == ProgressLabel.recognisedIndependently)
          l,
    ];
    final recent = progress.recentAttempts(8);

    return ParentScaffold(
      title: 'Parent area',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(Avatar.byId(learner.avatarId).emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(learner.nickname, style: t.titleLarge),
                    Text(learner.isGuest ? 'Guest learner on this device' : 'Learner on this device'),
                  ]),
                ),
              ]),
              TextButton(onPressed: () => _push(const LearnersScreen()), child: const Text('Switch or manage learners')),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _Stat(label: 'Sounds explored', value: '${explored.length}', color: AppTokens.mint),
          _Stat(label: 'Practising', value: practising.isEmpty ? '–' : practising.join(', '), color: AppTokens.coral),
          _Stat(label: 'Recognised independently', value: recognised.isEmpty ? '–' : recognised.join(', '), color: AppTokens.lavender),
        ]),
        const SizedBox(height: 6),
        Text('Labels describe evidence so far; they are not a measure of mastery.',
            style: t.bodyMedium?.copyWith(color: AppTokens.navyMuted)),
        const SectionTitle('Recent activity'),
        if (recent.isEmpty)
          const Text('Nothing yet. Activity will appear here after playing.')
        else
          Card(
            child: Column(children: [
              for (final a in recent)
                ListTile(
                  dense: true,
                  title: Text('${_activityName(a)} · ${_targetName(a.targetId)}'),
                  subtitle: Text(
                      '${a.domain.label} · ${_outcomeText(a.outcome)} · ${a.context == ActivityContext.guidedLesson ? 'lesson' : 'free play'}'),
                  trailing: Text(_ago(a.completedAt)),
                ),
            ]),
          ),
        const SectionTitle('Settings and details'),
        SettingsNavTile(
            icon: AppIcons.insights,
            title: 'Progress details',
            subtitle: 'Sounds, letters, numbers and shapes',
            onTap: () => _push(const ProgressDetailsScreen())),
        SettingsNavTile(
            icon: AppIcons.people, title: 'Learners', subtitle: 'Add, switch, reset or delete', onTap: () => _push(const LearnersScreen())),
        SettingsNavTile(
            icon: AppIcons.learning,
            title: 'Learning preferences',
            subtitle: 'For ${learner.nickname}',
            onTap: () => _push(const PreferencesScreen())),
        SettingsNavTile(
            icon: AppIcons.listen,
            title: 'Sound and accessibility',
            subtitle: 'This device',
            onTap: () => _push(const DeviceSettingsScreen())),
        SettingsNavTile(
            icon: AppIcons.contentStatus,
            title: 'Content status',
            subtitle: 'Which recordings are available and reviewed',
            onTap: () => _push(const ContentStatusScreen())),
        SettingsNavTile(icon: AppIcons.privacy, title: 'Privacy', onTap: () => _push(const PrivacyScreen())),
        SettingsNavTile(icon: AppIcons.help, title: 'Help', onTap: () => _push(const HelpScreen())),
      ],
    );
  }

  static String _activityName(ActivityAttempt a) {
    final t = a.gameType;
    if (t == null) return 'Explored';
    return ContentCatalog.activities[t]?.title ??
        switch (t) {
          GameType.countMatch => 'Count and Match',
          GameType.shapeMatch => 'Shape Match',
          GameType.shapeName => 'Find the Shape',
          _ => t.name,
        };
  }

  static String _targetName(String targetId) {
    final name = targetId.split(':').last;
    return targetId.startsWith('word:') ? ContentCatalog.wordsById[name]?.text ?? name : name;
  }

  static String _outcomeText(AttemptOutcome o) => switch (o) {
        AttemptOutcome.correctFirstTry => 'first try',
        AttemptOutcome.correctAfterRetry => 'after listening again',
        AttemptOutcome.correctWithHint => 'with a hint',
        AttemptOutcome.demonstrated => 'shown the answer',
        AttemptOutcome.completed => 'completed',
        AttemptOutcome.completedWithHelp => 'completed with help',
        AttemptOutcome.skipped => 'skipped',
        AttemptOutcome.exposure => 'explored',
      };

  static String _ago(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppTokens.radiusSmall)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ]),
        ),
      );
}
