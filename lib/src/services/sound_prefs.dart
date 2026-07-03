import 'package:shared_preferences/shared_preferences.dart';

class SoundPrefs {
  SoundPrefs._();

  static const _enabledKey = 'sound_enabled';
  static const _volumeKey = 'volume';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<double> volume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_volumeKey) ?? 1.0;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  static Future<void> setVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, value.clamp(0.0, 1.0));
  }
}
