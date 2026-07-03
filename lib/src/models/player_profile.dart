/// Snapshot for profile / hint UI.
class PlayerProfile {
  const PlayerProfile({
    required this.firstPlayDate,
    required this.gamesCompleted,
    required this.totalHintsUsed,
    required this.freeHintsRemaining,
    required this.batchHintsRemaining,
    required this.isTutorialPhase,
    required this.hintPhaseLabel,
    required this.hintCountSummary,
  });

  final DateTime? firstPlayDate;
  final int gamesCompleted;
  final int totalHintsUsed;
  final int freeHintsRemaining;
  final int batchHintsRemaining;
  final bool isTutorialPhase;
  final String hintPhaseLabel;
  final String hintCountSummary;
}
