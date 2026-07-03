import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puli_meka_game_flutter/src/models/game_result.dart';
import 'package:puli_meka_game_flutter/src/services/history_service.dart';

void main() {
  group('HistoryService', () {
    late HistoryService historyService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      historyService = HistoryService();
    });

    test('saves and loads a game result', () async {
      final result = GameResult(
        id: '1',
        mode: 'Offline',
        winner: 'Tigers',
        capturedGoats: 12,
        goatsPlaced: 23,
        playedAt: DateTime.utc(2026, 5, 23),
      );

      await historyService.saveResult(result);
      final loaded = await historyService.loadHistory();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, equals('1'));
      expect(loaded.first.mode, equals('Offline'));
      expect(loaded.first.winner, equals('Tigers'));
      expect(loaded.first.capturedGoats, equals(12));
      expect(loaded.first.goatsPlaced, equals(23));
      expect(loaded.first.playedAt, equals(DateTime.utc(2026, 5, 23)));
    });

    test('clears stored history', () async {
      final result = GameResult(
        id: '1',
        mode: 'AI',
        winner: 'Goats',
        capturedGoats: 0,
        goatsPlaced: 23,
        playedAt: DateTime.utc(2026, 5, 23),
      );

      await historyService.saveResult(result);
      await historyService.clearHistory();
      final loaded = await historyService.loadHistory();

      expect(loaded, isEmpty);
    });
  });
}
