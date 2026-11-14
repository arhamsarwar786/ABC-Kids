import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../audio/audio_coordinator.dart';
import '../constants/ad_constants.dart';

/// Where ads may appear, following the Google Play Families ads policy for
/// apps aimed at children: one clearly labelled banner per screen, docked in
/// its own strip below the content (see AdFrame; never drawn over lessons,
/// games or rewards), and no full-screen formats —
/// interstitial, rewarded and app-open ads “take up the entire screen”, which
/// the policy prohibits for this audience. Those switches stay off; the code
/// is kept so the decision is documented. See docs/redesign/MONETIZATION.md.
class AdPlacementPolicy {
  final bool childBanners;
  final bool childNative;
  final bool sessionEndInterstitial;
  final bool appOpenOnForeground;
  final bool rewardedPrompts;

  const AdPlacementPolicy({
    this.childBanners = false,
    this.childNative = false,
    this.sessionEndInterstitial = false,
    this.appOpenOnForeground = false,
    this.rewardedPrompts = false,
  });

  /// Browse-tab banner on Android only: Apple's Kids Category does not allow
  /// third-party ads in the child area.
  factory AdPlacementPolicy.forPlatform() => AdPlacementPolicy(childBanners: defaultTargetPlatform == TargetPlatform.android);
}

/// Google Mobile Ads integration (child-directed, G-rated).
///
/// The SDK starts when the app's banner strip first builds (banner only, so
/// nothing covers the screen at launch).
class AdsService extends ChangeNotifier {
  static const Duration _fullscreenCooldown = Duration(seconds: 90);
  static const Duration _appOpenMaxAge = Duration(hours: 4);

  final AdPlacementPolicy policy;
  final AudioCoordinator? _audio;
  Future<void>? _starting;
  bool _ready = false;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadTime;
  DateTime? _lastFullscreenAt;
  bool _isShowingFullscreen = false;
  StreamSubscription<AppState>? _appStateSub;

  AdsService({this.policy = const AdPlacementPolicy(), AudioCoordinator? audio}) : _audio = audio;

  /// Every ad request: non-personalised (no interest-based ads or remarketing).
  static const AdRequest childRequest = AdRequest(nonPersonalizedAds: true);

  bool get ready => _ready;

  /// Initialises the SDK once. Safe to call repeatedly.
  Future<void> ensureStarted() => _starting ??= _start();

  Future<void> _start() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          // G: suitable for all audiences, including children.
          maxAdContentRating: MaxAdContentRating.g,
          // Child-directed and under the age of consent (replaces the older
          // tagForChildDirectedTreatment / tagForUnderAgeOfConsent flags).
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
        ),
      );
      await MobileAds.instance.initialize();
      _ready = true;
      notifyListeners();
      if (policy.sessionEndInterstitial) loadInterstitial();
      if (policy.rewardedPrompts) loadRewarded();
      if (policy.appOpenOnForeground) {
        loadAppOpen();
        await AppStateEventNotifier.startListening();
        _appStateSub = AppStateEventNotifier.appStateStream.listen((s) {
          if (s == AppState.foreground) showAppOpenIfAvailable();
        });
      }
    } catch (e) {
      debugPrint('Ads unavailable: $e');
      _starting = null;
    }
  }

  bool _canShowFullscreen() {
    if (_isShowingFullscreen) return false;
    final last = _lastFullscreenAt;
    return last == null || DateTime.now().difference(last) >= _fullscreenCooldown;
  }

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdConstants.interstitialAdUnitId,
      request: childRequest,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (e) => _interstitialAd = null,
      ),
    );
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: AdConstants.rewardedAdUnitId,
      request: childRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (e) => _rewardedAd = null,
      ),
    );
  }

  void loadAppOpen() {
    AppOpenAd.load(
      adUnitId: AdConstants.appOpenAdUnitId,
      request: childRequest,
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (e) => _appOpenAd = null,
      ),
    );
  }

  /// Disabled by [AdPlacementPolicy.sessionEndInterstitial] (off).
  Future<void> showInterstitialAtSessionEnd() async {
    if (!policy.sessionEndInterstitial || _interstitialAd == null || !_canShowFullscreen()) return;
    final ad = _interstitialAd!;
    _interstitialAd = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = _callback<InterstitialAd>(onDone: () {
      loadInterstitial();
      if (!done.isCompleted) done.complete();
    });
    _beginShow();
    await ad.show();
    return done.future;
  }

  /// Disabled by [AdPlacementPolicy.rewardedPrompts] (off). Returns true if
  /// the reward was earned.
  Future<bool> showRewarded() async {
    if (!policy.rewardedPrompts || _rewardedAd == null || !_canShowFullscreen()) return false;
    final ad = _rewardedAd!;
    _rewardedAd = null;
    var earned = false;
    final done = Completer<void>();
    ad.fullScreenContentCallback = _callback<RewardedAd>(onDone: () {
      loadRewarded();
      if (!done.isCompleted) done.complete();
    });
    _beginShow();
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    await done.future;
    return earned;
  }

  /// Disabled by [AdPlacementPolicy.appOpenOnForeground] (off).
  void showAppOpenIfAvailable() {
    if (!policy.appOpenOnForeground || !_canShowFullscreen() || _appOpenAd == null) return;
    final loaded = _appOpenLoadTime;
    if (loaded == null || DateTime.now().difference(loaded) > _appOpenMaxAge) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      loadAppOpen();
      return;
    }
    final ad = _appOpenAd!;
    _appOpenAd = null;
    ad.fullScreenContentCallback = _callback<AppOpenAd>(onDone: loadAppOpen);
    _beginShow();
    ad.show();
  }

  FullScreenContentCallback<T> _callback<T extends Ad>({required VoidCallback onDone}) {
    return FullScreenContentCallback<T>(
      onAdFailedToShowFullScreenContent: (ad, e) {
        _isShowingFullscreen = false;
        ad.dispose();
        _audio?.releaseMusic('ad');
        onDone();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullscreen = false;
        ad.dispose();
        _audio?.releaseMusic('ad');
        onDone();
      },
    );
  }

  void _beginShow() {
    _audio?.stopNarration();
    _audio?.suspendMusic('ad');
    _isShowingFullscreen = true;
    _lastFullscreenAt = DateTime.now();
  }

  @override
  void dispose() {
    _appStateSub?.cancel();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
    super.dispose();
  }
}
