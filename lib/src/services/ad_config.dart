import 'package:flutter/foundation.dart';

import '../config/store_ad_config.dart';

/// Mirrors Android `AdConfig` / `AdManager` ad unit IDs.
class AdConfig {
  AdConfig._();

  /// Set via `--dart-define=HIDE_ADS=true` to match Android `HIDE_ADS` build flag.
  static const bool hideAds = bool.fromEnvironment('HIDE_ADS', defaultValue: false);

  static bool adsEnabled = true;

  static bool get shouldShowAds => !hideAds && adsEnabled;

  /// Whether the app should request ad fills from the network.
  ///
  /// iOS Debug uses Google test units (matches `Debug.xcconfig` test app id).
  /// iOS Profile/Release uses prod units from [AdmobIosProdConfig].
  static bool get shouldLoadAds {
    if (!shouldShowAds || kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (kDebugMode) return true;
      return StoreAdConfig.iosProdAdsReady;
    }
    return true;
  }

  /// True when prod (non-test) ad unit IDs are active.
  static bool get shouldRequestLiveAds => shouldLoadAds && StoreAdConfig.useProductionAdUnits;

  static String get bannerAdUnitId => StoreAdConfig.bannerAdUnitId;

  static String get interstitialAdUnitId => StoreAdConfig.interstitialAdUnitId;

  static String get rewardedAdUnitId => StoreAdConfig.rewardedAdUnitId;

  /// False in release until `AdmobProdConfig.rewardedAdUnitId` is set.
  static bool get canUseRewardedAd => StoreAdConfig.canUseRewardedAd;

  /// iOS release interstitials only after an iOS interstitial unit is added in AdMob.
  static bool get canLoadInterstitial {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        !kDebugMode &&
        StoreAdConfig.useProductionAdUnits) {
      return StoreAdConfig.iosInterstitialAdsReady;
    }
    return true;
  }

  static const double bannerHeight = 50;

  /// Post-game interstitial skip delay (Android completion overlay ~8–12s).
  static const int completionAdSkipSeconds = 8;
}
