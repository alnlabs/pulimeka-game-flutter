import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sound_prefs.dart';

/// Game SFX via native AVAudioPlayer / SoundPool (no audioplayers pod on iOS).
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const MethodChannel _channel =
      MethodChannel('com.alnlabs.pulimeka/sounds');

  bool enabled = true;
  double volume = 1.0;

  Future<void> loadFromPrefs() async {
    enabled = await SoundPrefs.isEnabled();
    volume = await SoundPrefs.volume();
    await _syncVolume();
  }

  Future<void> updateVolume(double value) async {
    volume = value;
    await _syncVolume();
  }

  Future<void> playClick() => _play('assets/sounds/click.mp3');
  Future<void> playMove() => _play('assets/sounds/move.mp3');
  Future<void> playCapture() => _play('assets/sounds/capture.mp3');

  Future<void> _syncVolume() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setVolume', volume);
    } catch (_) {}
  }

  Future<void> _play(String assetPath) async {
    if (!enabled || kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('play', {
        'asset': assetPath,
        'volume': volume,
      });
    } catch (_) {}
  }
}
