import 'dart:math';

import '../models/ai_difficulty.dart';
import '../models/ai_move.dart';
import '../models/game_state.dart';
import 'ai_evaluator.dart';

class _MinimaxResult {
  const _MinimaxResult(this.score, this.move);

  final int score;
  final AiMove? move;
}

/// Minimax with iterative deepening (Android `Minimax.kt`).
class AiMinimax {
  AiMinimax({Random? random}) : _random = random ?? Random();

  final Random _random;

  AiMove? bestMove({
    required GameState state,
    required PieceType aiRole,
    required AiDifficulty difficulty,
  }) {
    if (state.currentTurn != aiRole) return null;

    var moves = AiEvaluator.movesForRole(state, aiRole);
    if (moves.isEmpty) return null;
    if (moves.length == 1) return moves.first;

    // Teaching tiger: stay in the pocket. Random / depth-1 search both flee
    // to the open board and brick sparse goat levels after one miss.
    if (difficulty == AiDifficulty.tutorial && aiRole == PieceType.tiger) {
      return _docileTigerMove(state, moves);
    }

    if (_random.nextDouble() < difficulty.randomMoveChance) {
      return moves[_random.nextInt(moves.length)];
    }

    final started = DateTime.now().millisecondsSinceEpoch;
    AiMove? bestMove;
    var bestScore = -999999999;

    for (var depth = 1; depth <= difficulty.searchDepth; depth++) {
      // Time limit only between depth iterations (matches Android).
      if (DateTime.now().millisecondsSinceEpoch - started > difficulty.timeLimitMs) {
        break;
      }

      final result = _minimax(
        state: state,
        depth: depth,
        isMaximizing: true,
        aiRole: aiRole,
        alpha: -999999999,
        beta: 999999999,
      );

      if (result.move != null) {
        bestMove = result.move;
        bestScore = result.score;
      }
      if (bestScore > 5000) break;
    }

    return bestMove ?? moves.first;
  }

  /// Prefer a step (not a jump) that leaves the fewest tiger moves.
  AiMove _docileTigerMove(GameState state, List<AiMove> moves) {
    final steps = moves.where((m) => !m.isJump).toList();
    final pool = steps.isNotEmpty ? steps : moves;

    var bestMobility = 1 << 30;
    final tied = <AiMove>[];
    for (final move in pool) {
      final copy = state.copy();
      if (!AiEvaluator.applyMove(copy, move)) continue;
      var mobility = 0;
      for (final node in copy.board.allNodes) {
        if (copy.pieceAt(node) == PieceType.tiger) {
          mobility += copy.getTigerMoves(node).length;
        }
      }
      if (mobility < bestMobility) {
        bestMobility = mobility;
        tied
          ..clear()
          ..add(move);
      } else if (mobility == bestMobility) {
        tied.add(move);
      }
    }
    if (tied.isEmpty) return pool.first;
    return tied[_random.nextInt(tied.length)];
  }

  _MinimaxResult _minimax({
    required GameState state,
    required int depth,
    required bool isMaximizing,
    required PieceType aiRole,
    required int alpha,
    required int beta,
  }) {
    if (_terminalWinner(state) != null || depth == 0) {
      return _MinimaxResult(AiEvaluator.evaluate(state, aiRole), null);
    }

    final currentRole = isMaximizing
        ? aiRole
        : (aiRole == PieceType.tiger ? PieceType.goat : PieceType.tiger);

    var moves = AiEvaluator.movesForRole(state, currentRole);
    if (moves.isEmpty) {
      return _MinimaxResult(AiEvaluator.evaluate(state, aiRole), null);
    }

    var bestMove = moves.first;
    var bestScore = isMaximizing ? -999999999 : 999999999;
    var currentAlpha = alpha;
    var currentBeta = beta;

    for (final move in moves) {
      final copy = state.copy();
      if (!AiEvaluator.applyMove(copy, move)) {
        continue;
      }

      final result = _minimax(
        state: copy,
        depth: depth - 1,
        isMaximizing: !isMaximizing,
        aiRole: aiRole,
        alpha: currentAlpha,
        beta: currentBeta,
      );

      if (isMaximizing) {
        if (result.score > bestScore) {
          bestScore = result.score;
          bestMove = move;
        }
        currentAlpha = max(currentAlpha, bestScore);
      } else {
        if (result.score < bestScore) {
          bestScore = result.score;
          bestMove = move;
        }
        currentBeta = min(currentBeta, bestScore);
      }

      if (currentBeta <= currentAlpha) break;
    }

    return _MinimaxResult(bestScore, bestMove);
  }

  String? _terminalWinner(GameState state) {
    if (state.winner != null) return state.winner;
    final goatsOnBoard =
        state.pieceState.values.where((v) => v == PieceType.goat).length;
    if (state.goatsToPlace <= 0 && goatsOnBoard == 0) {
      return 'tigers';
    }
    if (!state.winByTrapOnly &&
        state.capturedGoats >= state.goatsToCaptureForTigerWin) {
      return 'tigers';
    }
    if (state.areTigersTrapped()) return 'goats';
    return null;
  }
}
