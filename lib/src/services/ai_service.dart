import 'dart:math';

import '../models/ai_difficulty.dart';
import '../models/ai_move.dart';
import '../models/board_layout.dart';
import '../models/game_state.dart';
import 'ai_minimax.dart';

export '../models/ai_move.dart';

class AiService {
  AiService({
    AiDifficulty difficulty = AiDifficulty.medium,
    Random? random,
  })  : _difficulty = difficulty,
        _minimax = AiMinimax(random: random ?? Random());

  final AiDifficulty _difficulty;
  final AiMinimax _minimax;

  AiDifficulty get difficulty => _difficulty;

  AiMove? chooseTigerMove(GameState state) {
    if (state.currentTurn != PieceType.tiger) return null;
    return _minimax.bestMove(
      state: state,
      aiRole: PieceType.tiger,
      difficulty: _difficulty,
    );
  }

  AiMove? chooseGoatMove(GameState state) {
    if (state.currentTurn != PieceType.goat) return null;
    return _minimax.bestMove(
      state: state,
      aiRole: PieceType.goat,
      difficulty: _difficulty,
    );
  }

  String chooseGoatPlacement(GameState state) {
    final move = chooseGoatMove(state);
    if (move?.isPlacement == true) return move!.placement!;
    final targets = state.placementTargets;
    if (targets.isEmpty) return BoardLayout.allNodes.first;
    return targets.first;
  }
}
