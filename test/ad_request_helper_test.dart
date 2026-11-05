import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:puli_meka_game_flutter/src/services/ad_config.dart';
import 'package:puli_meka_game_flutter/src/services/ad_request_helper.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('Android ad requests ask for G-rated, non-personalized inventory',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final config = await AdRequestHelper.platformRequestConfiguration();
    expect(config.maxAdContentRating, MaxAdContentRating.g);
    expect(
      config.tagForChildDirectedTreatment,
      TagForChildDirectedTreatment.yes,
    );
    expect(config.tagForUnderAgeOfConsent, TagForUnderAgeOfConsent.yes);

    final request = AdRequestHelper.build();
    expect(request.nonPersonalizedAds, isTrue);
    expect(request.extras?['max_ad_content_rating'], MaxAdContentRating.g);
  });

  test('Android does not allow rewarded or interstitial ads', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AdConfig.allowFullScreenAds, isFalse);
    expect(AdConfig.canUseRewardedAd, isFalse);
    expect(AdConfig.canLoadInterstitial, isFalse);
  });
}
