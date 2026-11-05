import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design/components/scaffolds.dart';
import '../../core/design/tokens.dart';
import '../../data/models/learner.dart';
import '../../state/learner_store.dart';
import '../../state/progress_store.dart';
import 'parent_gate.dart';
import '../../core/design/app_icons.dart';

/// Local learner profiles: nickname and built-in avatar only.
class LearnersScreen extends StatelessWidget {
  const LearnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LearnerStore>();
    return ParentScaffold(
      title: 'Learners',
      children: [
        for (final l in store.learners)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Text(Avatar.byId(l.avatarId).emoji, style: const TextStyle(fontSize: 32)),
              title: Text(l.nickname),
              subtitle: Text(l.id == store.active.id ? 'Playing now' : 'Tap to switch'),
              selected: l.id == store.active.id,
              onTap: () => store.switchTo(l.id),
              trailing: PopupMenuButton<String>(
                tooltip: 'More for ${l.nickname}',
                onSelected: (v) {
                  if (v == 'edit') _edit(context, l);
                  if (v == 'reset') _reset(context, l);
                  if (v == 'delete') _delete(context, l);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit name or avatar')),
                  PopupMenuItem(value: 'reset', child: Text('Reset progress')),
                  PopupMenuItem(value: 'delete', child: Text('Delete learner')),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: AppTokens.purple),
          onPressed: () => _edit(context, null),
          icon: const Icon(AppIcons.addPerson),
          label: const Text('Add a learner'),
        ),
        const SizedBox(height: 12),
        Text('Profiles are stored only on this device. We ask only for a nickname and a picture: no date of birth, email or photos.',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Future<void> _edit(BuildContext context, LearnerProfile? existing) async {
    final store = context.read<LearnerStore>();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _ProfileDialog(existing: existing),
    );
    if (result == null) return;
    final (name, avatar) = result;
    if (existing == null) {
      final p = await store.addLearner(name, avatar);
      await store.switchTo(p.id);
    } else {
      await store.updateLearner(existing.copyWith(nickname: LearnerProfile.cleanNickname(name), avatarId: avatar));
    }
  }

  Future<void> _reset(BuildContext context, LearnerProfile l) async {
    final progress = context.read<ProgressStore>();
    if (!await ParentGate.show(context, reason: 'Confirm it’s a grown-up') || !context.mounted) return;
    final data = progress.peek(l.id);
    final ok = await _confirm(
      context,
      title: 'Reset ${l.nickname}’s progress?',
      removed: [
        '${data.attempts.length} recorded activities and all skill progress',
        '${data.stickers.length} stickers${data.legacyStars > 0 ? ' and ${data.legacyStars} stars from before' : ''}',
        '${data.completedLessons.length} finished lessons and any saved place in a lesson',
      ],
      kept: '${l.nickname}’s name, picture and preferences, other learners, and device settings are kept.',
      action: 'Reset ${l.nickname}’s progress',
    );
    if (ok) await progress.resetLearner(l.id);
  }

  Future<void> _delete(BuildContext context, LearnerProfile l) async {
    final store = context.read<LearnerStore>();
    final progress = context.read<ProgressStore>();
    if (!await ParentGate.show(context, reason: 'Confirm it’s a grown-up') || !context.mounted) return;
    final data = progress.peek(l.id);
    final ok = await _confirm(
      context,
      title: 'Delete ${l.nickname}?',
      removed: [
        'The profile (name “${l.nickname}”, picture and preferences)',
        '${data.attempts.length} recorded activities and all skill progress',
        '${data.stickers.length} stickers${data.legacyStars > 0 ? ' and ${data.legacyStars} stars from before' : ''}',
        'Finished lessons and any saved place in a lesson',
      ],
      kept: 'Other learners and device settings are kept.${store.learners.length == 1 ? ' A new guest learner will be created.' : ''}',
      action: 'Delete ${l.nickname}',
    );
    if (!ok) return;
    await progress.flush();
    await store.deleteLearner(l.id);
  }

  Future<bool> _confirm(BuildContext context,
      {required String title, required List<String> removed, required String kept, required String action}) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('This removes:'),
            const SizedBox(height: 6),
            for (final x in removed) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $x')),
            const SizedBox(height: 8),
            Text(kept),
            const SizedBox(height: 8),
            const Text('This cannot be undone.'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTokens.gentle),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return r ?? false;
  }
}

class _ProfileDialog extends StatefulWidget {
  final LearnerProfile? existing;
  const _ProfileDialog({this.existing});
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.nickname ?? '');
  late String _avatar = widget.existing?.avatarId ?? Avatar.all[1].id;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = LearnerProfile.cleanNickname(_name.text).isNotEmpty;
    return AlertDialog(
      title: Text(widget.existing == null ? 'New learner' : 'Edit learner'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _name,
            maxLength: LearnerProfile.maxNicknameLength,
            decoration: const InputDecoration(labelText: 'Nickname', helperText: 'A first name or nickname is enough'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          const Text('Picture'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in Avatar.all)
              ChoiceChip(
                label: Text(a.emoji, style: const TextStyle(fontSize: 26)),
                tooltip: a.label,
                selected: _avatar == a.id,
                selectedColor: AppTokens.lavender,
                onSelected: (_) => setState(() => _avatar = a.id),
              ),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: valid ? () => Navigator.pop(context, (_name.text, _avatar)) : null, child: const Text('Save')),
      ],
    );
  }
}
