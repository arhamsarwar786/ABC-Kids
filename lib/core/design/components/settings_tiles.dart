import 'package:flutter/material.dart';

import '../tokens.dart';
import '../app_icons.dart';

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const SettingsSwitchTile({super.key, required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => _Card(
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: subtitle == null ? null : Text(subtitle!),
          value: value,
          onChanged: onChanged,
        ),
      );
}

class SettingsSliderTile extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final Widget? trailing;
  const SettingsSliderTile({super.key, required this.title, required this.value, required this.onChanged, this.trailing});

  @override
  Widget build(BuildContext context) => _Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              Text('${(value * 100).round()}%'),
              ?trailing,
            ]),
            Slider(
              value: value,
              divisions: 10,
              label: '${(value * 100).round()}%',
              semanticFormatterCallback: (v) => '$title ${(v * 100).round()} percent',
              onChanged: onChanged,
            ),
          ]),
        ),
      );
}

class SettingsChoiceTile<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  const SettingsChoiceTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => _Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium)],
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (v, label) in options)
                ChoiceChip(
                  label: Text(label),
                  selected: v == value,
                  onSelected: (_) => onChanged(v),
                  selectedColor: AppTokens.lavender,
                ),
            ]),
          ]),
        ),
      );
}

class SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  const SettingsNavTile({super.key, required this.icon, required this.title, this.subtitle, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => _Card(
        child: ListTile(
          minVerticalPadding: 14,
          leading: Icon(icon, color: color ?? AppTokens.purple),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: const Icon(AppIcons.chevronRight),
          onTap: onTap,
        ),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppTokens.radius), boxShadow: AppTokens.softShadow),
          child: Card(clipBehavior: Clip.antiAlias, child: child),
        ),
      );
}
