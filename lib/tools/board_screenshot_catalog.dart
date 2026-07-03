import 'package:puli_meka_game_flutter/src/controllers/game_controller.dart';
import 'package:puli_meka_game_flutter/src/tutorial/tutorial_snapshots.dart';

/// Fixed board states for each gameplay phase — used by tutorial and screenshot tool.
class BoardScreenshotCatalog {
  BoardScreenshotCatalog._();

  static List<BoardScreenshotPhase> get phases => [
        BoardScreenshotPhase(
          id: '01-opening',
          title: 'Opening position',
          subtitle: '2 tigers · 4 goats on board',
          ui: TutorialSnapshots.opening,
        ),
        BoardScreenshotPhase(
          id: '02-tiger-starts',
          title: 'Tigers move first',
          subtitle: "Tiger player's opening turn",
          ui: TutorialSnapshots.tigerStarts,
        ),
        BoardScreenshotPhase(
          id: '03-tiger-move',
          title: 'Tiger movement',
          subtitle: 'Move along a line to highlighted node',
          ui: TutorialSnapshots.tigerMove,
        ),
        BoardScreenshotPhase(
          id: '04-tiger-capture',
          title: 'Tiger capture',
          subtitle: 'Jump over a goat to capture',
          ui: TutorialSnapshots.tigerCapture ?? TutorialSnapshots.tigerCaptureDemo,
        ),
        BoardScreenshotPhase(
          id: '05-goat-placement',
          title: 'Goat placement',
          subtitle: 'Place goats on empty points',
          ui: TutorialSnapshots.goatPlacement,
        ),
        BoardScreenshotPhase(
          id: '06-goat-move',
          title: 'Goat movement',
          subtitle: 'Slide one step after all goats placed',
          ui: TutorialSnapshots.goatMove,
        ),
        BoardScreenshotPhase(
          id: '07-goats-win',
          title: 'Goats win',
          subtitle: 'All tigers trapped',
          ui: TutorialSnapshots.goatsWin,
        ),
        BoardScreenshotPhase(
          id: '08-tigers-win',
          title: 'Tigers win',
          subtitle: '12 goats captured',
          ui: TutorialSnapshots.tigersWin,
        ),
      ];
}

class BoardScreenshotPhase {
  const BoardScreenshotPhase({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ui,
  });

  final String id;
  final String title;
  final String subtitle;
  final UiGameState ui;

  String get filename => '$id.png';
}
