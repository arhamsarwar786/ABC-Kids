import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_constants.dart';
import '../utils/app_preferences.dart';
import 'audio_service.dart';
import '../../features/shared/widgets/ad_prompt_dialog.dart';

/// Loads and shows fullscreen ads at policy-safe moments.
class AdsService extends ChangeNotifier {
  static const Duration _fullscreenCooldown = Duration(seconds: 90);
  static const Duration _appOpenMaxAge = Duration(hours: 4);
  static const int _minViewsForInterstitial = 2;
  static const int _lettersPerRewardedBreak = 5;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  AppOpenAd? _appOpenAd;

  DateTime? _appOpenLoadTime;
  DateTime? _lastFullscreenAt;
  bool _isShowingFullscreen = false;
  bool _isFirstForeground = true;
  bool _homeReached = false;
  int _learningViews = 0;
  int _lettersSinceRewardedBreak = 0;
  int _starCount = 0;

  StreamSubscription<AppState>? _appStateSub;
  AudioService? _audio;

  int get starCount => _starCount;

  static Future<void> configureSdk() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.g,
        ageRestrictedTreatment: AgeRestrictedTreatment.child,
      ),
    );
    await MobileAds.instance.initialize();
  }

  Future<void> start() async {
    _starCount = AppPreferences.starCount;
    loadInterstitial();
    loadRewarded();
    loadRewardedInterstitial();
    loadAppOpen();
    await AppStateEventNotifier.startListening();
    _appStateSub = AppStateEventNotifier.appStateStream.listen(_onAppState);
  }

  void attachAudio(AudioService audio) {
    _audio = audio;
  }

  void markHomeReached() {
    _homeReached = true;
  }

  void recordLearningView() {
    _learningViews++;
  }

  void recordLetterCompleted() {
    _lettersSinceRewardedBreak++;
  }

  bool get shouldOfferRewardedInterstitial =>
      _lettersSinceRewardedBreak >= _lettersPerRewardedBreak &&
      _rewardedInterstitialAd != null &&
      _canShowFullscreen();

  bool _canShowFullscreen() {
    if (_isShowingFullscreen) return false;
    final last = _lastFullscreenAt;
    if (last != null && DateTime.now().difference(last) < _fullscreenCooldown) {
      return false;
    }
    return true;
  }

  void _onAppState(AppState state) {
    if (state != AppState.foreground) return;
    if (_isFirstForeground) {
      _isFirstForeground = false;
      return;
    }
    if (!_homeReached) return;
    showAppOpenIfAvailable();
  }

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: AdConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void loadRewardedInterstitial() {
    RewardedInterstitialAd.load(
      adUnitId: AdConstants.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded interstitial failed to load: $error');
          _rewardedInterstitialAd = null;
        },
      ),
    );
  }

  void loadAppOpen() {
    AppOpenAd.load(
      adUnitId: AdConstants.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('App open failed to load: $error');
          _appOpenAd = null;
        },
      ),
    );
  }

  /// Session-end interstitial when leaving ABC / Numbers after real play.
  Future<void> showInterstitialAtSessionEnd() {
    final completer = Completer<void>();
    if (_learningViews < _minViewsForInterstitial ||
        _interstitialAd == null ||
        !_canShowFullscreen()) {
      completer.complete();
      return completer.future;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    ad.fullScreenContentCallback = _callback<InterstitialAd>(
      onDone: () {
        loadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
    );
    _beginShow();
    ad.show();
    return completer.future;
  }

  /// User-opt-in rewarded ad. Must disclose the reward before showing.
  Future<void> offerRewardedAd(BuildContext context) async {
    if (_rewardedAd == null || !_canShowFullscreen()) {
      if (context.mounted) {
        await AdPromptDialog.showUnavailable(context);
      }
      loadRewarded();
      return;
    }

    final watch = await AdPromptDialog.show(
      context,
      title: 'Earn a star!',
      message: 'Watch a short video to earn 1 star. You can skip if you want.',
      watchLabel: 'Watch',
      skipLabel: 'Not now',
    );
    if (watch != true || !context.mounted) return;
    if (_rewardedAd == null || !_canShowFullscreen()) return;

    final ad = _rewardedAd!;
    _rewardedAd = null;
    var earned = false;
    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = _callback<RewardedAd>(
      onDone: () {
        loadRewarded();
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );
    _beginShow();
    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
    } catch (e) {
      debugPrint('Rewarded failed to show: $e');
      if (!dismissed.isCompleted) dismissed.complete();
    }
    await dismissed.future;
    if (earned && context.mounted) {
      await _grantStar(context);
    }
  }

  /// Natural break after several letters. Intro screen with skip is required.
  Future<void> offerRewardedInterstitial(BuildContext context) async {
    if (!shouldOfferRewardedInterstitial) return;

    final watch = await AdPromptDialog.show(
      context,
      title: 'Bonus star!',
      message:
          'Watch a short video for a bonus star, or skip and keep learning.',
      watchLabel: 'Watch',
      skipLabel: 'Skip',
    );
    _lettersSinceRewardedBreak = 0;
    if (watch != true || !context.mounted) return;
    if (_rewardedInterstitialAd == null || !_canShowFullscreen()) return;

    final ad = _rewardedInterstitialAd!;
    _rewardedInterstitialAd = null;
    var earned = false;
    final dismissed = Completer<void>();
    ad.fullScreenContentCallback = _callback<RewardedInterstitialAd>(
      onDone: () {
        loadRewardedInterstitial();
        if (!dismissed.isCompleted) dismissed.complete();
      },
    );
    _beginShow();
    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
    } catch (e) {
      debugPrint('Rewarded interstitial failed to show: $e');
      if (!dismissed.isCompleted) dismissed.complete();
    }
    await dismissed.future;
    if (earned && context.mounted) {
      await _grantStar(context);
    }
  }

  void showAppOpenIfAvailable() {
    if (!_canShowFullscreen() || _appOpenAd == null) {
      if (_appOpenAd == null) loadAppOpen();
      return;
    }
    final loadTime = _appOpenLoadTime;
    if (loadTime == null ||
        DateTime.now().difference(loadTime) > _appOpenMaxAge) {
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

  FullScreenContentCallback<T> _callback<T extends Ad>({
    required VoidCallback onDone,
  }) {
    return FullScreenContentCallback<T>(
      onAdShowedFullScreenContent: (_) {
        _isShowingFullscreen = true;
        _lastFullscreenAt = DateTime.now();
        _pauseAudio();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        debugPrint('Fullscreen ad failed to show: $error');
        _isShowingFullscreen = false;
        failedAd.dispose();
        _resumeAudio();
        onDone();
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        _isShowingFullscreen = false;
        dismissedAd.dispose();
        _resumeAudio();
        onDone();
      },
    );
  }

  void _beginShow() {
    _pauseAudio();
    _isShowingFullscreen = true;
    _lastFullscreenAt = DateTime.now();
  }

  Future<void> _grantStar(BuildContext context) async {
    _starCount += 1;
    await AppPreferences.setStarCount(_starCount);
    notifyListeners();
    if (context.mounted) {
      await AdPromptDialog.showStarEarned(context, _starCount);
    }
  }

  void _pauseAudio() => _audio?.setBgmSuspended(true);

  void _resumeAudio() => _audio?.setBgmSuspended(false);

  @override
  void dispose() {
    _appStateSub?.cancel();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
    _appOpenAd?.dispose();
    super.dispose();
  }
}
