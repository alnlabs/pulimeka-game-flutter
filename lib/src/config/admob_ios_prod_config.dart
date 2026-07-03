/// Production AdMob IDs for iOS (`com.alnlabs.pulimeka`).
///
/// Create an **iOS** app in AdMob (separate from Android), then paste IDs here and in
/// `ios/Flutter/Release.xcconfig` + `Profile.xcconfig` (`GAD_APPLICATION_ID`).
/// Steps: `docs/ADMOB_IOS_UNITS.md`
class AdmobIosProdConfig {
  AdmobIosProdConfig._();

  /// AdMob → Apps → Puli Meka (iOS) → App settings → App ID (`~` suffix).
  static const String applicationId = 'ca-app-pub-5227558935673781~4570923137';

  /// Ad units → Banner (iOS).
  static const String bannerAdUnitId = 'ca-app-pub-5227558935673781/9140561834';

  /// Ad units → Interstitial (iOS).
  static const String interstitialAdUnitId =
      'ca-app-pub-5227558935673781/6715532874';

  /// Ad units → Rewarded (iOS), e.g. hint unlock.
  static const String rewardedAdUnitId =
      'ca-app-pub-5227558935673781/5402451204';

  static bool get hasApplicationId => applicationId.isNotEmpty;

  static bool get hasBannerAdUnit => bannerAdUnitId.isNotEmpty;

  static bool get hasInterstitialAdUnit => interstitialAdUnitId.isNotEmpty;

  static bool get hasRewardedAdUnit => rewardedAdUnitId.isNotEmpty;

  /// App id + banner — enough for home banner on iOS release.
  static bool get isConfigured => hasApplicationId && hasBannerAdUnit;

  /// Interstitial / timed ads need a separate iOS interstitial unit.
  static bool get hasFullAdSuite =>
      isConfigured && hasInterstitialAdUnit;
}
