import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/audio/audio_coordinator.dart';
import '../../core/design/components/scaffolds.dart';
import '../../core/design/components/settings_tiles.dart';
import '../../state/settings_store.dart';
import '../../core/design/app_icons.dart';

/// Device-wide sound and accessibility settings.
class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});
  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  String? _previewMessage;

  Future<void> _preview() async {
    final audio = context.read<AudioCoordinator>();
    final r = await audio.speak('Hello! This is how words and instructions will sound.');
    if (!mounted) return;
    setState(() => _previewMessage = switch (r) {
          PlayResult.played => null,
          PlayResult.unavailable => audio.deviceVoiceInstalled == false
              ? 'No English text-to-speech voice was found on this device.'
              : 'Turn on “Device voice for words” to hear a preview.',
          PlayResult.failed => 'The preview could not play.',
          PlayResult.cancelled => null,
        });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<SettingsStore>();
    final s = store.settings;
    final audio = context.watch<AudioCoordinator>();
    return ParentScaffold(
      title: 'Sound and accessibility',
      children: [
        const SectionTitle('Volume'),
        SettingsSliderTile(
          title: 'Narration (letters, words, instructions)',
          value: s.narrationVolume,
          onChanged: (v) => store.update((x) => x.copyWith(narrationVolume: v)),
          trailing: IconButton(tooltip: 'Preview narration', onPressed: _preview, icon: const Icon(AppIcons.playCircle)),
        ),
        if (_previewMessage != null) Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(_previewMessage!)),
        SettingsSliderTile(title: 'Music', value: s.musicVolume, onChanged: (v) => store.update((x) => x.copyWith(musicVolume: v))),
        SettingsSwitchTile(
          title: 'Mute music',
          subtitle: 'Narration and effects still play.',
          value: s.musicMuted,
          onChanged: (v) => store.update((x) => x.copyWith(musicMuted: v)),
        ),
        SettingsSliderTile(title: 'Effects', value: s.effectsVolume, onChanged: (v) => store.update((x) => x.copyWith(effectsVolume: v))),
        SettingsSwitchTile(
          title: 'Device voice for words',
          subtitle: 'No word recordings are bundled yet. When on, your device’s text-to-speech reads whole words and instructions. '
              'It is never used for single letter sounds.${audio.deviceVoiceInstalled == false ? ' No English voice was found on this device.' : ''}',
          value: s.deviceVoiceForWords,
          onChanged: (v) => store.update((x) => x.copyWith(deviceVoiceForWords: v)),
        ),
        const SizedBox(height: 4),
        const Text('Letter sounds always play at normal speed.'),
        const SectionTitle('Accessibility'),
        SettingsSwitchTile(
          title: 'Reduce motion',
          subtitle: 'Stops floating and moving animations. The system setting is also respected.',
          value: s.reduceMotion,
          onChanged: (v) => store.update((x) => x.copyWith(reduceMotion: v)),
        ),
        SettingsSwitchTile(
          title: 'Larger text',
          subtitle: 'Makes text 20% larger on top of the system text size.',
          value: s.largerText,
          onChanged: (v) => store.update((x) => x.copyWith(largerText: v)),
        ),
        SettingsSwitchTile(
          title: 'Show words under pictures',
          value: s.showCaptions,
          onChanged: (v) => store.update((x) => x.copyWith(showCaptions: v)),
        ),
      ],
    );
  }
}
