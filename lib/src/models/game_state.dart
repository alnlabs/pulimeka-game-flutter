import 'board_layout.dart';
import 'board_spec.dart';
import 'game_constants.dart';

enum PieceType { tiger, goat }

/// Starting positions and win thresholds for a match.
class RuleSpec {
  const RuleSpec({
    required this.totalGoats,
    required this.goatsToCapture,
    required this.tigerStarts,
    required this.goatStarts,
    this.firstTurn = PieceType.tiger,
    this.winByTrapOnly = false,
    this.allowTigerJumps = true,
  });

  final int totalGoats;
  final int goatsToCapture;
  final List<String> tigerStarts;
  final List<String> goatStarts;
  final PieceType firstTurn;

  /// Teaching levels: goats win only by trapping; tiger cannot win by captures.
  final bool winByTrapOnly;

  /// When false, tigers only step to empty neighbors (no capturing jumps).
  final bool allowTigerJumps;

  int get goatsToPlace =>
      (totalGoats - goatStarts.length).clamp(0, totalGoats);
}

class GameMove {
  final String target;
  final String? jumped;
  final bool isJump;

  GameMove({required this.target, this.jumped}) : isJump = jumped != null;
}

class GameState {
  final BoardSpec board;
  final int totalGoats;
  final int initialGoatsOnBoard;
  final int goatsToCaptureForTigerWin;
  final List<String> tigerStartNodes;
  final List<String> goatStartNodes;
  final PieceType firstTurn;
  final bool winByTrapOnly;
  final bool allowTigerJumps;

  final Map<String, PieceType?> pieceState;
  PieceType currentTurn;
  String gamePhase;
  int goatsToPlace;
  int capturedGoats;
  String? winner;

  GameState._({
    required this.board,
    required this.totalGoats,
    required this.initialGoatsOnBoard,
    required this.goatsToCaptureForTigerWin,
    required this.tigerStartNodes,
    required this.goatStartNodes,
    required this.firstTurn,
    required this.winByTrapOnly,
    required this.allowTigerJumps,
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
      board: board,
      totalGoats: totalGoats,
      initialGoatsOnBoard: initialGoatsOnBoard,
      goatsToCaptureForTigerWin: goatsToCaptureForTigerWin,
      tigerStartNodes: tigerStartNodes,
      goatStartNodes: goatStartNodes,
      firstTurn: firstTurn,
      winByTrapOnly: winByTrapOnly,
      allowTigerJumps: allowTigerJumps,
      pieceState: Map<String, PieceType?>.from(pieceState),
      currentTurn: currentTurn,
      gamePhase: gamePhase,
      goatsToPlace: goatsToPlace,
      capturedGoats: capturedGoats,
      winner: winner,
    );
  }

  factory GameState.initial() {
    return GameState.fromRules(
      board: BoardLayout.asSpec(),
      rules: RuleSpec(
        totalGoats: GameConstants.totalGoats,
        goatsToCapture: GameConstants.goatsToCaptureForTigerWin,
        tigerStarts: BoardLayout.tigerStartNodes,
        goatStarts: BoardLayout.initialGoatNodes,
        firstTurn: PieceType.tiger,
      ),
    );
  }

