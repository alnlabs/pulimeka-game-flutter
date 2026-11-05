import 'dart:async';

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
              if (identical(_ad, ad)) _ad = null;
              preload();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                'Interstitial show failed (${error.code}): ${error.message}',
              );
              ad.dispose();
              if (identical(_ad, ad)) _ad = null;
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

  /// Shows an interstitial and completes only after it is dismissed.
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null) {
      preload();
      return false;
    }
    _ad = null;
    final done = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
          'Interstitial show failed (${error.code}): ${error.message}',
        );
        ad.dispose();
        preload();
        if (!done.isCompleted) done.complete(false);
      },
    );

    try {
      await ad.show();
    } catch (e, stack) {
      debugPrint('Interstitial show threw: $e\n$stack');
      ad.dispose();
      preload();
      if (!done.isCompleted) done.complete(false);
    }
    return done.future;
  }

  bool get isReady => _ad != null;
}
