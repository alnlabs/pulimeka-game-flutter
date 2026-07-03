import '../models/ai_difficulty.dart';
import '../models/ai_move.dart';
import '../models/game_state.dart';
import 'ai_service.dart';

class MoveHint {
  const MoveHint({
    required this.message,
    this.from,
    this.to,
  });

  final String message;
  final String? from;
  final String? to;

  bool get isPlacement => from == null && to != null;
}

/// Best-move hints using the same minimax as Hard AI (no random moves).
class MoveHintCalculator {
  MoveHintCalculator({AiService? aiService})
      : _ai = aiService ?? AiService(difficulty: AiDifficulty.hard);

  final AiService _ai;

  MoveHint? suggest(GameState state) {
    if (state.winner != null) {
      return null;
    }

    final AiMove? best;
    if (state.currentTurn == PieceType.tiger) {
      best = _ai.chooseTigerMove(state);
    } else if (state.currentTurn == PieceType.goat) {
      best = _ai.chooseGoatMove(state);
    } else {
      return null;
    }

    return _toMoveHint(best, state.currentTurn);
  }

  MoveHint? _toMoveHint(AiMove? move, PieceType role) {
    if (move == null) {
      return null;
    }

    if (move.isPlacement) {
      return MoveHint(
        message: 'Place a goat on the highlighted dot.',
        to: move.placement,
      );
    }

    if (role == PieceType.tiger) {
      return MoveHint(
        message: move.isJump
            ? 'Jump to capture the highlighted goat.'
            : 'Move the selected tiger to the highlighted node.',
        from: move.from,
        to: move.target,
      );
    }

    return MoveHint(
      message: 'Move the selected goat to the highlighted node.',
      from: move.from,
      to: move.target,
    );
  }
}
