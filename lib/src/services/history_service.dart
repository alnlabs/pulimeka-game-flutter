import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_result.dart';
import '../models/leaderboard_entry.dart';

class HistoryService {
  static const String _historyKey = 'game_history';
  static const String _leaderboardKey = 'leaderboard';
  static final HistoryService _instance = HistoryService._internal();

  HistoryService._internal();

  factory HistoryService() => _instance;

  Future<List<GameResult>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final data = json.decode(jsonString) as List<dynamic>;
    final list = data
        .whereType<Map<String, dynamic>>()
        .map(GameResult.fromJson)
        .toList();
    if (list.length > 100) {
      return list.take(100).toList();
    }
    return list;
  }

  Future<List<LeaderboardEntry>> loadLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_leaderboardKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final data = json.decode(jsonString) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(LeaderboardEntry.fromJson)
        .toList()
      ..sort((a, b) => b.wins.compareTo(a.wins));
  }

  Future<void> saveResult(
    GameResult result, {
    required String playerName,
    required bool humanWon,
    bool isDraw = false,
  }) async {
    final history = await loadHistory();
    history.insert(0, result);
    final trimmed = history.take(100).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      json.encode(trimmed.map((r) => r.toJson()).toList()),
    );

    await _updateLeaderboard(
      playerName: playerName,
      humanWon: humanWon,
      isDraw: isDraw,
    );
  }

  Future<void> _updateLeaderboard({
    required String playerName,
    required bool humanWon,
    required bool isDraw,
  }) async {
    final name = playerName.trim().isEmpty ? 'Player' : playerName.trim();
    final key = name.toLowerCase();
    var board = await loadLeaderboard();
    final index = board.indexWhere((e) => e.canonicalKey == key);
    final now = DateTime.now();

    LeaderboardEntry entry;
    if (index >= 0) {
      final existing = board[index];
      entry = existing.copyWith(
        playerName: name,
        wins: existing.wins + (humanWon && !isDraw ? 1 : 0),
        losses: existing.losses + (!humanWon && !isDraw ? 1 : 0),
        draws: existing.draws + (isDraw ? 1 : 0),
        lastPlayed: now,
      );
      board[index] = entry;
    } else {
      entry = LeaderboardEntry(
        playerName: name,
        wins: humanWon && !isDraw ? 1 : 0,
        losses: !humanWon && !isDraw ? 1 : 0,
        draws: isDraw ? 1 : 0,
        lastPlayed: now,
      );
      board.add(entry);
    }

    board.sort((a, b) {
      if (b.wins != a.wins) return b.wins.compareTo(a.wins);
      return b.lastPlayed.compareTo(a.lastPlayed);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _leaderboardKey,
      json.encode(board.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await prefs.remove(_leaderboardKey);
  }
}
