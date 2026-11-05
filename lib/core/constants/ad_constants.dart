import 'package:flutter/foundation.dart';

class AdConstants {
  static const String appId = 'ca-app-pub-8834178071297418~9339297331';

  static String get bannerAdUnitId => _unitId(
    production: 'ca-app-pub-8834178071297418/8026215666',
    androidTest: 'ca-app-pub-3940256099942544/6300978111',
    iosTest: 'ca-app-pub-3940256099942544/2934735716',
  );

  static String get interstitialAdUnitId => _unitId(
    production: 'ca-app-pub-8834178071297418/8711827557',
    androidTest: 'ca-app-pub-3940256099942544/1033173712',
    iosTest: 'ca-app-pub-3940256099942544/4411468910',
  );

  static String get rewardedInterstitialAdUnitId => _unitId(
    production: 'ca-app-pub-8834178071297418/4640720603',
    androidTest: 'ca-app-pub-3940256099942544/5354046379',
    iosTest: 'ca-app-pub-3940256099942544/6978759866',
  );

  static String get rewardedAdUnitId => _unitId(
    production: 'ca-app-pub-8834178071297418/6649554811',
    androidTest: 'ca-app-pub-3940256099942544/5224354917',
    iosTest: 'ca-app-pub-3940256099942544/1712485313',
  );

  static String get nativeAdUnitId => _unitId(
    production: 'ca-app-pub-8834178071297418/5019994556',
    androidTest: 'ca-app-pub-3940256099942544/2247696110',
    iosTest: 'ca-app-pub-3940256099942544/3986624511',
  );

  static String get appOpenAdUnitId => _unitId(
    production: 'ca-app-pub-8834178071297418/8134026875',
    androidTest: 'ca-app-pub-3940256099942544/9257395921',
    iosTest: 'ca-app-pub-3940256099942544/5575463023',
  );

  static String _unitId({
    required String production,
    required String androidTest,
    required String iosTest,
  }) {
    // Test ads in debug and profile builds; production IDs only in release,
    // so device testing never generates invalid traffic.
    if (!kReleaseMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? iosTest
          : androidTest;
    }
    return production;
  }
}
