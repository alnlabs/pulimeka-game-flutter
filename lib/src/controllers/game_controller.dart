import 'package:flutter/foundation.dart';

import '../models/board_layout.dart';
import '../models/board_spec.dart';
import '../models/game_state.dart';
import '../services/move_hint_calculator.dart';

class BoardPiece {
  const BoardPiece({required this.type, required this.node});
  final PieceType type;
  final String node;
}

/// UI state aligned with Android `UiGameState` / `GameViewModel`.
class UiGameState {
  const UiGameState({
    this.pieces = const [],
    this.currentTurn = PieceType.tiger,
    this.validTargets = const {},
    this.selectedNode,
    this.winner,
    this.capturedGoats = 0,
    this.goatsToCaptureGoal = 12,
    this.initialGoatsOnBoard = 4,
    this.goatsToPlaceTotal = 19,
    this.winByTrapOnly = false,
    this.board,
    this.invalidMoveMessage,
    this.activeHintMessage,
    this.hintHighlightNodes = const {},
    this.showPlacementDots = false,
  });

  final List<BoardPiece> pieces;
  final PieceType currentTurn;
  final Set<String> validTargets;
  final String? selectedNode;
  final String? winner;
  final int capturedGoats;
  final int goatsToCaptureGoal;
  final int initialGoatsOnBoard;
  final int goatsToPlaceTotal;
  final bool winByTrapOnly;
  final BoardSpec? board;
  final String? invalidMoveMessage;
  final String? activeHintMessage;
  final Set<String> hintHighlightNodes;
  final bool showPlacementDots;

  BoardSpec get boardOrClassic => board ?? BoardLayout.asSpec();

  int get goatsOnBoard => pieces.where((p) => p.type == PieceType.goat).length;

  int get goatsPlacedFromHand {
    final placed = goatsOnBoard + capturedGoats - initialGoatsOnBoard;
    return placed.clamp(0, goatsToPlaceTotal);
  }

  int get goatsRemainingToPlace =>
      (goatsToPlaceTotal - goatsPlacedFromHand).clamp(0, goatsToPlaceTotal);

  /// True while goats from hand still need to be placed (matches Android UI).
  bool get isPlacementPhase => goatsRemainingToPlace > 0;

  bool get isGoatPlacementTurn =>
      isPlacementPhase && currentTurn == PieceType.goat;

  UiGameState copyWith({
    List<BoardPiece>? pieces,
    PieceType? currentTurn,
    Set<String>? validTargets,
    String? selectedNode,
    bool clearSelectedNode = false,
    String? winner,
    bool clearWinner = false,
    int? capturedGoats,
    int? goatsToCaptureGoal,
    int? initialGoatsOnBoard,
    int? goatsToPlaceTotal,
    bool? winByTrapOnly,
    BoardSpec? board,
    String? invalidMoveMessage,
    bool clearInvalidMoveMessage = false,
    String? activeHintMessage,
    bool clearActiveHintMessage = false,
    Set<String>? hintHighlightNodes,
    bool clearHintHighlights = false,
    bool? showPlacementDots,
  }) {
    return UiGameState(
      pieces: pieces ?? this.pieces,
      currentTurn: currentTurn ?? this.currentTurn,
      validTargets: validTargets ?? this.validTargets,
      selectedNode: clearSelectedNode ? null : (selectedNode ?? this.selectedNode),
      winner: clearWinner ? null : (winner ?? this.winner),
      capturedGoats: capturedGoats ?? this.capturedGoats,
      goatsToCaptureGoal: goatsToCaptureGoal ?? this.goatsToCaptureGoal,
      initialGoatsOnBoard: initialGoatsOnBoard ?? this.initialGoatsOnBoard,
      goatsToPlaceTotal: goatsToPlaceTotal ?? this.goatsToPlaceTotal,
      winByTrapOnly: winByTrapOnly ?? this.winByTrapOnly,
      board: board ?? this.board,
      invalidMoveMessage: clearInvalidMoveMessage
          ? null
          : (invalidMoveMessage ?? this.invalidMoveMessage),
      activeHintMessage: clearActiveHintMessage
          ? null
          : (activeHintMessage ?? this.activeHintMessage),
      hintHighlightNodes: clearHintHighlights
          ? const {}
          : (hintHighlightNodes ?? this.hintHighlightNodes),
      showPlacementDots: showPlacementDots ?? this.showPlacementDots,
    );
  }
}

class GameController extends ChangeNotifier {
  GameController({GameState? engine}) : _engine = engine ?? GameState.initial() {
    _syncFromEngine(selected: null);
  }

  final GameState _engine;
  UiGameState _ui = const UiGameState();

  bool tutorialAutoHints = false;
  bool _hintUnlockActive = false;

  UiGameState get ui => _ui;
  GameState get gameState => _engine;

  void setTutorialAutoHints(bool enabled) {
    tutorialAutoHints = enabled;
    _syncFromEngine(selected: _ui.selectedNode);
    notifyListeners();
  }

