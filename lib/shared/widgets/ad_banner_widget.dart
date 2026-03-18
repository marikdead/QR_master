import 'package:apphud/apphud.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/ad_constants.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  late final Future<bool> _isPremiumFuture;

  @override
  void initState() {
    super.initState();
    _isPremiumFuture = Apphud.hasPremiumAccess();
    _loadBanner();
  }

  void _loadBanner() {
    final banner = BannerAd(
      adUnitId: AdConstants.bannerId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
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
          ad.dispose();
          _isLoaded = false;
          Future<void>.delayed(const Duration(seconds: 60), _loadBanner);
        },
      ),
    );
    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isPremiumFuture,
      builder: (context, snapshot) {
        final isPremium = snapshot.data == true;
        if (isPremium) return const SizedBox.shrink();

        // Placeholder нужной высоты чтобы layout не прыгал при загрузке
        if (!_isLoaded || _bannerAd == null) return const SizedBox(height: 50);

        return SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        );
      },
    );
  }
}

