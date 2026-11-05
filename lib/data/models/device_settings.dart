/// Settings that belong to the device, not to a learner.
class DeviceSettings {
  final double narrationVolume;
  final double musicVolume;
  final double effectsVolume;
  final bool musicMuted;

  /// Use the device text-to-speech voice for whole words and instructions
  /// when no recording exists. Never used for isolated sounds.
  final bool deviceVoiceForWords;
  final bool reduceMotion;
  final bool largerText;
  final bool showCaptions;
  final bool firstRunComplete;

  const DeviceSettings({
    this.narrationVolume = 1.0,
    this.musicVolume = 0.35,
    this.effectsVolume = 0.6,
    this.musicMuted = false,
    this.deviceVoiceForWords = true,
    this.reduceMotion = false,
    this.largerText = false,
    this.showCaptions = true,
    this.firstRunComplete = false,
  });

  DeviceSettings copyWith({
    double? narrationVolume,
    double? musicVolume,
    double? effectsVolume,
    bool? musicMuted,
    bool? deviceVoiceForWords,
    bool? reduceMotion,
    bool? largerText,
    bool? showCaptions,
    bool? firstRunComplete,
  }) {
    return DeviceSettings(
      narrationVolume: narrationVolume ?? this.narrationVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      effectsVolume: effectsVolume ?? this.effectsVolume,
      musicMuted: musicMuted ?? this.musicMuted,
      deviceVoiceForWords: deviceVoiceForWords ?? this.deviceVoiceForWords,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      largerText: largerText ?? this.largerText,
      showCaptions: showCaptions ?? this.showCaptions,
      firstRunComplete: firstRunComplete ?? this.firstRunComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'narrationVolume': narrationVolume,
        'musicVolume': musicVolume,
        'effectsVolume': effectsVolume,
        'musicMuted': musicMuted,
        'deviceVoiceForWords': deviceVoiceForWords,
        'reduceMotion': reduceMotion,
        'largerText': largerText,
        'showCaptions': showCaptions,
        'firstRunComplete': firstRunComplete,
      };

  factory DeviceSettings.fromJson(Map<String, dynamic> j) {
    const d = DeviceSettings();
    double vol(String k, double f) {
      final v = j[k];
      return v is num ? v.toDouble().clamp(0.0, 1.0) : f;
    }

    bool b(String k, bool f) => j[k] is bool ? j[k] as bool : f;
    return DeviceSettings(
      narrationVolume: vol('narrationVolume', d.narrationVolume),
      musicVolume: vol('musicVolume', d.musicVolume),
      effectsVolume: vol('effectsVolume', d.effectsVolume),
      musicMuted: b('musicMuted', d.musicMuted),
      deviceVoiceForWords: b('deviceVoiceForWords', d.deviceVoiceForWords),
      reduceMotion: b('reduceMotion', d.reduceMotion),
      largerText: b('largerText', d.largerText),
      showCaptions: b('showCaptions', d.showCaptions),
      firstRunComplete: b('firstRunComplete', d.firstRunComplete),
    );
  }
}
