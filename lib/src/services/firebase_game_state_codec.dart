import '../models/board_layout.dart';
import '../models/game_constants.dart';
import '../models/game_state.dart';

/// Encode/decode game state for Firebase RTDB (Android online format).
class FirebaseGameStateCodec {
  static Map<String, dynamic> createInitialFirebaseMap() {
    final pieceState = <String, dynamic>{};
    for (final node in BoardLayout.allNodes) {
      pieceState[node] = null;
    }
    for (final node in BoardLayout.tigerStartNodes) {
      pieceState[node] = 'tiger';
    }
    for (final node in BoardLayout.initialGoatNodes) {
      pieceState[node] = 'goat';
    }

    return {
      'pieceState': pieceState,
      'currentTurn': 'tiger',
      'gamePhase': 'placement',
      'goatsToPlace': GameConstants.totalGoats - GameConstants.initialGoats,
      'capturedGoats': 0,
      'winner': null,
      'moveCount': 0,
      'lastMoveBy': null,
      'lastMoveAt': null,
    };
  }

  static GameState fromFirebase(Map<dynamic, dynamic> data) {
    // Do not use GameState.initial() here: Firebase update() drops null keys, so
    // missing nodes must stay empty — not revert to default tiger/goat positions.
    final syncedPieces = <String, PieceType?>{};
    final rawPieces = data['pieceState'];
    if (rawPieces is Map) {
      for (final entry in rawPieces.entries) {
        final node = entry.key.toString();
        if (!BoardLayout.allNodes.contains(node)) continue;
        final piece = entry.value?.toString();
        switch (piece) {
          case 'tiger':
            syncedPieces[node] = PieceType.tiger;
          case 'goat':
            syncedPieces[node] = PieceType.goat;
          default:
            syncedPieces[node] = null;
        }
      }
    }

    final turn = data['currentTurn']?.toString() ?? 'tiger';
    return GameState.fromOnlineSync(
      syncedPieces: syncedPieces,
      currentTurn: turn == 'goat' ? PieceType.goat : PieceType.tiger,
      gamePhase: data['gamePhase']?.toString() ?? 'placement',
      goatsToPlace: parseIntField(data['goatsToPlace']) ??
          (GameConstants.totalGoats - GameConstants.initialGoats),
      capturedGoats: parseIntField(data['capturedGoats']) ?? 0,
      winner: data['winner']?.toString(),
    );
  }

  static Map<String, dynamic> toFirebase({
    required GameState state,
    required String playerId,
    required int moveCount,
  }) {
    final pieceState = <String, dynamic>{};
    for (final node in BoardLayout.allNodes) {
      switch (state.pieceState[node]) {
        case PieceType.tiger:
          pieceState[node] = 'tiger';
        case PieceType.goat:
          pieceState[node] = 'goat';
        default:
          pieceState[node] = null;
      }
    }

    return {
      'pieceState': pieceState,
      'currentTurn':
          state.currentTurn == PieceType.tiger ? 'tiger' : 'goat',
      'gamePhase': state.gamePhase,
      'goatsToPlace': state.goatsToPlace,
      'capturedGoats': state.capturedGoats,
      'winner': state.winner,
      'moveCount': moveCount,
      'lastMoveBy': playerId,
      'lastMoveAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static int? parseIntField(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
