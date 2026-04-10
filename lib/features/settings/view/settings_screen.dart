import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
      appBar: AppBar(
        title: Text(
          'Setting',
          style: GoogleFonts.fredoka(
            color: const Color(0xFF5D5D5D),
            fontWeight: FontWeight.w900,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFB57AFF), Color(0xFF7A4BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.appBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mute/Unmute Button (Functional)
                GestureDetector(
                  onTap: () => viewModel.toggleMute(audioService),
                  child: SettingCircleButton(
                    icon: audioService.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: const Color(0xFFFF7675),
                  ),
                ),
                const SizedBox(height: 40),

                // Share Button (Functional)
                GestureDetector(
                  onTap: () => viewModel.shareApp(),
                  child: const SettingCircleButton(
                    icon: Icons.share_rounded,
                    color: Color(0xFFFF7675),
                  ),
                ),

                const SizedBox(height: 100), // Push away from bottom castle
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;

  const SettingCircleButton({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 50),
    );
  }
}
