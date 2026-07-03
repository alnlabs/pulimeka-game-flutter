import 'package:shared_preferences/shared_preferences.dart';

/// Last-used names for two-player offline mode on this device.
class OfflinePlayerPrefs {
  OfflinePlayerPrefs._();

  static const _tigerKey = 'offline_tiger_player_name';
  static const _goatKey = 'offline_goat_player_name';

  static const String defaultTigerName = 'Tiger Player';
  static const String defaultGoatName = 'Goat Player';

  static Future<({String tiger, String goat})> getNames() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      tiger: _sanitize(prefs.getString(_tigerKey), defaultTigerName),
      goat: _sanitize(prefs.getString(_goatKey), defaultGoatName),
    );
  }

  static Future<void> setNames({
    required String tiger,
    required String goat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tigerKey, _sanitize(tiger, defaultTigerName));
    await prefs.setString(_goatKey, _sanitize(goat, defaultGoatName));
  }

  static String _sanitize(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;
    return trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed;
  }
}
