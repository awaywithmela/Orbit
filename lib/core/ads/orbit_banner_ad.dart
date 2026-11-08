import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_consent_service.dart';

/// Development banner. Replace the test unit IDs before release.
class OrbitBannerAd extends StatefulWidget {
  const OrbitBannerAd({super.key});

  @override
  State<OrbitBannerAd> createState() => _OrbitBannerAdState();
}

class _OrbitBannerAdState extends State<OrbitBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  static const _androidTestUnit = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosTestUnit = 'ca-app-pub-3940256099942544/2934735716';

  String get _unitId => switch (Theme.of(context).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => _iosTestUnit,
    _ => _androidTestUnit,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (!mounted || !AdsConsentService.adsReady) return;
    final ad = BannerAd(
      adUnitId: _unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _ad = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