  factory GameState.fromRules({
    required BoardSpec board,
    required RuleSpec rules,
  }) {
    for (final node in [...rules.tigerStarts, ...rules.goatStarts]) {
      if (!board.hasNode(node)) {
        throw ArgumentError('Start node $node missing on board ${board.id}');
      }
    }

    final pieces = <String, PieceType?>{};
    for (final node in board.allNodes) {
      pieces[node] = null;
    }
    for (final tiger in rules.tigerStarts) {
      pieces[tiger] = PieceType.tiger;
    }
    for (final goat in rules.goatStarts) {
      pieces[goat] = PieceType.goat;
    }

    final toPlace = rules.goatsToPlace;
    return GameState._(
      board: board,
      totalGoats: rules.totalGoats,
      initialGoatsOnBoard: rules.goatStarts.length,
      goatsToCaptureForTigerWin: rules.goatsToCapture,
      tigerStartNodes: List.unmodifiable(rules.tigerStarts),
      goatStartNodes: List.unmodifiable(rules.goatStarts),
      firstTurn: rules.firstTurn,
      winByTrapOnly: rules.winByTrapOnly,
      allowTigerJumps: rules.allowTigerJumps,
      pieceState: pieces,
      currentTurn: rules.firstTurn,
      gamePhase: toPlace > 0 ? 'placement' : 'movement',
      goatsToPlace: toPlace,
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
    final board = BoardLayout.asSpec();
    final pieces = <String, PieceType?>{};
    for (final node in board.allNodes) {
      pieces[node] = syncedPieces[node];
    }
    return GameState._(
      board: board,
      totalGoats: GameConstants.totalGoats,
      initialGoatsOnBoard: GameConstants.initialGoats,
      goatsToCaptureForTigerWin: GameConstants.goatsToCaptureForTigerWin,
      tigerStartNodes: BoardLayout.tigerStartNodes,
      goatStartNodes: BoardLayout.initialGoatNodes,
      firstTurn: PieceType.tiger,
      winByTrapOnly: false,
      allowTigerJumps: true,
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

  /// Empty nodes a tiger can step/jump into right now (recomputed from board).
  Set<String> get tigerEscapeGaps {
    final gaps = <String>{};
    for (final entry in pieceState.entries) {
      if (entry.value != PieceType.tiger) continue;
      for (final move in getTigerMoves(entry.key)) {
        gaps.add(move.target);
      }
    }
    return gaps;
  }

  /// True if placing a goat on [node] would leave every tiger with no moves.
  bool placementWouldTrapTigers(String node) {
    if (pieceState[node] != null) return false;
    final previous = pieceState[node];
    pieceState[node] = PieceType.goat;
    final trapped = areTigersTrapped();
    pieceState[node] = previous;
    return trapped;
  }

  /// Placements that close at least one current escape, preferring instant traps.
  Set<String> get teachingPlacementGaps {
    final escapes = tigerEscapeGaps;
    if (escapes.isEmpty) return {};
    final trapping = <String>{};
    final reducing = <String>{};
    for (final node in escapes) {
      if (placementWouldTrapTigers(node)) {
        trapping.add(node);
      } else {
        reducing.add(node);
      }
    }
    return trapping.isNotEmpty ? trapping : reducing;
  }

  /// True when a goat from hand can finish the trap this turn.
  bool get hasInstantTrapPlacement {
    if (!isPlacementPhase || goatsToPlace <= 0) return false;
    final gaps = teachingPlacementGaps;
    return gaps.isNotEmpty && placementWouldTrapTigers(gaps.first);
  }

  PieceType? pieceAt(String node) => pieceState[node];

  List<GameMove> getTigerMoves(String startNode) {
    if (pieceState[startNode] != PieceType.tiger) {
      return [];
    }
    final start = board.nodeCoord(startNode);
    if (start == null) {
      return [];
    }

    final moves = <GameMove>[];
    for (final neighborName in board.neighbors(startNode)) {
      final neighborPiece = pieceState[neighborName];
      if (neighborPiece == null) {
        moves.add(GameMove(target: neighborName));
      }
    }

    if (allowTigerJumps) {
      for (final midNodeName in board.neighbors(startNode)) {
        if (pieceState[midNodeName] != PieceType.goat) {
          continue;
        }
        final mid = board.nodeCoord(midNodeName);
        if (mid == null) continue;
        final startToMidDx = mid.col - start.col;
        final startToMidDy = mid.row - start.row;

        for (final endNodeName in board.neighbors(midNodeName)) {
          if (endNodeName == startNode) {
            continue;
          }
          if (pieceState[endNodeName] != null) {
            continue;
          }
          final end = board.nodeCoord(endNodeName);
          if (end == null) continue;
          final midToEndDx = end.col - mid.col;
          final midToEndDy = end.row - mid.row;

          if (_isSameDirection(startToMidDx, startToMidDy, midToEndDx, midToEndDy)) {
            moves.add(GameMove(target: endNodeName, jumped: midNodeName));
          }
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
    for (final neighborName in board.neighbors(startNode)) {
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
    var sawTiger = false;
    for (final entry in pieceState.entries) {
      if (entry.value != PieceType.tiger) continue;
      sawTiger = true;
      if (getTigerMoves(entry.key).isNotEmpty) {
        return false;
      }
    }
    return sawTiger;
  }

  void _advanceTurn() {
    currentTurn = currentTurn == PieceType.tiger ? PieceType.goat : PieceType.tiger;
  }

  void refreshWinner() => _updateWinner();

  void _updateWinner() {
    final goatsOnBoard =
        pieceState.values.where((v) => v == PieceType.goat).length;
    final herdWipedOut = goatsToPlace <= 0 && goatsOnBoard == 0;

    // Tiger win: capture quota, or every goat has been eaten (no herd left).
    if (herdWipedOut ||
        (!winByTrapOnly && capturedGoats >= goatsToCaptureForTigerWin)) {
      winner = 'tigers';
      return;
    }
    // Goats win as soon as every tiger has no legal step/jump — including
    // mid-placement. Waiting for movement left the board frozen when the AI
    // (or a human tiger) had an empty move list.
    if (areTigersTrapped()) {
      winner = 'goats';
      return;
    }
    winner = null;
  }

  void reset() {
    final initial = GameState.fromRules(
      board: board,
      rules: RuleSpec(
        totalGoats: totalGoats,
        goatsToCapture: goatsToCaptureForTigerWin,
        tigerStarts: tigerStartNodes,
        goatStarts: goatStartNodes,
        firstTurn: firstTurn,
        winByTrapOnly: winByTrapOnly,
        allowTigerJumps: allowTigerJumps,
      ),
    );
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
