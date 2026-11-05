import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/components/scaffolds.dart';
import '../../core/design/tokens.dart';
import '../../data/content/content_catalog.dart';
import '../../data/models/content.dart';
import '../../data/models/progress.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';

/// Evidence per sound and per domain, with guided vs free-play counts.
class ProgressDetailsScreen extends StatelessWidget {
  const ProgressDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressStore>();
    final learner = context.watch<LearnerStore>().active;
    final c = progress.criteria;
    final t = Theme.of(context).textTheme;
    final letterTargets = learner.preferences.soundSequence.map(Targets.letter).toList();
    final other = progress.data.skills.values
        .where((s) => !letterTargets.contains(s.targetId))
        .where((s) =>
            s.targetId.startsWith('number:') ||
            s.targetId.startsWith('shape:') ||
            s.targetId.startsWith('word:') ||
            s.targetId.startsWith('letter:'))
        .toList()
      ..sort((a, b) => a.targetId.compareTo(b.targetId));

    return ParentScaffold(
      title: 'Progress details',
      children: [
        Text(learner.nickname, style: t.titleLarge),
        const SizedBox(height: 6),
        SoftCard(
          color: AppTokens.purpleSoft,
          child: Text(
            '“Recognised independently” needs at least ${c.minIndependentCorrect} first-try answers on at least '
            '${c.minDistinctDays} different days, and ${(c.minRecentFirstTryRate * 100).round()}% of the last '
            '${c.recentWindow} tries right first time. Answers after a replay, a hint or a demonstration count as practice, '
            'never as independent. Visual matching, building and tracing are not phonics evidence.',
            style: t.bodyMedium,
          ),
        ),
        const SectionTitle('Sounds'),
        for (final target in letterTargets) _TargetCard(targetId: target, progress: progress),
        if (other.isNotEmpty) ...[
          const SectionTitle('Other letters, words, numbers and shapes'),
          for (final id in {for (final s in other) s.targetId}) _TargetCard(targetId: id, progress: progress),
        ],
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  final String targetId;
  final ProgressStore progress;
  const _TargetCard({required this.targetId, required this.progress});

  @override
  Widget build(BuildContext context) {
    final skills = progress.skillsForTarget(targetId)..sort((a, b) => a.domain.index.compareTo(b.domain.index));
    final t = Theme.of(context).textTheme;
    final name = targetId.split(':').last;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(targetId.startsWith('word:') ? ContentCatalog.wordsById[name]?.text ?? name : name, style: t.titleLarge),
        subtitle: Text(skills.isEmpty ? 'New' : '${skills.where((s) => s.practiceAttempts > 0).length} skills practised'),
        children: [
          if (skills.isEmpty) const ListTile(title: Text('No activity yet.')),
          for (final s in skills)
            ListTile(
              title: Text('${s.domain.label}: ${s.label(progress.criteria).text}'),
              subtitle: Text(s.domain.name == 'exposure'
                  ? 'Seen or heard ${s.exposures} times'
                  : 'First try ${s.independentCorrect} · with help ${s.assistedCorrect} · shown ${s.demonstrated} · '
                      'lesson ${s.guidedAttempts} / free play ${s.freePlayAttempts} · days ${s.independentDays.length}'),
            ),
        ],
      ),
    );
  }
}
