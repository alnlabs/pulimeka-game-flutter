import 'package:flutter_test/flutter_test.dart';
import 'package:puli_meka_game_flutter/src/models/ai_difficulty.dart';
import 'package:puli_meka_game_flutter/src/models/game_state.dart';
import 'package:puli_meka_game_flutter/src/services/ai_service.dart';
import 'package:puli_meka_game_flutter/src/services/move_hint_calculator.dart';

void main() {
  group('MoveHintCalculator', () {
    test('suggests best tiger capture when available', () {
      final state = GameState.initial();
      state.goatsToPlace = 0;
      state.gamePhase = 'movement';
      state.currentTurn = PieceType.tiger;
      state.pieceState['r2-c2'] = PieceType.tiger;
      state.pieceState['r2-c3'] = PieceType.goat;
      state.pieceState['r2-c4'] = null;

      final hint = MoveHintCalculator().suggest(state);

      expect(hint, isNotNull);
      expect(hint!.from, 'r2-c2');
      expect(hint.to, 'r2-c4');
      expect(hint.isPlacement, isFalse);
    });

    test('suggests best goat placement from minimax', () {
      final state = GameState.initial();
      state.currentTurn = PieceType.goat;

      final aiMove = AiService(difficulty: AiDifficulty.hard).chooseGoatMove(state);
      final hint = MoveHintCalculator().suggest(state);

      expect(hint, isNotNull);
      expect(hint!.isPlacement, isTrue);
      expect(hint.to, aiMove?.placement);
    });

    test('suggests tiger move during placement phase when legal', () {
      final state = GameState.initial();
      state.currentTurn = PieceType.tiger;

      final aiMove = AiService(difficulty: AiDifficulty.hard).chooseTigerMove(state);
      final hint = MoveHintCalculator().suggest(state);

      expect(hint, isNotNull);
      expect(hint!.from, aiMove?.from);
      expect(hint.to, aiMove?.target ?? aiMove?.placement);
    });
  });
}
