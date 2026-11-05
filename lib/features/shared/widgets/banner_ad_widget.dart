import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/ad_constants.dart';
import '../../../core/services/ads_service.dart';

/// Anchored adaptive banner for the bottom of a [Scaffold].
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isLoaded) return;
    _isLoading = true;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) {
      _isLoading = false;
      return;
    }

    setState(() => _adSize = size);

    final bannerAd = BannerAd(
      size: size,
      adUnitId: AdConstants.bannerAdUnitId,
      request: AdsService.childRequest,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _adSize = null;
              _isLoading = false;
            });
          }
        },
      ),
    );

    await bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adSize = _adSize;
    if (adSize == null) {
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: adSize.width.toDouble(),
          height: adSize.height.toDouble(),
          child: _isLoaded && _bannerAd != null ? AdWidget(ad: _bannerAd!) : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
