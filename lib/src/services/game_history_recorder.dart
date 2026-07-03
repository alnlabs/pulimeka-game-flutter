import '../models/game_result.dart';
import 'history_service.dart';

/// Saves match results and updates leaderboard (Android `GameHistoryManager`).
class GameHistoryRecorder {
  GameHistoryRecorder._();
  static final GameHistoryRecorder instance = GameHistoryRecorder._();

  final HistoryService _history = HistoryService();

  Future<void> recordMatch({
    required String playerName,
    required String mode,
    required bool humanWon,
    String? opponentName,
    int capturedGoats = 0,
    int goatsPlaced = 0,
    bool isDraw = false,
  }) async {
    final name = playerName.trim().isEmpty ? 'Player' : playerName.trim();
    final winner = isDraw
        ? 'draw'
        : humanWon
            ? name
            : (opponentName?.trim().isEmpty ?? true)
                ? 'opponent'
                : opponentName!.trim();

    await _history.saveResult(
      GameResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mode: mode,
        winner: winner,
        capturedGoats: capturedGoats,
        goatsPlaced: goatsPlaced,
        playedAt: DateTime.now(),
      ),
      playerName: name,
      humanWon: humanWon,
      isDraw: isDraw,
    );
  }
}
