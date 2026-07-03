import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../config/online_config.dart';
import 'firebase_game_state_codec.dart';
import 'online_session_prefs.dart';

typedef RoomData = Map<String, dynamic>;
typedef RoomListener = void Function(RoomData? room);
typedef RoomsListener = void Function(List<RoomData> rooms);
typedef GameStateListener = void Function(Map<String, dynamic>? state);

/// Firebase multiplayer — port of Android `OnlineGameService`.
class OnlineGameService {
  OnlineGameService._();
  static final OnlineGameService instance = OnlineGameService._();

  DatabaseReference? _root;

  DatabaseReference get root {
    _root ??= FirebaseDatabase.instance.ref();
    return _root!;
  }

  bool get isAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  DatabaseReference _roomsRef() => root.child(OnlineConfig.roomsPath);
  DatabaseReference _gamesRef() => root.child(OnlineConfig.gamesPath);

  static int? _asLong(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _isWaitingRoomExpired(RoomData room, {int? nowMs}) {
    final status = room['status']?.toString();
    if (status != 'waiting') return false;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final ts = _asLong(room['lastActivityAt']) ??
        _asLong(room['updatedAt']) ??
        _asLong(room['createdAt']);
    if (ts == null) return false;
    return now - ts > OnlineConfig.waitingRoomTtlMs;
  }

  static RoomData? _normalizeRoom(String roomId, dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(
      raw.map((k, v) => MapEntry(k.toString(), v)),
    );
    map['roomId'] = roomId;
    return map;
  }

  Future<void> tryResumeActiveSession({
    required void Function(ActiveOnlineSession session) onSuccess,
    required VoidCallback onUnavailable,
  }) async {
    final session = await OnlineSessionPrefs.getActiveSession();
    if (session == null || !isAvailable) {
      onUnavailable();
      return;
    }

    try {
      final snap = await _roomsRef().child(session.roomId).get();
      if (!snap.exists || snap.value == null) {
        await OnlineSessionPrefs.clearActiveSession();
        onUnavailable();
        return;
      }
      final room = _normalizeRoom(session.roomId, snap.value)!;
      if (_isWaitingRoomExpired(room)) {
        await OnlineSessionPrefs.clearActiveSession();
        onUnavailable();
        return;
      }
      final hostId = room['hostId']?.toString();
      final guestId = room['guestId']?.toString();
      if (hostId != session.playerId && guestId != session.playerId) {
        await OnlineSessionPrefs.clearActiveSession();
        onUnavailable();
        return;
      }
      onSuccess(session);
    } catch (e) {
      debugPrint('Resume session failed: $e');
      onUnavailable();
    }
  }

  Future<String> createRoom({
    required String playerId,
    required String playerName,
    String playerRole = 'tiger',
  }) async {
    final uuid = DateTime.now().millisecondsSinceEpoch;
    final roomId = 'room_${uuid}_${uuid % 1000000000}';
    final guestRole = playerRole == 'tiger' ? 'goat' : 'tiger';

    final roomData = {
      'roomId': roomId,
      'hostId': playerId,
      'hostName': playerName,
      'hostRole': playerRole,
      'guestId': null,
      'guestName': null,
      'guestRole': guestRole,
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
      'lastActivityAt': ServerValue.timestamp,
      'hostLastActivityAt': ServerValue.timestamp,
      'guestLastActivityAt': null,
    };

    await _roomsRef().child(roomId).set(roomData);
    return roomId;
  }

  Future<RoomData> joinRoom({
    required String roomId,
    required String playerId,
    required String playerName,
  }) async {
    final ref = _roomsRef().child(roomId);
    String? rejection;

    final result = await ref.runTransaction((current) {
      if (current == null) {
        rejection =
            'Room not found. The room may have been deleted or the room code is incorrect.';
        return Transaction.abort();
      }

      final room = Map<String, dynamic>.from(current as Map);
      final guestId = room['guestId'];
      if (guestId != null && guestId.toString().isNotEmpty) {
        rejection = 'Room is full. Another player has already joined.';
        return Transaction.abort();
      }
      if (room['hostId']?.toString() == playerId) {
        rejection =
            'You are already the host of this room. Please join as a guest from another device.';
        return Transaction.abort();
      }
      if (room['status']?.toString() != 'waiting') {
        rejection =
            'Room is not available. Status: ${room['status'] ?? 'unknown'}';
        return Transaction.abort();
      }
      if (_isWaitingRoomExpired(room)) {
        rejection = 'Room expired. Please create or join a newer room.';
        return Transaction.abort();
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      room['guestId'] = playerId;
      room['guestName'] = playerName;
      room['status'] = 'playing';
      room['updatedAt'] = now;
      room['lastActivityAt'] = now;
      room['guestLastActivityAt'] = now;
      return Transaction.success(room);
    });

    if (!result.committed) {
      throw StateError(
        rejection ?? 'Room is no longer available. Please try a different room.',
      );
    }

    final value = result.snapshot.value;
    if (value is! Map) {
      throw StateError('Joined room, but failed to read updated room state.');
    }
    return _normalizeRoom(roomId, value)!;
  }

  Future<void> leaveRoom(String roomId, String playerId) async {
    final snap = await _roomsRef().child(roomId).get();
    if (!snap.exists || snap.value == null) return;
    final room = Map<String, dynamic>.from(snap.value as Map);

    if (room['hostId']?.toString() == playerId) {
      await _gamesRef().child(roomId).remove();
      await _roomsRef().child(roomId).remove();
      return;
    }

    if (room['guestId']?.toString() == playerId) {
      await _roomsRef().child(roomId).update({
        'guestId': null,
        'guestName': null,
        'status': 'waiting',
        'updatedAt': ServerValue.timestamp,
        'lastActivityAt': ServerValue.timestamp,
      });
    }
  }

  Future<void> cancelRoom(String roomId, String playerId) async {
    final snap = await _roomsRef().child(roomId).get();
    if (!snap.exists || snap.value == null) {
      throw StateError('Room not found');
    }
    final room = Map<String, dynamic>.from(snap.value as Map);
    if (room['hostId']?.toString() != playerId) {
      throw StateError('Only the host can cancel the game');
    }
    await _gamesRef().child(roomId).remove();
    await _roomsRef().child(roomId).remove();
  }

  Future<void> deleteMyRooms(String playerId) async {
    if (playerId.isEmpty) return;
    final snap = await _roomsRef().get();
    if (!snap.exists || snap.value == null) return;
    final rooms = snap.value as Map;
    for (final entry in rooms.entries) {
      final roomId = entry.key.toString();
      if (entry.value is! Map) continue;
      final room = Map<String, dynamic>.from(entry.value as Map);
      if (room['hostId']?.toString() == playerId) {
        await _gamesRef().child(roomId).remove();
        await _roomsRef().child(roomId).remove();
      }
    }
  }

  StreamSubscription<DatabaseEvent> subscribeToRoom(
    String roomId,
    RoomListener onUpdate,
  ) {
    return _roomsRef().child(roomId).onValue.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        onUpdate(null);
        return;
      }
      final room = _normalizeRoom(roomId, event.snapshot.value)!;
      if (_isWaitingRoomExpired(room)) {
        _roomsRef().child(roomId).remove();
        _gamesRef().child(roomId).remove();
        onUpdate(null);
        return;
      }
      onUpdate(room);
    });
  }

  StreamSubscription<DatabaseEvent> subscribeToAvailableRooms(
    RoomsListener onUpdate,
  ) {
    return _roomsRef().onValue.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        onUpdate([]);
        return;
      }
      final raw = event.snapshot.value as Map;
      final now = DateTime.now().millisecondsSinceEpoch;
      final list = <RoomData>[];
      for (final entry in raw.entries) {
        final roomId = entry.key.toString();
        if (entry.value is! Map) continue;
        final room = _normalizeRoom(roomId, entry.value)!;
        if (_isWaitingRoomExpired(room, nowMs: now)) {
          _roomsRef().child(roomId).remove();
          _gamesRef().child(roomId).remove();
          continue;
        }
        if (room['status'] == 'waiting' &&
            (room['guestId'] == null || room['guestId'].toString().isEmpty)) {
          list.add(room);
        }
      }
      onUpdate(list);
    });
  }

  Future<void> updatePlayerName({
    required String roomId,
    required String playerId,
    required String playerName,
  }) async {
    final snap = await _roomsRef().child(roomId).get();
    if (!snap.exists || snap.value == null) {
      throw StateError('Room not found');
    }
    final room = Map<String, dynamic>.from(snap.value as Map);
    final updates = <String, dynamic>{
      'updatedAt': ServerValue.timestamp,
      'lastActivityAt': ServerValue.timestamp,
    };
    if (room['hostId']?.toString() == playerId) {
      updates['hostName'] = playerName;
      updates['hostLastActivityAt'] = ServerValue.timestamp;
    } else if (room['guestId']?.toString() == playerId) {
      updates['guestName'] = playerName;
      updates['guestLastActivityAt'] = ServerValue.timestamp;
    } else {
      throw StateError('You are not in this room');
    }
    await _roomsRef().child(roomId).update(updates);
  }

  Future<void> updateRoomActivity(String roomId, String playerId) async {
    final snap = await _roomsRef().child(roomId).get();
    if (!snap.exists || snap.value == null) return;
    final room = Map<String, dynamic>.from(snap.value as Map);
    final updates = <String, dynamic>{
      'lastActivityAt': ServerValue.timestamp,
    };
    if (room['hostId']?.toString() == playerId) {
      updates['hostLastActivityAt'] = ServerValue.timestamp;
    } else if (room['guestId']?.toString() == playerId) {
      updates['guestLastActivityAt'] = ServerValue.timestamp;
    }
    await _roomsRef().child(roomId).update(updates);
  }

  Future<void> initializeGameState(String roomId) async {
    final data = FirebaseGameStateCodec.createInitialFirebaseMap();
    data['updatedAt'] = ServerValue.timestamp;
    await _gamesRef().child(roomId).set(data);
  }

  Future<void> updateGameState(String roomId, Map<String, dynamic> state) async {
    final payload = Map<String, dynamic>.from(state);
    payload['updatedAt'] = ServerValue.timestamp;
    // Full replace so pieceState does not keep stale tiger/goat keys (RTDB merge + null omit).
    await _gamesRef().child(roomId).set(payload);
    await _roomsRef().child(roomId).update({
      'lastActivityAt': ServerValue.timestamp,
    });
  }

  StreamSubscription<DatabaseEvent> subscribeToGameState(
    String roomId,
    GameStateListener onUpdate,
  ) {
    return _gamesRef().child(roomId).onValue.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        onUpdate(null);
        return;
      }
      final raw = event.snapshot.value;
      if (raw is Map) {
        onUpdate(Map<String, dynamic>.from(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        ));
      } else {
        onUpdate(null);
      }
    });
  }

  Future<void> deleteGameState(String roomId) async {
    await _gamesRef().child(roomId).remove();
  }
}
