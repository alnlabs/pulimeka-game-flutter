import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ad_load_retry.dart';
import 'ad_config.dart';
import 'ad_request_helper.dart';
import 'ad_service.dart';

/// Preloads and shows full-screen interstitial ads (timed hint unlock).
class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _ad;
  bool _loading = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 6;

  Future<void> preload() async {
    if (!AdConfig.shouldLoadAds ||
        !AdConfig.canLoadInterstitial ||
        _loading ||
        _ad != null) {
      return;
    }

    await AdService.ensureInitialized();
    _loading = true;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: AdRequestHelper.build(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          _retryAttempt = 0;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              preload();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                'Interstitial show failed (${error.code}): ${error.message}',
              );
              ad.dispose();
              _ad = null;
              preload();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            'Interstitial load failed (${error.code}): ${error.message}',
          );
          _loading = false;
          _scheduleRetry();
        },
      ),
    );
  }

  void _scheduleRetry() {
    _retryAttempt++;
    if (_retryAttempt > _maxRetries) return;
    Future<void>.delayed(adRetryDelay(_retryAttempt), preload);
  }

  /// Returns true if an interstitial was shown.
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null) {
      preload();
      return false;
    }
    _ad = null;
    await ad.show();
    preload();
    return true;
  }

  bool get isReady => _ad != null;
}
