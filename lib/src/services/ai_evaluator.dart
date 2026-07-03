import '../models/ai_move.dart';
import '../models/board_layout.dart';
import '../models/game_state.dart';

/// Board evaluation and move generation for minimax (Android `AIEvaluator`).
class AiEvaluator {
  static const _centerNodes = ['r2-c3', 'r2-c4', 'r2-c5', 'r1-c4', 'r3-c4'];

  static int evaluate(GameState state, PieceType aiRole) {
    if (aiRole == PieceType.tiger) {
      if (state.capturedGoats >= GameState.goatsToCaptureForTigerWin) {
        return 10000;
      }
      if (state.areTigersTrapped()) {
        return -10000;
      }
    } else {
      if (state.areTigersTrapped()) {
        return 10000;
      }
      if (state.capturedGoats >= GameState.goatsToCaptureForTigerWin) {
        return -10000;
      }
    }

    var score = 0;
    if (aiRole == PieceType.tiger) {
      score += state.capturedGoats * 500;
      var totalTigerMoves = 0;
      var captureMoves = 0;
      for (final node in BoardLayout.allNodes) {
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
      for (final node in BoardLayout.allNodes) {
        if (state.pieceAt(node) == PieceType.tiger &&
            _centerNodes.contains(node)) {
          score += 20;
        }
      }
    } else {
      var totalTigerMoves = 0;
      for (final node in BoardLayout.allNodes) {
        if (state.pieceAt(node) == PieceType.tiger) {
          totalTigerMoves += state.getTigerMoves(node).length;
        }
      }
      score += (10 - totalTigerMoves) * 100;
      if (totalTigerMoves == 0) score += 5000;
      score -= state.capturedGoats * 300;

      var blockingGoats = 0;
      for (final node in BoardLayout.allNodes) {
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
      for (final node in BoardLayout.allNodes) {
        if (state.pieceAt(node) == PieceType.goat) {
          totalGoatMoves += state.getGoatMoves(node).length;
        }
      }
      score += totalGoatMoves * 5;
      for (final node in BoardLayout.allNodes) {
        if (state.pieceAt(node) == PieceType.goat &&
            _centerNodes.contains(node)) {
          score += 10;
        }
      }
    }
    return score;
  }

  /// Mirrors Android `getAllPossibleMoves` for the active player [role].
  static List<AiMove> movesForRole(GameState state, PieceType role) {
    if (state.winner != null) return [];
    if (state.currentTurn != role) return [];

    final moves = <AiMove>[];
    final gamePhase = state.gamePhase;
    final goatsToPlace = state.goatsToPlace;

    if (gamePhase == 'placement' &&
        role == PieceType.goat &&
        goatsToPlace > 0) {
      for (final node in state.placementTargets) {
        moves.add(AiMove.placement(node));
      }
      return moves;
    }

    if (gamePhase == 'placement' && role == PieceType.tiger) {
      for (final node in BoardLayout.allNodes) {
        if (state.pieceAt(node) != PieceType.tiger) continue;
        for (final m in state.getTigerMoves(node)) {
          moves.add(AiMove(from: node, target: m.target, jumped: m.jumped));
        }
      }
      return moves;
    }

    if (gamePhase == 'movement') {
      if (role == PieceType.tiger) {
        for (final node in BoardLayout.allNodes) {
          if (state.pieceAt(node) != PieceType.tiger) continue;
          for (final m in state.getTigerMoves(node)) {
            moves.add(AiMove(from: node, target: m.target, jumped: m.jumped));
          }
        }
      } else {
        for (final node in BoardLayout.allNodes) {
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
