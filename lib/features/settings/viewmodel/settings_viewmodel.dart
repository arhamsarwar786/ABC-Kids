import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import 'package:share_plus/share_plus.dart';

class SettingsViewModel extends ChangeNotifier {
  void toggleMute(AudioService audioService) {
    audioService.toggleMute();
  }

  void shareApp() {
    Share.share('Check out ABC Kids Learning App! Download it now to let your kids learn numbers and alphabets.');
  }
}
