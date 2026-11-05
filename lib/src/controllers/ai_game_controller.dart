import 'package:flutter/foundation.dart';

import '../models/ai_difficulty.dart';
import '../models/ai_move.dart';
import '../models/game_state.dart';
import '../services/ai_compute.dart';
import '../services/ai_service.dart';
import 'game_controller.dart';

class AiGameController extends GameController {
  AiGameController({
    required this.humanRole,
    AiDifficulty difficulty = AiDifficulty.medium,
    AiService? aiService,
    GameState? engine,
  })  : difficulty = difficulty,
        _ai = aiService ?? AiService(difficulty: difficulty),
        super(engine: engine) {
    if (ui.currentTurn != humanRole && ui.winner == null) {
      Future.microtask(_scheduleAiTurn);
    }
  }

  final PieceType humanRole;
  final AiDifficulty difficulty;
  final AiService _ai;
  bool _runningAi = false;
  int _aiTurnSerial = 0;

  @override
  void resetGame() {
    _aiTurnSerial++;
    super.resetGame();
    Future.microtask(_scheduleAiTurn);
  }

  @override
  void onNodeTapped(String node) {
    super.onNodeTapped(node);
    _scheduleAiTurn();
  }

  void _scheduleAiTurn() {
    if (_runningAi || ui.winner != null) return;
    if (ui.currentTurn == humanRole) return;

    _runningAi = true;
    final serial = ++_aiTurnSerial;
    Future<void>.delayed(difficulty.thinkDelay, () async {
      try {
        await _runAiMove(serial);
      } finally {
        _runningAi = false;
        if (ui.winner == null && ui.currentTurn != humanRole) {
          _scheduleAiTurn();
        }
      }
    });
  }

  Future<void> _runAiMove(int serial) async {
    if (ui.winner != null || serial != _aiTurnSerial) return;

    final snapshot = gameState.copy();
    final turn = snapshot.currentTurn;

    AiMove? move;
    if (kIsWeb) {
      move = _chooseMoveLocally(snapshot, turn);
    } else {
      try {
        move = await compute(
          aiComputeMove,
          AiComputeRequest(
            state: snapshot,
            turn: turn,
            difficulty: difficulty,
          ),
        );
      } catch (e, stack) {
        debugPrint('AI compute failed, using local search: $e\n$stack');
        move = _chooseMoveLocally(snapshot, turn);
      }
    }

    if (ui.winner != null ||
        serial != _aiTurnSerial ||
        gameState.currentTurn != turn) {
      return;
    }

    if (move == null) {
      declareTrapWinIfNeeded();
      return;
    }

    if (move.isPlacement) {
      applyPlacementDirect(move.placement!);
    } else {
      applyMoveDirect(move.from!, move.target!);
    }
  }

  AiMove? _chooseMoveLocally(GameState state, PieceType turn) {
    if (turn == PieceType.tiger) {
      return _ai.chooseTigerMove(state);
    }
    return _ai.chooseGoatMove(state);
  }
}
