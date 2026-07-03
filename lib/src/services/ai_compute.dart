import '../models/ai_difficulty.dart';
import '../models/ai_move.dart';
import '../models/game_state.dart';
import 'ai_service.dart';

/// Payload for [compute] — runs minimax off the UI thread.
class AiComputeRequest {
  const AiComputeRequest({
    required this.state,
    required this.turn,
    required this.difficulty,
  });

  final GameState state;
  final PieceType turn;
  final AiDifficulty difficulty;
}

/// Top-level entry point for Flutter [compute].
AiMove? aiComputeMove(AiComputeRequest request) {
  final ai = AiService(difficulty: request.difficulty);
  if (request.turn == PieceType.tiger) {
    return ai.chooseTigerMove(request.state);
  }
  return ai.chooseGoatMove(request.state);
}