  void clearActiveHint() {
    if (!_hintUnlockActive &&
        _ui.activeHintMessage == null &&
        _ui.hintHighlightNodes.isEmpty) {
      return;
    }
    _hintUnlockActive = false;
    _syncFromEngine(selected: _ui.selectedNode, clearHint: true);
    notifyListeners();
  }

  void showMoveHint(MoveHint hint) {
    if (_ui.winner != null) {
      return;
    }
    _hintUnlockActive = true;

    if (hint.isPlacement && hint.to != null) {
      _syncFromEngine(
        selected: null,
        clearHint: true,
        hintMessage: hint.message,
        hintNodes: {hint.to!},
        forcePlacementDots: true,
        placementTargets: {hint.to!},
      );
      notifyListeners();
      return;
    }

    if (hint.from != null && hint.to != null) {
      _syncFromEngine(
        selected: hint.from,
        clearHint: true,
        hintMessage: hint.message,
        hintNodes: {hint.from!, hint.to!},
      );
      notifyListeners();
      return;
    }

    _ui = _ui.copyWith(activeHintMessage: hint.message);
    notifyListeners();
  }

  void clearInvalidMoveMessage() {
    if (_ui.invalidMoveMessage != null) {
      _ui = _ui.copyWith(clearInvalidMoveMessage: true);
      notifyListeners();
    }
  }

  void resetGame() {
    _engine.reset();
    _hintUnlockActive = false;
    _ui = const UiGameState();
    _syncFromEngine(selected: null);
    notifyListeners();
  }

  /// If tigers have no legal moves, record a goat win and refresh the HUD.
  bool declareTrapWinIfNeeded() {
    if (_ui.winner != null) return false;
    _engine.refreshWinner();
    if (_engine.winner == null) return false;
    _syncFromEngine(selected: null, clearInvalid: true, clearHint: true);
    notifyListeners();
    return true;
  }

  /// Direct engine updates for AI / automation (skips tap validation messages).
  void applyPlacementDirect(String node) {
    if (_ui.winner != null) return;
    if (!_engine.applyPlacement(node)) return;
    _syncFromEngine(selected: null, clearInvalid: true, clearHint: true);
    notifyListeners();
  }

  void applyMoveDirect(String from, String to) {
    if (_ui.winner != null) return;
    if (!_engine.applyMove(from, to)) return;
    _syncFromEngine(selected: null, clearInvalid: true, clearHint: true);
    notifyListeners();
  }

  void onNodeTapped(String node) {
    if (declareTrapWinIfNeeded()) return;
    if (_ui.winner != null) return;

    final selected = _ui.selectedNode;

    // Place goats from hand on goat's turn (tap empty node; selection not required).
    if (_canPlaceGoatAt(node)) {
      // Only lock when a placement would finish the trap (level 1, or a
      // later teaching position that can end this turn). Otherwise glowing
      // gaps are hints — a missed block must still be recoverable.
      if (tutorialAutoHints &&
          _engine.winByTrapOnly &&
          _engine.hasInstantTrapPlacement &&
          !_engine.teachingPlacementGaps.contains(node)) {
        final gaps = _engine.teachingPlacementGaps;
        _syncFromEngine(
          selected: null,
          clearInvalid: true,
          clearHint: true,
          hintMessage: 'That placement wins — tap the glowing gap.',
          hintNodes: gaps,
          forcePlacementDots: true,
          placementTargets: gaps,
        );
        _ui = _ui.copyWith(
          invalidMoveMessage: 'Tap the glowing gap to trap the tiger.',
        );
        notifyListeners();
        return;
      }
      _engine.applyPlacement(node);
      _hintUnlockActive = false;
      _syncFromEngine(selected: null, clearInvalid: true, clearHint: true);
      notifyListeners();
      return;
    }

    if (selected == null &&
        _ui.isGoatPlacementTurn &&
        _engine.pieceAt(node) == null) {
      _ui = _ui.copyWith(
        invalidMoveMessage: 'Goats can only be placed on empty nodes.',
      );
      notifyListeners();
      return;
    }

    if (selected == null &&
        _ui.isPlacementPhase &&
        _ui.currentTurn == PieceType.tiger &&
        _engine.pieceAt(node) == null) {
      _ui = _ui.copyWith(
        invalidMoveMessage:
            'Select a tiger, then tap a highlighted node to move.',
      );
      notifyListeners();
      return;
    }

    if (selected == null) {
      final piece = _engine.pieceAt(node);
      if ((piece == PieceType.tiger && _ui.currentTurn == PieceType.tiger) ||
          (piece == PieceType.goat && _ui.currentTurn == PieceType.goat)) {
        _syncFromEngine(selected: node, clearInvalid: true);
        notifyListeners();
      } else {
        _ui = _ui.copyWith(
          invalidMoveMessage: 'Select your own piece first.',
        );
        notifyListeners();
      }
      return;
    }

    // Tap a different friendly piece → change selection (matches Android UX).
    if (node != selected) {
      final piece = _engine.pieceAt(node);
      if ((piece == PieceType.tiger && _ui.currentTurn == PieceType.tiger) ||
          (piece == PieceType.goat &&
              _ui.currentTurn == PieceType.goat &&
              _engine.isMovementPhase)) {
        _syncFromEngine(selected: node, clearInvalid: true);
        notifyListeners();
        return;
      }
    }

    final valid = _ui.currentTurn == PieceType.tiger
        ? _engine.getTigerMoves(selected)
        : _engine.getGoatMoves(selected);
    GameMove? chosen;
    for (final move in valid) {
      if (move.target == node) {
        chosen = move;
        break;
      }
    }

    if (chosen == null) {
      if (node == selected) {
        _syncFromEngine(selected: null, clearInvalid: true);
      } else {
        _ui = _ui.copyWith(
          invalidMoveMessage:
              'That move is not allowed. Choose a highlighted node.',
        );
      }
      notifyListeners();
      return;
    }

    _engine.applyMove(selected, node);
    _hintUnlockActive = false;
    _syncFromEngine(selected: null, clearInvalid: true, clearHint: true);
    notifyListeners();
  }

