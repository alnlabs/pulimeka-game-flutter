import 'package:flutter/foundation.dart';

import '../models/game_constants.dart';
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
  final String? invalidMoveMessage;
  final String? activeHintMessage;
  final Set<String> hintHighlightNodes;
  final bool showPlacementDots;

  int get goatsOnBoard => pieces.where((p) => p.type == PieceType.goat).length;

  int get goatsToPlaceTotal => GameConstants.totalGoats - GameConstants.initialGoats;

  int get goatsPlacedFromHand {
    final placed = goatsOnBoard + capturedGoats - GameConstants.initialGoats;
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
  GameController() {
    _syncFromEngine(selected: null);
  }

  final GameState _engine = GameState.initial();
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

  /// Direct engine updates for AI / automation (skips tap validation messages).
  void applyPlacementDirect(String node) {
    if (_ui.winner != null) return;
    if (!_engine.applyPlacement(node)) return;
    _syncFromEngine(selected: null, clearInvalid: true);
    notifyListeners();
  }

  void applyMoveDirect(String from, String to) {
    if (_ui.winner != null) return;
    if (!_engine.applyMove(from, to)) return;
    _syncFromEngine(selected: null, clearInvalid: true);
    notifyListeners();
  }

  void onNodeTapped(String node) {
    if (_ui.winner != null) return;

    final selected = _ui.selectedNode;

    // Place goats from hand on goat's turn (tap empty node; selection not required).
    if (_canPlaceGoatAt(node)) {
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
      validTargets = _engine.placementTargets.toSet();
    }

    final nextHintMessage = hintMessage ??
        (clearHint && hintNodes == null ? null : _ui.activeHintMessage);
    final nextHintNodes = hintNodes ??
        (clearHint ? const <String>{} : _ui.hintHighlightNodes);

    _ui = UiGameState(
      pieces: pieces,
      currentTurn: _engine.currentTurn,
      validTargets: validTargets,
      selectedNode: selected,
      winner: _engine.winner,
      capturedGoats: _engine.capturedGoats,
      invalidMoveMessage: clearInvalid ? null : _ui.invalidMoveMessage,
      activeHintMessage: nextHintMessage,
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
