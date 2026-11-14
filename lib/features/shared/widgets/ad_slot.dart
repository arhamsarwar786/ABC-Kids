import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ad_constants.dart';
import '../../../core/design/tokens.dart';
import '../../../core/services/ads_service.dart';

/// Tells the app-wide bottom strip (see AdFrame) whether the tab shell is the
/// screen on top. The shell docks its own banner directly above its tab bar,
/// so the strip steps aside there and there is never a second banner below.
class AdRouteTracker extends NavigatorObserver with ChangeNotifier {
  final List<Route<dynamic>> _pages = [];
  Route<dynamic>? _shell;
  bool _scheduled = false;
  bool _disposed = false;

  bool get shellOnTop => _shell != null && _pages.isNotEmpty && identical(_pages.last, _shell);

  void registerShell(Route<dynamic>? route) {
    if (identical(_shell, route)) return;
    _shell = route;
    _notify();
  }

  void unregisterShell(Route<dynamic> route) {
    if (identical(_shell, route)) {
      _shell = null;
      _notify();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _pages.add(route);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _pages.remove(oldRoute);
    if (newRoute is PageRoute) _pages.add(newRoute);
    _notify();
  }

  void _notify() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_disposed) notifyListeners();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Loads banners one at a time, starting only after the app has had a moment
/// to become interactive. Creating several ad WebViews at once can freeze the
/// UI thread on low-end phones (Android reports "not responding").
class _LoadQueue {
  static Future<void> _tail = Future<void>.delayed(const Duration(milliseconds: 1800));

  static Future<void> enqueue(Future<void> Function() job) {
    final run = _tail.then((_) => job()).catchError((Object _) {});
    _tail = run.then((_) => Future<void>.delayed(const Duration(milliseconds: 900)));
    return run;
  }
}

enum BannerStyle {
  /// Full-width white strip with a hairline on top (bottom of a screen or
  /// directly above the tab bar).
  strip,

}

/// One banner ad placement. Every request is child-directed, G-rated and
/// non-personalised (see [AdsService]); the banner is always labelled
/// "Advertisement" and takes no space until an ad has loaded, so there is
/// never an empty box.
///
/// A slot only requests an ad once it is actually on screen: hidden tabs and
/// screens covered by another route do not load anything, so launching the app
/// does not fire off a burst of requests.
class BannerSlot extends StatefulWidget {
  final BannerStyle style;

  /// False keeps the slot idle (no request) until it becomes true.
  final bool active;

  /// Extra space under a [BannerStyle.strip] (the system navigation inset).
  final double bottomInset;

  /// Reports whether an ad is currently showing.
  final ValueChanged<bool>? onLoadedChanged;

  const BannerSlot({super.key, this.style = BannerStyle.strip, this.active = true, this.bottomInset = 0, this.onLoadedChanged});

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  static const _retryDelays = [Duration(seconds: 20), Duration(seconds: 60), Duration(minutes: 3)];

  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;
  int _attempt = 0;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    // Make sure the SDK is starting (idempotent) even if nothing else did.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ads = context.read<AdsService>();
      if (ads.policy.childBanners) ads.ensureStarted();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.watch<AdsService>();
    _maybeLoad();
  }

  @override
  void didUpdateWidget(BannerSlot old) {
    super.didUpdateWidget(old);
    _maybeLoad();
  }

  void _setLoaded(bool v) {
    if (_loaded == v) return;
    _loaded = v;
    widget.onLoadedChanged?.call(v);
  }

  Future<void> _maybeLoad() async {
    final ads = context.read<AdsService>();
    if (_requested || !widget.active || !ads.ready || !ads.policy.childBanners) return;
    // Hidden tabs and covered routes have tickers off: wait until visible.
    if (!TickerMode.of(context)) return;
    _requested = true;
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width.truncate();
    final orientation = MediaQuery.orientationOf(context);
    // ignore: deprecated_member_use  (the "large" variant is too tall for a kids UI)
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(orientation, width);
    if (!mounted) return;
    if (size == null) {
      _requested = false;
      return;
    }
    final done = Completer<void>();
    await _LoadQueue.enqueue(() async {
      if (!mounted) return;
      _ad = BannerAd(
        size: size,
        adUnitId: AdConstants.bannerAdUnitId,
        request: AdsService.childRequest,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            _attempt = 0;
            if (mounted) setState(() => _setLoaded(true));
            if (!done.isCompleted) done.complete();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner failed to load: $error');
            ad.dispose();
            _ad = null;
            if (!done.isCompleted) done.complete();
            if (!mounted) return;
            setState(() => _setLoaded(false));
            // Back off instead of hammering the ad server; give up after a few tries.
            if (_attempt < _retryDelays.length) {
              _retry?.cancel();
              _retry = Timer(_retryDelays[_attempt++], () {
                _requested = false;
                if (mounted) _maybeLoad();
              });
            }
          },
        ),
      )..load();
      await done.future.timeout(const Duration(seconds: 12), onTimeout: () {});
    });
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox(width: double.infinity);
    final label = Text('Advertisement',
        textScaler: TextScaler.noScaling,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 9, height: 1.2, color: AppTokens.navyMuted, fontWeight: FontWeight.w700));
    final adBox = SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad));

    return ColoredBox(
        color: Colors.white,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Divider(height: 1, thickness: 1, color: AppTokens.outline),
          Padding(padding: const EdgeInsets.only(top: 2), child: label),
          adBox,
          SizedBox(height: widget.bottomInset),
        ]),
      );
  }
}
