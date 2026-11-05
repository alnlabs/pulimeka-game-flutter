import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ios_tracking_authorization.dart';

/// Builds [AdRequest] and platform [RequestConfiguration] for AdMob.
class AdRequestHelper {
  AdRequestHelper._();

  static bool _trackingAuthorized = false;
  static bool _trackingResolved = false;

  static bool get trackingAuthorized => _trackingAuthorized;

  /// Call after ATT prompt (iOS) before loading ads.
  static Future<void> refreshTrackingStatus() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || kIsWeb) {
      _trackingResolved = true;
      _trackingAuthorized = true;
      return;
    }
    try {
      final status = await IosTrackingAuthorization.trackingAuthorizationStatus();
      _trackingAuthorized = IosTrackingAuthorization.isAuthorized(status);
      _trackingResolved = true;
      debugPrint('ATT status: $status (ads NPA=${!_trackingAuthorized})');
    } catch (e) {
      debugPrint('ATT status read failed: $e');
      _trackingAuthorized = false;
      _trackingResolved = true;
    }
  }

  static Future<RequestConfiguration> platformRequestConfiguration() async {
    // Play Families: Android requests are child-directed so only G-rated
    // inventory can serve. iOS omits TFCD because fill drops sharply.
    final childDirected = defaultTargetPlatform == TargetPlatform.android
        ? TagForChildDirectedTreatment.yes
        : TagForChildDirectedTreatment.unspecified;
    final underAge = defaultTargetPlatform == TargetPlatform.android
        ? TagForUnderAgeOfConsent.yes
        : TagForUnderAgeOfConsent.unspecified;

    return RequestConfiguration(
      maxAdContentRating: MaxAdContentRating.g,
      tagForChildDirectedTreatment: childDirected,
      tagForUnderAgeOfConsent: underAge,
    );
  }

  static AdRequest build() {
    // Families Policy: child-directed Android traffic must not use
    // personalized ads. iOS still keys NPA off App Tracking Transparency.
    final npa = defaultTargetPlatform == TargetPlatform.android ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            _trackingResolved &&
            !_trackingAuthorized);
    return AdRequest(
      nonPersonalizedAds: npa,
      extras: {'max_ad_content_rating': MaxAdContentRating.g},
    );
  }
}
