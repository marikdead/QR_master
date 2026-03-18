import 'package:apphud/apphud.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_constants.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  bool _initialized = false;

  // Инициализация — вызвать один раз до runApp
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdConstants.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialReady = false;
          Future<void>.delayed(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  // Показать межстраничную если готова и пользователь не Premium
  Future<void> showInterstitialIfReady() async {
    final isPremium = await Apphud.hasPremiumAccess();
    if (isPremium) return;

    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;
  }
}

