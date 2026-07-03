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
    // Play Families tags on Android only — iOS fill drops sharply with child-directed.
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
    final npa = defaultTargetPlatform == TargetPlatform.iOS &&
        _trackingResolved &&
        !_trackingAuthorized;
    return AdRequest(nonPersonalizedAds: npa);
  }
}
