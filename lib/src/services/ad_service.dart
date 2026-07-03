import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/store_ad_config.dart';
import 'ad_config.dart';
import 'ad_request_helper.dart';
import 'interstitial_ad_manager.dart';
import 'ios_tracking_authorization.dart';
import 'rewarded_ad_manager.dart';

/// Initializes AdMob and preloads full-screen formats (Android `AdManager.initialize`).
class AdService {
  AdService._();

  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  /// Completes after [MobileAds.instance.initialize] (safe to await before loading).
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;
    return initialize();
  }

  static Future<void> initialize() async {
    if (_initialized || kIsWeb || !AdConfig.shouldShowAds) {
      return;
    }
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    try {
      await _requestTrackingAuthorizationIfNeeded();
      await AdRequestHelper.refreshTrackingStatus();

      await MobileAds.instance.updateRequestConfiguration(
        await AdRequestHelper.platformRequestConfiguration(),
      );

      final initStatus = await MobileAds.instance.initialize();
      for (final entry in initStatus.adapterStatuses.entries) {
        debugPrint(
          'AdMob adapter ${entry.key}: ${entry.value.state} '
          '${entry.value.description}',
        );
      }
      _initialized = true;

      if (AdConfig.shouldLoadAds) {
        debugPrint(
          'AdMob units (prod=${StoreAdConfig.useProductionAdUnits}): '
          'banner=${AdConfig.bannerAdUnitId} '
          'interstitial=${AdConfig.interstitialAdUnitId} '
          'rewarded=${AdConfig.rewardedAdUnitId}',
        );
        InterstitialAdManager.instance.preload();
        RewardedAdManager.instance.preload();
      }

      _initCompleter!.complete();
    } catch (e, stack) {
      debugPrint('AdMob initialize failed: $e\n$stack');
      _initCompleter!.completeError(e, stack);
      _initCompleter = null;
      rethrow;
    }
  }

  static Future<void> _requestTrackingAuthorizationIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || kIsWeb) {
      return;
    }
    try {
      var status = await IosTrackingAuthorization.trackingAuthorizationStatus();
      if (status == 0) {
        status = await IosTrackingAuthorization.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('ATT request skipped: $e');
    }
  }

  static void preloadHintAds() {
    if (!AdConfig.shouldLoadAds) {
      return;
    }
    InterstitialAdManager.instance.preload();
    RewardedAdManager.instance.preload();
  }
}
