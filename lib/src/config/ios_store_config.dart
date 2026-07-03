/// Optional iOS App Store id for deep links (set in source or `--dart-define=APP_STORE_ID=...`).
class IosStoreConfig {
  IosStoreConfig._();

  /// Numeric App Store id (e.g. 1234567890), not bundle id.
  static const String appStoreId = String.fromEnvironment(
    'APP_STORE_ID',
    defaultValue: '',
  );

  static const String _admobAppId = String.fromEnvironment(
    'IOS_ADMOB_APP_ID',
    defaultValue: '',
  );

  static bool get hasAppStoreId =>
      appStoreId.isNotEmpty && RegExp(r'^\d+$').hasMatch(appStoreId);

  static String get appStoreListingUrl {
    if (hasAppStoreId) {
      return 'https://apps.apple.com/app/id$appStoreId';
    }
    return 'https://apps.apple.com/search?term=puli+meka';
  }

  static String get appStoreReviewUrl {
    if (hasAppStoreId) {
      return 'https://apps.apple.com/app/id$appStoreId?action=write-review';
    }
    return appStoreListingUrl;
  }

  static bool get hasIosAdMobAppId => _admobAppId.isNotEmpty;
}
