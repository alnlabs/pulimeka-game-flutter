import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puli_meka_game_flutter/src/models/ai_difficulty.dart';
import 'package:puli_meka_game_flutter/src/models/game_state.dart';
import 'package:puli_meka_game_flutter/src/services/ai_service.dart';

void main() {
  group('AiService', () {
    test('chooses a valid tiger move when movement phase begins', () {
      final gameState = GameState.initial();
      gameState.goatsToPlace = 0;
      gameState.gamePhase = 'movement';
      gameState.currentTurn = PieceType.tiger;

      final aiService = AiService();
      final move = aiService.chooseTigerMove(gameState);

      expect(move, isNotNull);
      expect(gameState.pieceAt(move!.from!), equals(PieceType.tiger));
      expect(gameState.pieceAt(move.target!), isNull);
    });

    test('chooses a valid goat placement target', () {
      final gameState = GameState.initial();
      gameState.currentTurn = PieceType.goat;
      final aiService = AiService();
      final move = aiService.chooseGoatMove(gameState);

      expect(move, isNotNull);
      expect(move!.isPlacement, isTrue);
      expect(gameState.placementTargets, contains(move.placement));
    });

    test('hard mode goat placement prefers choking tiger mobility', () {
      final state = GameState.initial();
      state.currentTurn = PieceType.goat;
      final beforeMobility = state.getTigerMoves('r2-c2').length +
          state.getTigerMoves('r2-c6').length;

      final move = AiService(
        difficulty: AiDifficulty.hard,
        random: Random(42),
      ).chooseGoatMove(state);

      expect(move, isNotNull);
      expect(move!.isPlacement, isTrue);

      final trial = state.copy();
      trial.applyPlacement(move.placement!);
      final afterMobility = trial.getTigerMoves('r2-c2').length +
          trial.getTigerMoves('r2-c6').length;
      expect(afterMobility, lessThanOrEqualTo(beforeMobility));
    });

    test('hard mode prefers a capture when one is available', () {
      final state = GameState.initial();
      state.goatsToPlace = 0;
      state.gamePhase = 'movement';
      state.currentTurn = PieceType.tiger;
      state.pieceState['r2-c2'] = PieceType.tiger;
      state.pieceState['r2-c3'] = PieceType.goat;
      state.pieceState['r2-c4'] = null;

      final hardMove = AiService(
        difficulty: AiDifficulty.hard,
        random: Random(1),
      ).chooseTigerMove(state);
      expect(hardMove, isNotNull);
      expect(hardMove!.isJump, isTrue);
      expect(hardMove.jumped, 'r2-c3');
    });

    test('easy sometimes picks a random move unlike hard', () {
      final state = GameState.initial();
      state.currentTurn = PieceType.goat;

      final hardMove = AiService(
        difficulty: AiDifficulty.hard,
        random: Random(7),
      ).chooseGoatMove(state);

      var easyRandomCount = 0;
      for (var seed = 0; seed < 40; seed++) {
        final easyMove = AiService(
          difficulty: AiDifficulty.easy,
          random: Random(seed),
        ).chooseGoatMove(state);
        if (easyMove?.placement != hardMove?.placement) {
          easyRandomCount++;
        }
      }
      expect(easyRandomCount, greaterThan(0));
    });
  });
}