  void _syncFromEngine({
    required String? selected,
    bool clearInvalid = false,
    bool clearHint = false,
    String? hintMessage,
    Set<String>? hintNodes,
    bool forcePlacementDots = false,
    Set<String>? placementTargets,
  }) {
    final pieces = <BoardPiece>[];
    for (final entry in _engine.pieceState.entries) {
      final piece = entry.value;
      if (piece != null) {
        pieces.add(BoardPiece(type: piece, node: entry.key));
      }
    }

    Set<String> validTargets = {};
    if (selected != null) {
      final piece = _engine.pieceAt(selected);
      if (piece == PieceType.tiger) {
        validTargets = _engine.getTigerMoves(selected).map((m) => m.target).toSet();
      } else if (piece == PieceType.goat) {
        validTargets = _engine.getGoatMoves(selected).map((m) => m.target).toSet();
      }
    }

    final inGoatPlacement =
        _engine.isPlacementPhase &&
        _engine.currentTurn == PieceType.goat &&
        _engine.goatsToPlace > 0 &&
        selected == null;

    final showPlacementDots = forcePlacementDots ||
        (inGoatPlacement && (tutorialAutoHints || _hintUnlockActive));

    if (placementTargets != null) {
      validTargets = placementTargets;
    } else if (inGoatPlacement && showPlacementDots) {
      // Prefer live tiger escape gaps (updated after every move), not all empties.
      final gaps = _engine.winByTrapOnly || tutorialAutoHints
          ? _engine.teachingPlacementGaps
          : _engine.placementTargets.toSet();
      validTargets = gaps.isNotEmpty ? gaps : _engine.placementTargets.toSet();
    } else if (tutorialAutoHints &&
        _engine.winByTrapOnly &&
        _engine.currentTurn == PieceType.goat &&
        _engine.isMovementPhase &&
        selected == null) {
      // Movement phase: glow current escape gaps so the player knows what to fill.
      validTargets = _engine.tigerEscapeGaps;
    }

    final nextHintMessage = hintMessage ??
        (clearHint && hintNodes == null ? null : _ui.activeHintMessage);

    Set<String> nextHintNodes;
    if (hintNodes != null) {
      nextHintNodes = hintNodes;
    } else if (clearHint) {
      nextHintNodes = const {};
    } else {
      nextHintNodes = _ui.hintHighlightNodes;
    }

    // Teaching trap levels: always refresh glowing gaps from the live board
    // (after tiger moves, old escape squares are wrong).
    final teachGaps = tutorialAutoHints &&
        _engine.winByTrapOnly &&
        _engine.winner == null &&
        _engine.currentTurn == PieceType.goat &&
        hintNodes == null;
    if (teachGaps) {
      nextHintNodes = _engine.isPlacementPhase && _engine.goatsToPlace > 0
          ? _engine.teachingPlacementGaps
          : _engine.tigerEscapeGaps;
    }

    _ui = UiGameState(
      pieces: pieces,
      currentTurn: _engine.currentTurn,
      validTargets: validTargets,
      selectedNode: selected,
      winner: _engine.winner,
      capturedGoats: _engine.capturedGoats,
      goatsToCaptureGoal: _engine.goatsToCaptureForTigerWin,
      initialGoatsOnBoard: _engine.initialGoatsOnBoard,
      goatsToPlaceTotal: _engine.totalGoats - _engine.initialGoatsOnBoard,
      winByTrapOnly: _engine.winByTrapOnly,
      board: _engine.board,
      invalidMoveMessage: clearInvalid ? null : _ui.invalidMoveMessage,
      activeHintMessage: teachGaps && nextHintNodes.isNotEmpty
          ? (hintMessage ??
              (_engine.isPlacementPhase
                  ? 'Place a goat on a glowing gap to block the tiger.'
                  : 'Fill a glowing gap — move a goat onto it.'))
          : nextHintMessage,
      hintHighlightNodes: nextHintNodes,
      showPlacementDots: showPlacementDots,
    );
  }

  bool _canPlaceGoatAt(String node) {
    return _engine.isPlacementPhase &&
        _engine.currentTurn == PieceType.goat &&
        _engine.goatsToPlace > 0 &&
        _engine.pieceAt(node) == null;
  }
}
