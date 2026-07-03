/// Hint economy: tutorial games → free bank → batches of hints per ad.
class HintPolicy {
  HintPolicy._();

  /// First N completed games show automatic placement / turn hints.
  static const int tutorialGames = 3;

  /// Hints granted once tutorial ends (persisted).
  static const int freeHintsAfterTutorial = 5;

  /// After free hints, each ad unlocks this many hints.
  static const int hintsPerAdBatch = 3;

  /// Countdown before skip on timed hint unlock ad.
  static const int timedAdSkipSeconds = 5;
}
