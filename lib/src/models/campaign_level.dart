import 'ai_difficulty.dart';
import 'board_layout.dart';
import 'board_spec.dart';
import 'game_state.dart';

/// One level stage (difficulty is baked in — no picker).
class CampaignLevel {
  const CampaignLevel({
    required this.id,
    required this.title,
    required this.goalText,
    required this.boardId,
    required this.humanSide,
    required this.ai,
    required this.rules,
  });

  final int id;
  final String title;
  final String goalText;
  final String boardId;
  final PieceType humanSide;
  final AiDifficulty ai;
  final RuleSpec rules;

  BoardSpec get board =>
      boardId == 'classic' ? BoardLayout.asSpec() : BoardSpec.byId(boardId);

  bool get humanIsGoat => humanSide == PieceType.goat;

  /// Levels 1–4 glow recommended gaps. Only an instant-win tap is locked.
  bool get usesTeachingHints => id <= 4;

  GameState createEngine() => GameState.fromRules(board: board, rules: rules);
}

/// All 20 levels — sparse starts (tiger has room); goats arrive from hand.
class CampaignLevels {
  CampaignLevels._();

  static const int count = 20;

  static CampaignLevel byId(int id) {
    for (final level in all) {
      if (level.id == id) return level;
    }
    throw ArgumentError('Unknown level $id');
  }

