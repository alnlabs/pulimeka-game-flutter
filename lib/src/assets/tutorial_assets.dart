/// Pre-rendered board screenshots for the visual tutorial (`assets/tutorial/phases/`).
///
/// Regenerate: `./scripts/capture_board_screenshots.sh`
class TutorialAssets {
  TutorialAssets._();

  static const String _base = 'assets/tutorial/phases';

  static const String opening = '$_base/01-opening.png';
  static const String tigerStarts = '$_base/02-tiger-starts.png';
  static const String tigerMove = '$_base/03-tiger-move.png';
  static const String tigerCapture = '$_base/04-tiger-capture.png';
  static const String goatPlacement = '$_base/05-goat-placement.png';
  static const String goatMove = '$_base/06-goat-move.png';
  static const String goatsWin = '$_base/07-goats-win.png';
  static const String tigersWin = '$_base/08-tigers-win.png';
}
