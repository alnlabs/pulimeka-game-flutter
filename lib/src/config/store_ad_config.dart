import 'package:flutter/foundation.dart';

import 'admob_ios_prod_config.dart';
import 'admob_prod_config.dart';

/// Ad unit IDs — Android and iOS prod configs in `admob_*_prod_config.dart`.
class StoreAdConfig {
  StoreAdConfig._();

  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId = AdmobProdConfig.rewardedAdUnitIdTest;

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  /// Prod units in Release, or iOS Profile when prod IDs are configured.
  static bool get useProductionAdUnits {
    if (kReleaseMode) return true;
    return _isIos && !kDebugMode && AdmobIosProdConfig.isConfigured;
  }

  static String get bannerAdUnitId {
    const override = String.fromEnvironment('BANNER_AD_UNIT_ID');
    if (override.isNotEmpty) return override;
    if (!useProductionAdUnits) return testBannerAdUnitId;
    if (_isIos && AdmobIosProdConfig.hasBannerAdUnit) {
      return AdmobIosProdConfig.bannerAdUnitId;
    }
    return AdmobProdConfig.bannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    const override = String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID');
    if (override.isNotEmpty) return override;
    if (!useProductionAdUnits) return testInterstitialAdUnitId;
    if (_isIos && AdmobIosProdConfig.hasInterstitialAdUnit) {
      return AdmobIosProdConfig.interstitialAdUnitId;
    }
    if (_isIos) {
      return testInterstitialAdUnitId;
    }
    return AdmobProdConfig.interstitialAdUnitId;
  }

  static String get rewardedAdUnitId {
    const override = String.fromEnvironment('REWARDED_AD_UNIT_ID');
    if (override.isNotEmpty) return override;
    if (useProductionAdUnits) {
      if (_isIos && AdmobIosProdConfig.hasRewardedAdUnit) {
        return AdmobIosProdConfig.rewardedAdUnitId;
      }
      if (!_isIos && AdmobProdConfig.hasRewardedAdUnit) {
        return AdmobProdConfig.rewardedAdUnitId;
      }
    }
    return testRewardedAdUnitId;
  }

  static bool get canUseRewardedAd {
    if (!useProductionAdUnits) return true;
    if (_isIos) return AdmobIosProdConfig.hasRewardedAdUnit;
    return AdmobProdConfig.hasRewardedAdUnit;
  }

  /// Native iOS `GADApplicationIdentifier` — must match `GAD_APPLICATION_ID` in xcconfig.
  static String get admobApplicationId {
    const override = String.fromEnvironment('IOS_ADMOB_APP_ID');
    if (override.isNotEmpty) return override;
    if (_isIos && AdmobIosProdConfig.hasApplicationId) {
      return AdmobIosProdConfig.applicationId;
    }
    return AdmobProdConfig.applicationId;
  }

  static bool get iosProdAdsReady => AdmobIosProdConfig.isConfigured;

  static bool get iosInterstitialAdsReady =>
      AdmobIosProdConfig.hasInterstitialAdUnit;
}
