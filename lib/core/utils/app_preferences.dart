import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static late SharedPreferences _prefs;

  static const String _keyMuteSound = 'mute_sound';
  static const String _keyOnboardingSeen = 'onboarding_seen';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isSoundMuted => _prefs.getBool(_keyMuteSound) ?? false;
  static Future<void> setSoundMuted(bool value) async {
    await _prefs.setBool(_keyMuteSound, value);
  }

  static bool get isOnboardingSeen => _prefs.getBool(_keyOnboardingSeen) ?? false;
  static Future<void> setOnboardingSeen(bool value) async {
    await _prefs.setBool(_keyOnboardingSeen, value);
  }
}
