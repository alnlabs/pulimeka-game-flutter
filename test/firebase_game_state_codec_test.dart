import 'package:flutter_test/flutter_test.dart';
import 'package:puli_meka_game_flutter/src/models/game_state.dart';
import 'package:puli_meka_game_flutter/src/services/firebase_game_state_codec.dart';

void main() {
  test('fromFirebase does not restore default tigers on empty nodes', () {
    // Simulate RTDB after a tiger moved: only non-null keys are stored.
    final data = {
      'pieceState': {
        'r2-c6': 'tiger',
        'r1-c4': 'goat',
        'r3-c4': 'goat',
        'r2-c3': 'goat',
        'r2-c5': 'goat',
      },
      'currentTurn': 'goat',
      'gamePhase': 'placement',
      'goatsToPlace': 19,
      'capturedGoats': 0,
      'moveCount': 1,
    };

    final state = FirebaseGameStateCodec.fromFirebase(data);

    expect(state.pieceAt('r2-c2'), isNull);
    expect(state.pieceAt('r2-c6'), PieceType.tiger);
    expect(state.pieceState.values.where((p) => p == PieceType.tiger).length, 1);
  });

  test('round-trip preserves moved tiger position', () {
    final initial = GameState.initial();
    initial.pieceState['r2-c2'] = null;
    initial.pieceState['r2-c1'] = PieceType.tiger;

    final map = FirebaseGameStateCodec.toFirebase(
      state: initial,
      playerId: 'p1',
      moveCount: 1,
    );
    final loaded = FirebaseGameStateCodec.fromFirebase(map);

    expect(loaded.pieceAt('r2-c2'), isNull);
    expect(loaded.pieceAt('r2-c1'), PieceType.tiger);
    expect(
      loaded.pieceState.values.where((p) => p == PieceType.tiger).length,
      2,
    );
  });
}
