import 'package:flutter_test/flutter_test.dart';
import 'package:puli_meka_game_flutter/src/models/ai_difficulty.dart';
import 'package:puli_meka_game_flutter/src/models/campaign_level.dart';
import 'package:puli_meka_game_flutter/src/models/game_state.dart';
import 'package:puli_meka_game_flutter/src/services/campaign_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _openingJumps(GameState e) {
  var jumps = 0;
  for (final entry in e.pieceState.entries) {
    if (entry.value != PieceType.tiger) continue;
    for (final move in e.getTigerMoves(entry.key)) {
      if (move.isJump) jumps++;
    }
  }
  return jumps;
}

int _tigerMoveCount(GameState e) {
  var n = 0;
  for (final entry in e.pieceState.entries) {
    if (entry.value != PieceType.tiger) continue;
    n += e.getTigerMoves(entry.key).length;
  }
  return n;
}

void main() {
  test('20 campaign levels are well-formed', () {
    expect(CampaignLevels.all.length, CampaignLevels.count);
    expect(CampaignLevels.all.map((l) => l.id).toList(),
        List.generate(20, (i) => i + 1));

    for (final level in CampaignLevels.all) {
      final engine = level.createEngine();
      final tigers = level.rules.tigerStarts;
      final goats = level.rules.goatStarts;

      expect(engine.board.allNodes, isNotEmpty, reason: 'L${level.id}');
      expect(tigers, isNotEmpty, reason: 'L${level.id}');
      expect(tigers.toSet().length, tigers.length, reason: 'L${level.id} dup tigers');
      expect(goats.toSet().length, goats.length, reason: 'L${level.id} dup goats');
      expect(tigers.toSet().intersection(goats.toSet()), isEmpty,
          reason: 'L${level.id} overlapping starts');
      expect(engine.winner, isNull, reason: 'L${level.id} already over');
      expect(engine.areTigersTrapped(), isFalse, reason: 'L${level.id} trapped at start');
      expect(engine.totalGoats, greaterThanOrEqualTo(goats.length),
          reason: 'L${level.id} total goats');
      expect(_tigerMoveCount(engine), greaterThan(0), reason: 'L${level.id} tiger immobile');
    }
  });

  test('teaching levels 1-3 are step-only surround puzzles', () {
    for (final id in [1, 2, 3]) {
      final level = CampaignLevels.byId(id);
      expect(level.humanIsGoat, isTrue);
      expect(level.rules.winByTrapOnly, isTrue);
      expect(level.rules.allowTigerJumps, isFalse);
      expect(level.rules.firstTurn, PieceType.goat);
      expect(level.ai, AiDifficulty.tutorial);
      expect(_openingJumps(level.createEngine()), 0, reason: 'L$id opening jump');
    }

    final l1 = CampaignLevels.byId(1).createEngine();
    expect(l1.teachingPlacementGaps, {'r1-c2'});
    expect(l1.hasInstantTrapPlacement, isTrue);
    expect(l1.goatsToPlace, 1);
    expect(l1.applyPlacement('r1-c2'), isTrue);
    expect(l1.areTigersTrapped(), isTrue);
    expect(l1.winner, 'goats');
  });

  test('trapped tigers lose immediately, even mid-placement', () {
    final board = CampaignLevels.byId(1).board;
    final e = GameState.fromRules(
      board: board,
      rules: RuleSpec(
        totalGoats: 10,
        goatsToCapture: 5,
        winByTrapOnly: false,
        allowTigerJumps: false,
        tigerStarts: ['r0-c2'],
        goatStarts: [
          'r1-c1',
          'r1-c3',
          'r2-c0',
          'r2-c2',
          'r2-c4',
          'r4-c2',
        ],
        firstTurn: PieceType.goat,
      ),
    );
    expect(e.isPlacementPhase, isTrue);
    expect(e.goatsToPlace, greaterThan(1));
    expect(e.applyPlacement('r1-c2'), isTrue);
    expect(e.areTigersTrapped(), isTrue);
    expect(e.isPlacementPhase, isTrue);
    expect(e.winner, 'goats');
  });

  test('level 2 is a gradual surround, not a one-miss loss', () {
    final e = CampaignLevels.byId(2).createEngine();
    expect(e.allowTigerJumps, isFalse);
    expect(e.hasInstantTrapPlacement, isFalse);
    expect(e.goatsToPlace, greaterThanOrEqualTo(4));
    expect(e.tigerEscapeGaps.length, greaterThanOrEqualTo(4));

    final firstGap = e.tigerEscapeGaps.first;
    expect(e.applyPlacement(firstGap), isTrue);
    expect(e.areTigersTrapped(), isFalse);
    expect(e.winner, isNull);
    expect(e.goatsToPlace, greaterThan(0));
  });

  test('step-only rules ignore jump geometry', () {
    final e = CampaignLevels.byId(2).createEngine();
    // Adjacent goats would be jumpable if jumps were on.
    expect(_openingJumps(e), 0);
    e.applyPlacement(e.tigerEscapeGaps.first);
    expect(
      e.getTigerMoves('r2-c2').where((m) => m.isJump),
      isEmpty,
    );
  });

  test('goat-side levels 5, 7-10, 12-14, 16-17 have no opening jumps', () {
    for (final id in [5, 7, 8, 9, 10, 12, 13, 14, 16, 17]) {
      final level = CampaignLevels.byId(id);
      expect(level.humanIsGoat, isTrue, reason: 'L$id');
      expect(_openingJumps(level.createEngine()), 0, reason: 'L$id');
    }
  });

  test('tiger-side levels start with at least one jump', () {
    for (final id in [6, 11, 15, 19]) {
      final level = CampaignLevels.byId(id);
      expect(level.humanIsGoat, isFalse, reason: 'L$id');
      expect(level.rules.firstTurn, PieceType.tiger);
      expect(_openingJumps(level.createEngine()), greaterThan(0), reason: 'L$id');
    }
  });

  test('level 4 introduces jumping', () {
    final e = CampaignLevels.byId(4).createEngine();
    expect(e.allowTigerJumps, isTrue);
    expect(_openingJumps(e), 1);
    expect(e.currentTurn, PieceType.goat);
    expect(e.tigerEscapeGaps, contains('r0-c2'));
  });

  test('champion level uses classic rules', () {
    final level = CampaignLevels.byId(20);
    expect(level.boardId, 'classic');
    expect(level.rules.totalGoats, 23);
    expect(level.rules.goatsToCapture, 12);
    expect(level.ai, AiDifficulty.hard);
  });

  test('campaign win unlocks the next level and keeps best stars', () async {
    SharedPreferences.setMockInitialValues({});
    final service = CampaignProgressService.instance;

    expect(await service.highestUnlocked(), 1);

    final first = await service.recordWin(
      levelId: 1,
      capturedGoats: 2,
      goatsToCapture: 7,
      humanIsGoat: true,
    );
    expect(first, 2);
    expect(await service.highestUnlocked(), 2);
    expect(await service.starsFor(1), 2);

    final better = await service.recordWin(
      levelId: 1,
      capturedGoats: 0,
      goatsToCapture: 7,
      humanIsGoat: true,
    );
    expect(better, 3);
    expect(await service.starsFor(1), 3);
    expect(await service.highestUnlocked(), 2);
    expect(await service.totalStars(), 3);
    expect(CampaignProgressService.maxStars, 60);
  });
}
