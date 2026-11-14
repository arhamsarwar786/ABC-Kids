import 'dart:io';

import 'package:abc_kids_learning/core/services/ads_service.dart';
import 'package:abc_kids_learning/features/shell/main_shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Google Play Families ads rules for an app aimed at children.
void main() {
  test('no full-screen formats: interstitial, rewarded and app-open stay off on every platform', () {
    for (final p in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = p;
      final policy = AdPlacementPolicy.forPlatform();
      expect(policy.sessionEndInterstitial, isFalse);
      expect(policy.rewardedPrompts, isFalse);
      expect(policy.appOpenOnForeground, isFalse);
      expect(policy.childNative, isFalse, reason: 'one placement per page: the banner');
    }
    debugDefaultTargetPlatformOverride = null;
  });

  test('browse-tab banner on Android only (Apple Kids Category: no third-party ads)', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AdPlacementPolicy.forPlatform().childBanners, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AdPlacementPolicy.forPlatform().childBanners, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  test('every ad request is non-personalised and the SDK is child-directed and G-rated', () {
    expect(AdsService.childRequest.nonPersonalizedAds, isTrue);
    final src = File('lib/core/services/ads_service.dart').readAsStringSync();
    expect(src, contains('maxAdContentRating: MaxAdContentRating.g'));
    expect(src, contains('ageRestrictedTreatment: AgeRestrictedTreatment.child'));
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      expect(f.readAsStringSync().contains('const AdRequest()'), isFalse, reason: '${f.path} makes a personalised request');
    }
  });

  test('no inline ad widget inside lessons or gameplay (only the docked strip below them)', () {
    // Inline banners live in browse/scroll screens only. Lessons and the game
    // screens themselves never contain one; the app-wide strip sits outside them.
    for (final dir in ['lib/features/lesson', 'lib/features/games']) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (f.path.endsWith('games_catalogue.dart')) continue; // the Games tab list
        final s = f.readAsStringSync();
        expect(RegExp(r'BannerSlot|KidSafeBanner|AppBannerAd|NativeAdWidget|AdWidget').hasMatch(s), isFalse, reason: f.path);
      }
    }
  });

  test('one banner per page: BannerSlot is used only by the app-wide strip and the tab shell dock', () {
    final users = [
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')))
        if (RegExp(r'\bBannerSlot\(').hasMatch(f.readAsStringSync())) f.path,
    ]..sort();
    expect(users, ['lib/features/shared/widgets/ad_slot.dart', 'lib/features/shared/widgets/kid_safe_banner.dart', 'lib/features/shell/main_shell.dart']);
  });

  testWidgets('shell shows no banner until an ad has loaded (no empty ad box)', (tester) async {
    await setScreen(tester, const Size(390, 844));
    final app = await TestApp.create();
    await tester.pumpWidget(app.wrap(const MainShell()));
    await tester.pumpAndSettle();
    expect(find.text('Advertisement'), findsNothing);
  });
}
