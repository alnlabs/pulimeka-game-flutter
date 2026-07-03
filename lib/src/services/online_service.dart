import 'dart:async';
import 'dart:math';

import '../models/game_state.dart';

class OnlineRoom {
  final String roomId;
  final String ownerId;
  String? guestId;
  final GameState gameState;
  bool started = false;
  final StreamController<OnlineRoom> _controller;

  OnlineRoom({required this.roomId, required this.ownerId})
      : gameState = GameState.initial(),
        _controller = StreamController<OnlineRoom>.broadcast() {
    _controller.add(this);
  }

  Stream<OnlineRoom> get updates => _controller.stream;

  PieceType? roleFor(String playerId) {
    if (playerId == ownerId) return PieceType.tiger;
    if (playerId == guestId) return PieceType.goat;
    return null;
  }

  void join(String guestId) {
    if (this.guestId != null) {
      throw StateError('Room already has a guest');
    }
    this.guestId = guestId;
    started = true;
    _notify();
  }

  void updateState() {
    _notify();
  }

  void dispose() {
    _controller.close();
  }

  void _notify() {
    if (!_controller.isClosed) {
      _controller.add(this);
    }
  }
}

class OnlineService {
  static final OnlineService _instance = OnlineService._internal();
  final Map<String, OnlineRoom> _rooms = {};
  final Random _random = Random();

  OnlineService._internal();

  factory OnlineService() => _instance;

  Future<OnlineRoom> createGameRoom(String ownerId) async {
    final roomId = _generateRoomId();
    final room = OnlineRoom(roomId: roomId, ownerId: ownerId);
    _rooms[roomId] = room;
    return room;
  }

  Future<OnlineRoom> joinGameRoom(String roomId, String guestId) async {
    final room = _rooms[roomId];
    if (room == null) {
      throw StateError('Room not found');
    }
    if (room.guestId != null) {
      throw StateError('Room already full');
    }
    room.join(guestId);
    return room;
  }

  OnlineRoom? getRoom(String roomId) => _rooms[roomId];

  String _generateRoomId() {
    return (100000 + _random.nextInt(900000)).toString();
  }
}
