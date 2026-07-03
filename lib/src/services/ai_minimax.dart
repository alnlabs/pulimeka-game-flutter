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
    if (state.capturedGoats >= GameState.goatsToCaptureForTigerWin) {
      return 'tigers';
    }
    if (state.areTigersTrapped()) return 'goats';
    return null;
  }
}
