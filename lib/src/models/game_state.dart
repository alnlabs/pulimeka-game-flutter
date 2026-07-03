import 'board_layout.dart';
import 'game_constants.dart';

enum PieceType { tiger, goat }

class GameMove {
  final String target;
  final String? jumped;
  final bool isJump;

  GameMove({required this.target, this.jumped}) : isJump = jumped != null;
}

class GameState {
  static const int totalGoats = GameConstants.totalGoats;
  static const int initialGoats = GameConstants.initialGoats;
  static const int goatsToCaptureForTigerWin = GameConstants.goatsToCaptureForTigerWin;

  final Map<String, PieceType?> pieceState;
  PieceType currentTurn;
  String gamePhase;
  int goatsToPlace;
  int capturedGoats;
  String? winner;

  GameState._({
    required this.pieceState,
    required this.currentTurn,
    required this.gamePhase,
    required this.goatsToPlace,
    required this.capturedGoats,
    this.winner,
  });

  /// Deep copy for AI search.
  GameState copy() {
    return GameState._(
      pieceState: Map<String, PieceType?>.from(pieceState),
      currentTurn: currentTurn,
      gamePhase: gamePhase,
      goatsToPlace: goatsToPlace,
      capturedGoats: capturedGoats,
      winner: winner,
    );
  }

  factory GameState.initial() {
    final pieces = <String, PieceType?>{};
    for (final node in BoardLayout.allNodes) {
      pieces[node] = null;
    }
    for (final tiger in BoardLayout.tigerStartNodes) {
      pieces[tiger] = PieceType.tiger;
    }
    for (final goat in BoardLayout.initialGoatNodes) {
      pieces[goat] = PieceType.goat;
    }

    return GameState._(
      pieceState: pieces,
      currentTurn: PieceType.tiger,
      gamePhase: 'placement',
      goatsToPlace: totalGoats - initialGoats,
      capturedGoats: 0,
      winner: null,
    );
  }

  /// Empty board + fields from Firebase (not [initial] — RTDB omits null piece keys).
  factory GameState.fromOnlineSync({
    required Map<String, PieceType?> syncedPieces,
    required PieceType currentTurn,
    required String gamePhase,
    required int goatsToPlace,
    required int capturedGoats,
    String? winner,
  }) {
    final pieces = <String, PieceType?>{};
    for (final node in BoardLayout.allNodes) {
      pieces[node] = syncedPieces[node];
    }
    return GameState._(
      pieceState: pieces,
      currentTurn: currentTurn,
      gamePhase: gamePhase,
      goatsToPlace: goatsToPlace,
      capturedGoats: capturedGoats,
      winner: winner,
    );
  }

  bool get isPlacementPhase => gamePhase == 'placement';
  bool get isMovementPhase => gamePhase == 'movement';

  List<String> get placementTargets {
    return pieceState.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();
  }

  PieceType? pieceAt(String node) => pieceState[node];

  List<GameMove> getTigerMoves(String startNode) {
    if (pieceState[startNode] != PieceType.tiger) {
      return [];
    }
    final start = BoardLayout.nodeCoord(startNode);
    if (start == null) {
      return [];
    }

    final moves = <GameMove>[];
    for (final neighborName in BoardLayout.neighbors(startNode)) {
      final neighborPiece = pieceState[neighborName];
      if (neighborPiece == null) {
        moves.add(GameMove(target: neighborName));
      }
    }

    for (final midNodeName in BoardLayout.neighbors(startNode)) {
      if (pieceState[midNodeName] != PieceType.goat) {
        continue;
      }
      final mid = BoardLayout.nodeCoord(midNodeName);
      if (mid == null) continue;
      final startToMidDx = mid.col - start.col;
      final startToMidDy = mid.row - start.row;

      for (final endNodeName in BoardLayout.neighbors(midNodeName)) {
        if (endNodeName == startNode) {
          continue;
        }
        if (pieceState[endNodeName] != null) {
          continue;
        }
        final end = BoardLayout.nodeCoord(endNodeName);
        if (end == null) continue;
        final midToEndDx = end.col - mid.col;
        final midToEndDy = end.row - mid.row;

        if (_isSameDirection(startToMidDx, startToMidDy, midToEndDx, midToEndDy)) {
          moves.add(GameMove(target: endNodeName, jumped: midNodeName));
        }
      }
    }
    return moves;
  }

