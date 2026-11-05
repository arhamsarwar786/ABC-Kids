import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ad_constants.dart';
import '../../../core/design/tokens.dart';
import '../../../core/services/ads_service.dart';

/// The single banner on the browse tabs, built to Google Play Families rules:
/// one standard 320×50 banner, clearly labelled “Advertisement”, set apart in
/// its own card with space between it and the tab bar so it is not where
/// children tap for other things. Child-directed, G-rated, non-personalised
/// requests (see [AdsService]). Collapses to nothing until an ad has loaded.
class KidSafeBanner extends StatefulWidget {
  const KidSafeBanner({super.key});

  @override
  State<KidSafeBanner> createState() => _KidSafeBannerState();
}

class _KidSafeBannerState extends State<KidSafeBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ads = context.watch<AdsService>();
    if (!_requested && ads.ready && ads.policy.childBanners) {
      _requested = true;
      _ad = BannerAd(
        size: AdSize.banner,
        adUnitId: AdConstants.bannerAdUnitId,
        request: AdsService.childRequest,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner failed to load: $error');
            ad.dispose();
            _ad = null;
            // Try again on a later visit rather than retrying in a loop.
            if (mounted) setState(() => _requested = false);
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final show = _loaded && ad != null;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              // Clear gap above the tab bar so ad taps can't be mistaken for tab taps.
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                  decoration: BoxDecoration(
                    color: AppTokens.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTokens.outline, width: 1.5),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Advertisement',
                        textScaler: TextScaler.noScaling,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppTokens.navyMuted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad)),
                  ]),
                ),
              ),
            ),
    );
  }
}
