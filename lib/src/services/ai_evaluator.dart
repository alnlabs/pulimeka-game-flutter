import '../models/ai_move.dart';
import '../models/game_state.dart';

/// Board evaluation and move generation for minimax (Android `AIEvaluator`).
class AiEvaluator {
  static int evaluate(GameState state, PieceType aiRole) {
    if (aiRole == PieceType.tiger) {
      if (!state.winByTrapOnly &&
          state.capturedGoats >= state.goatsToCaptureForTigerWin) {
        return 10000;
      }
      if (state.areTigersTrapped()) {
        return -10000;
      }
    } else {
      if (state.areTigersTrapped()) {
        return 10000;
      }
      if (!state.winByTrapOnly &&
          state.capturedGoats >= state.goatsToCaptureForTigerWin) {
        return -10000;
      }
    }

    var score = 0;
    final nodes = state.board.allNodes;
    if (aiRole == PieceType.tiger) {
      score += state.capturedGoats * 500;
      var totalTigerMoves = 0;
      var captureMoves = 0;
      for (final node in nodes) {
        if (state.pieceAt(node) != PieceType.tiger) continue;
        final moves = state.getTigerMoves(node);
        totalTigerMoves += moves.length;
        captureMoves += moves.where((m) => m.isJump).length;
      }
      score += totalTigerMoves * 10;
      score += captureMoves * 100;
      if (totalTigerMoves == 0) {
        score -= 5000;
      } else if (totalTigerMoves <= 2) {
        score -= 200;
      }
      for (final node in nodes) {
        if (state.pieceAt(node) == PieceType.tiger && _isCentral(state, node)) {
          score += 20;
        }
      }
    } else {
      var totalTigerMoves = 0;
      for (final node in nodes) {
        if (state.pieceAt(node) == PieceType.tiger) {
          totalTigerMoves += state.getTigerMoves(node).length;
        }
      }
      score -= totalTigerMoves * 100;
      if (totalTigerMoves == 0) score += 5000;
      score -= state.capturedGoats * 300;

      var blockingGoats = 0;
      for (final node in nodes) {
        if (state.pieceAt(node) != PieceType.tiger) continue;
        for (final move in state.getTigerMoves(node)) {
          if (move.jumped != null &&
              state.pieceAt(move.jumped!) == PieceType.goat) {
            blockingGoats++;
          }
        }
      }
      score += blockingGoats * 50;

      var totalGoatMoves = 0;
      for (final node in nodes) {
        if (state.pieceAt(node) == PieceType.goat) {
          totalGoatMoves += state.getGoatMoves(node).length;
        }
      }
      score += totalGoatMoves * 5;
      for (final node in nodes) {
        if (state.pieceAt(node) == PieceType.goat && _isCentral(state, node)) {
          score += 10;
        }
      }
    }
    return score;
  }

  static bool _isCentral(GameState state, String node) {
    final coord = state.board.nodeCoord(node);
    if (coord == null) return false;
    final midRow = state.board.maxRow / 2;
    final midCol = state.board.maxCol / 2;
    return (coord.row - midRow).abs() <= 1 && (coord.col - midCol).abs() <= 1;
  }

  /// Mirrors Android `getAllPossibleMoves` for the active player [role].
  static List<AiMove> movesForRole(GameState state, PieceType role) {
    if (state.winner != null) return [];
    if (state.currentTurn != role) return [];

    final moves = <AiMove>[];
    final gamePhase = state.gamePhase;
    final goatsToPlace = state.goatsToPlace;
    final nodes = state.board.allNodes;

    if (gamePhase == 'placement' &&
        role == PieceType.goat &&
        goatsToPlace > 0) {
      for (final node in state.placementTargets) {
        moves.add(AiMove.placement(node));
      }
      return moves;
    }

    if (gamePhase == 'placement' && role == PieceType.tiger) {
      for (final node in nodes) {
        if (state.pieceAt(node) != PieceType.tiger) continue;
        for (final m in state.getTigerMoves(node)) {
          moves.add(AiMove(from: node, target: m.target, jumped: m.jumped));
        }
      }
      return moves;
    }

    if (gamePhase == 'movement') {
      if (role == PieceType.tiger) {
        for (final node in nodes) {
          if (state.pieceAt(node) != PieceType.tiger) continue;
          for (final m in state.getTigerMoves(node)) {
            moves.add(AiMove(from: node, target: m.target, jumped: m.jumped));
          }
        }
      } else {
        for (final node in nodes) {
          if (state.pieceAt(node) != PieceType.goat) continue;
          for (final m in state.getGoatMoves(node)) {
            moves.add(AiMove(from: node, target: m.target));
          }
        }
      }
    }

    return moves;
  }

  @Deprecated('Use movesForRole')
  static List<AiMove> allMovesForTurn(GameState state) {
    return movesForRole(state, state.currentTurn);
  }

  static bool applyMove(GameState state, AiMove move) {
    if (move.isPlacement) {
      return state.applyPlacement(move.placement!);
    }
    return state.applyMove(move.from!, move.target!);
  }
}