  List<GameMove> getGoatMoves(String startNode) {
    if (pieceState[startNode] != PieceType.goat) {
      return [];
    }
    final moves = <GameMove>[];
    for (final neighborName in BoardLayout.neighbors(startNode)) {
      if (pieceState[neighborName] == null) {
        moves.add(GameMove(target: neighborName));
      }
    }
    return moves;
  }

  List<GameMove> getValidMoves(String node) {
    final piece = pieceState[node];
    if (piece == PieceType.tiger) {
      return getTigerMoves(node);
    }
    if (piece == PieceType.goat) {
      return getGoatMoves(node);
    }
    return [];
  }

  Set<String> getValidTargets(String node) {
    final piece = pieceState[node];
    if (piece == null) {
      return const {};
    }
    // Tigers may move during placement; goats move only after all are placed.
    if (piece == PieceType.tiger && currentTurn == PieceType.tiger) {
      return getValidMoves(node).map((move) => move.target).toSet();
    }
    if (piece == PieceType.goat &&
        currentTurn == PieceType.goat &&
        isMovementPhase) {
      return getValidMoves(node).map((move) => move.target).toSet();
    }
    return const {};
  }

  bool applyPlacement(String targetNode) {
    if (!isPlacementPhase) return false;
    if (currentTurn != PieceType.goat) return false;
    if (pieceState[targetNode] != null) return false;

    pieceState[targetNode] = PieceType.goat;
    goatsToPlace -= 1;
    if (goatsToPlace <= 0) {
      gamePhase = 'movement';
    }
    _advanceTurn();
    _updateWinner();
    return true;
  }

  bool applyMove(String startNode, String targetNode) {
    final mover = pieceState[startNode];
    if (mover == null) return false;
    if (mover == PieceType.tiger && currentTurn != PieceType.tiger) return false;
    if (mover == PieceType.goat && currentTurn != PieceType.goat) return false;
    // While placing goats from hand, goats may only be placed — not moved.
    if (isPlacementPhase && goatsToPlace > 0 && mover == PieceType.goat) {
      return false;
    }

    final moves = getValidMoves(startNode);
    final chosen = moves.firstWhere(
      (move) => move.target == targetNode,
      orElse: () => GameMove(target: ''),
    );
    if (chosen.target.isEmpty) {
      return false;
    }
    pieceState[startNode] = null;
    pieceState[targetNode] = mover;
    if (chosen.isJump && chosen.jumped != null && mover == PieceType.tiger) {
      pieceState[chosen.jumped!] = null;
      capturedGoats += 1;
    }
    _advanceTurn();
    _updateWinner();
    return true;
  }

  bool areTigersTrapped() {
    for (final entry in pieceState.entries) {
      if (entry.value == PieceType.tiger) {
        if (getTigerMoves(entry.key).isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void _advanceTurn() {
    currentTurn = currentTurn == PieceType.tiger ? PieceType.goat : PieceType.tiger;
  }

  void _updateWinner() {
    if (capturedGoats >= goatsToCaptureForTigerWin) {
      winner = 'tigers';
      return;
    }
    if (isMovementPhase && areTigersTrapped()) {
      winner = 'goats';
      return;
    }
    winner = null;
  }

  void reset() {
    final initial = GameState.initial();
    pieceState
      ..clear()
      ..addAll(initial.pieceState);
    currentTurn = initial.currentTurn;
    gamePhase = initial.gamePhase;
    goatsToPlace = initial.goatsToPlace;
    capturedGoats = initial.capturedGoats;
    winner = initial.winner;
  }

  /// Matches Android `MoveValidator` straight-line jump check (grid col/row deltas).
  bool _isSameDirection(int dx1, int dy1, int dx2, int dy2) {
    if (dx1 == 0 && dx2 == 0) {
      return true;
    }
    if (dy1 == 0 && dy2 == 0) {
      return true;
    }
    if (dx1 != 0 && dx2 != 0 && dy1 != 0 && dy2 != 0) {
      final sameSignX = (dx1 > 0 && dx2 > 0) || (dx1 < 0 && dx2 < 0);
      final sameSignY = (dy1 > 0 && dy2 > 0) || (dy1 < 0 && dy2 < 0);
      final sameDistanceX = dx1.abs() == dx2.abs();
      final sameDistanceY = dy1.abs() == dy2.abs();
      return sameSignX && sameSignY && sameDistanceX && sameDistanceY;
    }
    return false;
  }
}
