/// Production AdMob IDs for **Android** (`com.alnlabs.pulimekagame`).
/// iOS: `admob_ios_prod_config.dart`. Edit here if the Android AdMob config changes.
class AdmobProdConfig {
  AdmobProdConfig._();

  /// `AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
  static const String applicationId = 'ca-app-pub-5227558935673781~6530756504';

  /// `app/env/prod/BANNER_AD_UNIT_ID`
  static const String bannerAdUnitId = 'ca-app-pub-5227558935673781/8457225467';

  /// `app/env/prod/INTERSTITIAL_AD_UNIT_ID`
  static const String interstitialAdUnitId =
      'ca-app-pub-5227558935673781/3600199191';

  /// Rewarded (hint unlock) — AdMob unit "Hint unlock" / rewarded.
  static const String rewardedAdUnitId =
      'ca-app-pub-5227558935673781/2017436045';

  static bool get hasRewardedAdUnit => rewardedAdUnitId.isNotEmpty;

  /// Google sample rewarded unit (debug / profile only).
  static const String rewardedAdUnitIdTest =
      'ca-app-pub-3940256099942544/5224354917';
}
