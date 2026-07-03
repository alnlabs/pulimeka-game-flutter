import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ad_load_retry.dart';
import 'ad_config.dart';
import 'ad_request_helper.dart';
import 'ad_service.dart';

/// Rewarded video for hint unlock.
class RewardedAdManager {
  RewardedAdManager._();

  static final RewardedAdManager instance = RewardedAdManager._();

  RewardedAd? _ad;
  bool _loading = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 6;

  Future<void> preload() async {
    if (!AdConfig.shouldLoadAds ||
        !AdConfig.canUseRewardedAd ||
        _loading ||
        _ad != null) {
      return;
    }

    await AdService.ensureInitialized();
    _loading = true;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: AdRequestHelper.build(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
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
                'Rewarded show failed (${error.code}): ${error.message}',
              );
              ad.dispose();
              _ad = null;
              preload();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            'Rewarded load failed (${error.code}): ${error.message}',
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

  /// Shows rewarded ad; [onReward] when user earns reward. Completes when dismissed.
  Future<bool> show({required VoidCallback onReward}) async {
    final ad = _ad;
    if (ad == null) {
      preload();
      return false;
    }
    _ad = null;
    var rewarded = false;
    final done = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        if (!done.isCompleted) {
          done.complete(rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
          'Rewarded show failed (${error.code}): ${error.message}',
        );
        ad.dispose();
        preload();
        if (!done.isCompleted) {
          done.complete(false);
        }
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        onReward();
      },
    );
    return done.future;
  }

  bool get isReady => _ad != null;
}
