import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/ios_store_config.dart';

class ExternalLinks {
  ExternalLinks._();

  /// Published Play Store application id (puli-meka-game-android).
  static const String playStoreApplicationId = 'com.alnlabs.pulimekagame';

  /// Public privacy policy (App Store / Play Store).
  static const String privacyPolicyUrl =
      'https://alnlabs.com/puli-meka/privacy-policy';

  static const _youtubeTutorial =
      'https://www.youtube.com/results?search_query=puli+meka+game+tutorial';
  static const websiteUrl = 'https://alnlabs.com';

  static Future<void> openPrivacyPolicy() => _open(privacyPolicyUrl);

  static Future<void> openYouTubeTutorial() => _open(_youtubeTutorial);

  static Future<void> openWebsite() => _open(websiteUrl);

  /// Kept for older call sites; opens ALN Labs site.
  static Future<void> openLinkedIn() => openWebsite();

  /// Play Store / App Store listing (Android rate-on-exit flow).
  static Future<void> openAppStoreListing() async {
    if (kIsWeb) return;
    try {
      final info = await PackageInfo.fromPlatform();
      if (Platform.isAndroid) {
        final packageId = info.packageName.contains('pulimekagame')
            ? info.packageName
            : playStoreApplicationId;
        final market = Uri.parse('market://details?id=$packageId');
        if (await canLaunchUrl(market)) {
          await launchUrl(market);
          return;
        }
        await _open(
          'https://play.google.com/store/apps/details?id=$packageId',
        );
        return;
      }
      if (Platform.isIOS) {
        final review = Uri.parse(IosStoreConfig.appStoreReviewUrl);
        if (await canLaunchUrl(review)) {
          await launchUrl(review, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}
  }

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