  static final List<CampaignLevel> all = [
    // —— Seed (1–7) ——
    // 1–3: tigers only step (no jumps). Surround is gradual, not a jump puzzle.
    CampaignLevel(
      id: 1,
      title: 'First steps',
      goalText: 'Place a goat on the glowing square to trap the tiger',
      boardId: 'seed',
      humanSide: PieceType.goat,
      ai: AiDifficulty.tutorial,
      rules: RuleSpec(
        totalGoats: 7,
        goatsToCapture: 7,
        winByTrapOnly: true,
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
    ),
    CampaignLevel(
      id: 2,
      title: 'Close in',
      goalText: 'Fill empty squares next to the tiger — it can only step, not jump',
      boardId: 'seed',
      humanSide: PieceType.goat,
      ai: AiDifficulty.tutorial,
      rules: RuleSpec(
        totalGoats: 10,
        goatsToCapture: 10,
        winByTrapOnly: true,
        allowTigerJumps: false,
        tigerStarts: ['r2-c2'],
        goatStarts: [
          'r0-c2',
          'r2-c0',
          'r2-c4',
          'r4-c2',
        ],
        firstTurn: PieceType.goat,
      ),
    ),
    CampaignLevel(
      id: 3,
      title: 'Keep surrounding',
      goalText: 'Keep filling gaps beside the tiger. A miss is not fatal — it cannot jump',
      boardId: 'seed',
      humanSide: PieceType.goat,
      ai: AiDifficulty.tutorial,
      rules: RuleSpec(
        totalGoats: 10,
        goatsToCapture: 10,
        winByTrapOnly: true,
        allowTigerJumps: false,
        tigerStarts: ['r4-c2'],
        goatStarts: [
          'r0-c2',
          'r2-c0',
          'r2-c2',
          'r2-c4',
        ],
        firstTurn: PieceType.goat,
      ),
    ),
    CampaignLevel(
      id: 4,
      title: 'Watch the jump',
      goalText: 'The tiger can jump now — occupy the landing square to stop a capture',
      boardId: 'seed',
      humanSide: PieceType.goat,
      ai: AiDifficulty.easy,
      rules: RuleSpec(
        totalGoats: 10,
        goatsToCapture: 6,
        tigerStarts: ['r2-c0'],
        goatStarts: [
          'r1-c1',
          'r2-c2',
          'r2-c4',
          'r4-c2',
        ],
        firstTurn: PieceType.goat,
      ),
    ),
    CampaignLevel(
      id: 5,
      title: 'Herd master',
      goalText: 'Trap the tiger on the seed board',
      boardId: 'seed',
      humanSide: PieceType.goat,
      ai: AiDifficulty.easy,
      rules: RuleSpec(
        totalGoats: 11,
        goatsToCapture: 6,
        allowTigerJumps: true,
        tigerStarts: ['r2-c2'],
        goatStarts: [
          'r0-c2',
          'r2-c0',
          'r2-c4',
          'r4-c2',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 6,
      title: "Tiger's turn",
      goalText: 'Jump to capture 2 goats',
      boardId: 'seed',
      humanSide: PieceType.tiger,
      ai: AiDifficulty.tutorial,
      rules: RuleSpec(
        totalGoats: 6,
        goatsToCapture: 2,
        tigerStarts: ['r2-c2'],
        goatStarts: [
          'r2-c1',
          'r2-c3',
          'r3-c1',
          'r3-c3',
          'r4-c2',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 7,
      title: 'Seed finale',
      goalText: 'Trap the tiger before it takes 5 goats',
      boardId: 'seed',
      humanSide: PieceType.goat,
      ai: AiDifficulty.easy,
      rules: RuleSpec(
        totalGoats: 11,
        goatsToCapture: 5,
        tigerStarts: ['r0-c2'],
        goatStarts: [
          'r1-c1',
          'r2-c0',
          'r2-c1',
          'r2-c3',
          'r2-c4',
          'r4-c2',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    // —— Grove (8–13): 23-node board ——
    CampaignLevel(
      id: 8,
      title: 'Into the grove',
      goalText: 'New board — the tiger still only steps. Surround it with your herd',
      boardId: 'grove',
      humanSide: PieceType.goat,
      ai: AiDifficulty.easy,
      rules: RuleSpec(
        totalGoats: 12,
        goatsToCapture: 12,
        winByTrapOnly: true,
        allowTigerJumps: false,
        tigerStarts: ['r2-c3'],
        goatStarts: [
          'r0-c3',
          'r1-c1',
          'r1-c5',
          'r2-c0',
          'r2-c6',
          'r4-c3',
        ],
        firstTurn: PieceType.goat,
      ),
    ),
    CampaignLevel(
      id: 9,
      title: 'Growing herd',
      goalText: 'Place goats and corner the tiger',
      boardId: 'grove',
      humanSide: PieceType.goat,
      ai: AiDifficulty.easy,
      rules: RuleSpec(
        totalGoats: 12,
        goatsToCapture: 5,
        tigerStarts: ['r0-c3'],
        goatStarts: [
          'r1-c1',
          'r1-c5',
          'r2-c2',
          'r2-c4',
          'r3-c3',
          'r4-c3',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 10,
      title: 'Two paths',
      goalText: 'Trap the tiger with your herd',
      boardId: 'grove',
      humanSide: PieceType.goat,
      ai: AiDifficulty.medium,
      rules: RuleSpec(
        totalGoats: 12,
        goatsToCapture: 5,
        tigerStarts: ['r2-c3'],
        goatStarts: [
          'r0-c2',
          'r0-c4',
          'r1-c1',
          'r2-c0',
          'r2-c6',
          'r4-c2',
          'r4-c4',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 11,
      title: 'Hunter lesson',
      goalText: 'Capture 3 goats as the tiger',
      boardId: 'grove',
      humanSide: PieceType.tiger,
      ai: AiDifficulty.easy,
      rules: RuleSpec(
        totalGoats: 8,
        goatsToCapture: 3,
        tigerStarts: ['r2-c3'],
        goatStarts: [
          'r0-c2',
          'r0-c4',
          'r2-c2',
          'r2-c4',
          'r3-c1',
          'r3-c5',
          'r4-c3',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 12,
      title: 'Twin threat',
      goalText: 'Survive two tigers — trap them both',
      boardId: 'grove',
      humanSide: PieceType.goat,
      ai: AiDifficulty.medium,
      rules: RuleSpec(
        totalGoats: 14,
        goatsToCapture: 6,
        tigerStarts: ['r1-c2', 'r1-c4'],
        goatStarts: [
          'r0-c3',
          'r2-c0',
          'r2-c6',
          'r3-c1',
          'r3-c5',
          'r4-c2',
          'r4-c4',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 13,
      title: 'Grove guardian',
      goalText: 'Trap both tigers',
      boardId: 'grove',
      humanSide: PieceType.goat,
      ai: AiDifficulty.medium,
      rules: RuleSpec(
        totalGoats: 14,
        goatsToCapture: 6,
        tigerStarts: ['r2-c0', 'r2-c6'],
        goatStarts: [
          'r0-c3',
          'r1-c2',
          'r1-c4',
          'r2-c3',
          'r3-c2',
          'r3-c4',
          'r4-c3',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    // —— Arena (14–17): 37-node board ——
    CampaignLevel(
      id: 14,
      title: 'Open arena',
      goalText: 'Trap both tigers',
      boardId: 'arena',
      humanSide: PieceType.goat,
      ai: AiDifficulty.medium,
      rules: RuleSpec(
        totalGoats: 14,
        goatsToCapture: 6,
        tigerStarts: ['r2-c2', 'r2-c6'],
        goatStarts: [
          'r0-c4',
          'r1-c3',
          'r1-c5',
          'r2-c4',
          'r3-c3',
          'r3-c5',
          'r4-c4',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 15,
      title: 'Arena hunt',
      goalText: 'Capture 4 goats as the tiger',
      boardId: 'arena',
      humanSide: PieceType.tiger,
      ai: AiDifficulty.medium,
      rules: RuleSpec(
        totalGoats: 10,
        goatsToCapture: 4,
        tigerStarts: ['r2-c4'],
        goatStarts: [
          'r1-c2',
          'r1-c4',
          'r1-c6',
          'r2-c1',
          'r2-c7',
          'r3-c2',
          'r3-c4',
          'r3-c6',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 16,
      title: 'Pressure cook',
      goalText: 'Trap both tigers before 6 captures',
      boardId: 'arena',
      humanSide: PieceType.goat,
      ai: AiDifficulty.medium,
      rules: RuleSpec(
        totalGoats: 15,
        goatsToCapture: 6,
        tigerStarts: ['r1-c2', 'r1-c6'],
        goatStarts: [
          'r0-c4',
          'r2-c1',
          'r2-c4',
          'r2-c7',
          'r3-c3',
          'r3-c5',
          'r4-c4',
          'r1-c4',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 17,
      title: 'Arena master',
      goalText: 'Trap both tigers',
      boardId: 'arena',
      humanSide: PieceType.goat,
      ai: AiDifficulty.hard,
      rules: RuleSpec(
        totalGoats: 15,
        goatsToCapture: 6,
        tigerStarts: ['r2-c0', 'r2-c8'],
        goatStarts: [
          'r0-c4',
          'r1-c3',
          'r1-c5',
          'r2-c3',
          'r2-c5',
          'r3-c3',
          'r3-c5',
          'r4-c4',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    // —— Classic (18–20): traditional 41-node board ——
    CampaignLevel(
      id: 18,
      title: 'Classic grounds',
      goalText: 'Trap both tigers on the full board',
      boardId: 'classic',
      humanSide: PieceType.goat,
      ai: AiDifficulty.medium,
      rules: RuleSpec(
        totalGoats: 15,
        goatsToCapture: 8,
        tigerStarts: ['r2-c2', 'r2-c6'],
        goatStarts: [
          'r1-c4',
          'r2-c3',
          'r2-c5',
          'r3-c4',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 19,
      title: 'Tiger king',
      goalText: 'Capture 6 goats as the tiger',
      boardId: 'classic',
      humanSide: PieceType.tiger,
      ai: AiDifficulty.hard,
      rules: RuleSpec(
        totalGoats: 12,
        goatsToCapture: 6,
        tigerStarts: ['r2-c2', 'r2-c6'],
        goatStarts: [
          'r1-c4',
          'r2-c3',
          'r2-c5',
          'r3-c4',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
    CampaignLevel(
      id: 20,
      title: 'Puli Meka champion',
      goalText: 'Win a full classic match — trap both tigers',
      boardId: 'classic',
      humanSide: PieceType.goat,
      ai: AiDifficulty.hard,
      rules: RuleSpec(
        totalGoats: 23,
        goatsToCapture: 12,
        tigerStarts: ['r2-c2', 'r2-c6'],
        goatStarts: [
          'r1-c4',
          'r2-c3',
          'r2-c5',
          'r3-c4',
        ],
        firstTurn: PieceType.tiger,
      ),
    ),
  ];
}
