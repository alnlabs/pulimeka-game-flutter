import 'package:shared_preferences/shared_preferences.dart';

/// Player identity and active online session (matches Android `puli_meka_prefs`).
class OnlineSessionPrefs {
  OnlineSessionPrefs._();

  static const _playerId = 'player_id';
  static const _playerName = 'player_name';
  static const _activeRoomId = 'active_room_id';
  static const _activePlayerId = 'active_player_id';
  static const _activeIsHost = 'active_is_host';
  static const _activePlayerRole = 'active_player_role';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<String> getPlayerId() async {
    final prefs = await _prefs;
    var id = prefs.getString(_playerId);
    if (id == null || id.isEmpty) {
      final uuid = DateTime.now().millisecondsSinceEpoch;
      id = 'player_${uuid}_${uuid % 1000000000}';
      await prefs.setString(_playerId, id);
    }
    return id;
  }

  static Future<String> getPlayerName() async {
    final prefs = await _prefs;
    return prefs.getString(_playerName) ?? 'Player';
  }

  static Future<void> setPlayerName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_playerName, name.trim().isEmpty ? 'Player' : name.trim());
  }

  static Future<void> saveActiveSession({
    required String roomId,
    required String playerId,
    required bool isHost,
    required String playerRole,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_activeRoomId, roomId);
    await prefs.setString(_activePlayerId, playerId);
    await prefs.setBool(_activeIsHost, isHost);
    await prefs.setString(_activePlayerRole, playerRole);
  }

  static Future<void> clearActiveSession() async {
    final prefs = await _prefs;
    await prefs.remove(_activeRoomId);
    await prefs.remove(_activePlayerId);
    await prefs.remove(_activeIsHost);
    await prefs.remove(_activePlayerRole);
  }

  static Future<ActiveOnlineSession?> getActiveSession() async {
    final prefs = await _prefs;
    final roomId = prefs.getString(_activeRoomId);
    final playerId = prefs.getString(_activePlayerId);
    final role = prefs.getString(_activePlayerRole);
    if (roomId == null ||
        roomId.isEmpty ||
        playerId == null ||
        playerId.isEmpty ||
        role == null ||
        role.isEmpty) {
      return null;
    }
    return ActiveOnlineSession(
      roomId: roomId,
      playerId: playerId,
      isHost: prefs.getBool(_activeIsHost) ?? false,
      playerRole: role,
    );
  }
}

class ActiveOnlineSession {
  const ActiveOnlineSession({
    required this.roomId,
    required this.playerId,
    required this.isHost,
    required this.playerRole,
  });

  final String roomId;
  final String playerId;
  final bool isHost;
  final String playerRole;
}
