import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/constants/app_assets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final audioService = context.watch<AudioService>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.appBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.volume_up_rounded, size: 32),
                    title: const Text(
                      'Mute Sound',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('Mute background music and sounds'),
                    trailing: Switch(
                      value: audioService.isMuted,
                      onChanged: (value) {
                        viewModel.toggleMute(audioService);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.share_rounded, size: 32),
                    title: const Text(
                      'Share App',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('Share this app with friends'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: () {
                      viewModel.shareApp();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
