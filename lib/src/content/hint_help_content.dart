import '../models/hint_policy.dart';

/// Shared copy for How to Play / About regarding the hint system.
class HintHelpContent {
  HintHelpContent._();

  static const String sectionTitle = 'Hints & help during play';

  static String get intro =>
      'Tap the light bulb on the game screen when you want a suggested move. '
      'How hints work depends on how many games you have finished.';

  static List<String> get bullets => [
    'Tutorial (first ${HintPolicy.tutorialGames} completed games): '
        'placement tips and green dots on the board are shown automatically. '
        'The hint button is free and unlimited.',
    'After tutorial: you receive ${HintPolicy.freeHintsAfterTutorial} free hints. '
        'Automatic board tips are turned off — use the hint button when you need help.',
    'When free hints are used up: tap the hint button to unlock '
        '${HintPolicy.hintsPerAdBatch} more hints. On some platforms this may '
        'use an optional short ad.',
    'A hint highlights suggested nodes in gold and shows a short message at the top of the board. '
        'You still make the move yourself.',
    'In Play with AI, hints are only available on your turn.',
  ];
}
