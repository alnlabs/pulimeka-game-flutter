import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/game_state.dart';
import '../services/firebase_game_state_codec.dart';
import '../services/online_game_service.dart';

/// Real-time online match synced via Firebase (Android `OnlineGameViewModel`).
class OnlineGameController extends ChangeNotifier {
  OnlineGameController({
    required this.roomId,
    required this.playerId,
    required this.playerRole,
    required this.isHost,
  }) : _gameState = GameState.initial();

  final String roomId;
  final String playerId;
  final String playerRole;
  final bool isHost;

  final GameState _gameState;
  int _moveCount = 0;
  String? _selectedNode;
  bool _isSyncing = false;
  bool _gameReady = false;
  bool _hostInitStarted = false;
  String? _error;

  StreamSubscription? _gameSub;

  GameState get gameState => _gameState;
  String? get selectedNode => _selectedNode;
  bool get isLoading => !_gameReady && _error == null;
  String? get error => _error;
  bool get isMyTurn {
    if (_gameState.winner != null) return false;
    return switch (playerRole) {
      'tiger' => _gameState.currentTurn == PieceType.tiger,
      'goat' => _gameState.currentTurn == PieceType.goat,
      _ => false,
    };
  }

  Set<String> get validTargets {
    if (_selectedNode == null || !isMyTurn) return {};
    return _gameState.getValidTargets(_selectedNode!);
  }

  void start() {
    _gameSub = OnlineGameService.instance.subscribeToGameState(
      roomId,
      _onFirebaseState,
    );
  }

  void _onFirebaseState(Map<String, dynamic>? data) {
    if (data == null) {
      if (isHost && !_hostInitStarted) {
        _hostInitStarted = true;
        _initializeHostGame();
      }
      return;
    }

    final lastMoveBy = data['lastMoveBy']?.toString();
    final remoteMoveCount =
        FirebaseGameStateCodec.parseIntField(data['moveCount']) ?? 0;

    if (_isSyncing && lastMoveBy == playerId) {
      _isSyncing = false;
      _gameReady = true;
      _error = null;
      notifyListeners();
      return;
    }

    // Drop out-of-order snapshots (e.g. merged RTDB state from before our move).
    if (remoteMoveCount < _moveCount) {
      return;
    }

    _applyFirebase(data);
    _gameReady = true;
    _error = null;
    notifyListeners();
  }

  Future<void> _initializeHostGame() async {
    try {
      await OnlineGameService.instance.initializeGameState(roomId);
    } catch (e) {
      _error = 'Failed to initialize game: $e';
      notifyListeners();
    }
  }

  void _applyFirebase(Map<String, dynamic> data) {
    final loaded = FirebaseGameStateCodec.fromFirebase(data);
    _gameState.pieceState
      ..clear()
      ..addAll(loaded.pieceState);
    _gameState.currentTurn = loaded.currentTurn;
    _gameState.gamePhase = loaded.gamePhase;
    _gameState.goatsToPlace = loaded.goatsToPlace;
    _gameState.capturedGoats = loaded.capturedGoats;
    _gameState.winner = loaded.winner;
    _moveCount = FirebaseGameStateCodec.parseIntField(data['moveCount']) ??
        _moveCount;
    _selectedNode = null;
  }

  void onNodeTap(String node) {
    if (!isMyTurn || _gameState.winner != null) return;

    if (_selectedNode == null &&
        _gameState.isPlacementPhase &&
        _gameState.currentTurn == PieceType.goat &&
        playerRole == 'goat' &&
        _gameState.pieceAt(node) == null &&
        _gameState.goatsToPlace > 0) {
      _gameState.applyPlacement(node);
      _moveCount++;
      _pushState();
      return;
    }

    if (_selectedNode == null) {
      final piece = _gameState.pieceAt(node);
      final myPiece =
          playerRole == 'tiger' ? PieceType.tiger : PieceType.goat;
      if (piece == myPiece) {
        _selectedNode = node;
        notifyListeners();
      }
      return;
    }

    if (node == _selectedNode) {
      _selectedNode = null;
      notifyListeners();
      return;
    }

    if (validTargets.contains(node)) {
      _gameState.applyMove(_selectedNode!, node);
      _moveCount++;
      _selectedNode = null;
      _pushState();
      return;
    }

    final piece = _gameState.pieceAt(node);
    final myPiece = playerRole == 'tiger' ? PieceType.tiger : PieceType.goat;
    if (piece == myPiece) {
      _selectedNode = node;
    } else {
      _selectedNode = null;
    }
    notifyListeners();
  }

  Future<void> _pushState() async {
    try {
      _isSyncing = true;
      final map = FirebaseGameStateCodec.toFirebase(
        state: _gameState,
        playerId: playerId,
        moveCount: _moveCount,
      );
      await OnlineGameService.instance.updateGameState(roomId, map);
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _error = 'Error syncing move: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    super.dispose();
  }
}
