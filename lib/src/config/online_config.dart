import 'package:flutter/foundation.dart';

/// Firebase RTDB paths — aligned with Android `BuildConfig.DB_PREFIX`.
class OnlineConfig {
  OnlineConfig._();

  static const String dbPrefix = String.fromEnvironment(
    'DB_PREFIX',
    defaultValue: kDebugMode ? 'test_' : 'prod_',
  );

  static String get roomsPath => '${dbPrefix}rooms';
  static String get gamesPath => '${dbPrefix}games';

  static const int waitingRoomTtlMs = 10 * 60 * 1000;
}
