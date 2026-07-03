import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS ATT via native MethodChannel (avoids the app_tracking_transparency pod).
class IosTrackingAuthorization {
  IosTrackingAuthorization._();

  static const MethodChannel _channel =
      MethodChannel('com.alnlabs.pulimeka/tracking');

  /// Matches [ATTrackingManager.AuthorizationStatus] raw values on iOS.
  static const int authorized = 3;

  static Future<int> trackingAuthorizationStatus() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || kIsWeb) {
      return authorized;
    }
    try {
      final status = await _channel.invokeMethod<int>('getStatus');
      return status ?? 0;
    } catch (e) {
      debugPrint('ATT status read failed: $e');
      return 0;
    }
  }

  static Future<int> requestTrackingAuthorization() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || kIsWeb) {
      return authorized;
    }
    try {
      final status = await _channel.invokeMethod<int>('request');
      return status ?? 0;
    } catch (e) {
      debugPrint('ATT request failed: $e');
      return 0;
    }
  }

  static bool isAuthorized(int status) => status == authorized;
}
