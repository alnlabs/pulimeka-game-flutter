import 'dart:math';

/// Exponential backoff for transient AdMob no-fill / network errors.
Duration adRetryDelay(int attempt, {int baseSeconds = 2, int maxSeconds = 60}) {
  final capped = min(attempt, 6);
  final seconds = min(maxSeconds, baseSeconds * pow(2, capped - 1).toInt());
  return Duration(seconds: seconds);
}
