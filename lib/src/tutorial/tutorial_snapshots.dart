import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../models/game_constants.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

/// Three-step tutorial: one board diagram, then plain-text rules.
class TutorialSnapshots {
  TutorialSnapshots._();

  static const List<BoardPiece> _openingPieces = [
    BoardPiece(type: PieceType.tiger, node: 'r2-c2'),
    BoardPiece(type: PieceType.tiger, node: 'r2-c6'),
    BoardPiece(type: PieceType.goat, node: 'r1-c4'),
    BoardPiece(type: PieceType.goat, node: 'r3-c4'),
    BoardPiece(type: PieceType.goat, node: 'r2-c3'),
    BoardPiece(type: PieceType.goat, node: 'r2-c5'),
  ];

  static List<TutorialStepData> get allSteps => [
        TutorialStepData(
          index: 0,
          title: 'What is Puli Meka?',
          body:
              'A traditional Indian board game — two Tigers hunt 23 Goats on a diamond-shaped grid. '
              'Pieces move along the lines between dots. Tigers always take the first turn.',
          board: opening,
          boardCaption: 'Starting position — 2 tigers, 4 goats on board',
          bullets: const [
            TutorialBullet(
              label: 'Tigers',
              text: '2 orange pieces that move and capture goats.',
            ),
            TutorialBullet(
              label: 'Goats',
              text: '23 green pieces — 4 start on the board, the rest are placed during play.',
            ),
          ],
          accentColor: AppTheme.textPrimary,
        ),
        const TutorialStepData(
          index: 1,
          title: 'How each side plays',
          body: 'Players alternate turns. Tap a piece, then tap a highlighted dot to move.',
          bullets: const [
            TutorialBullet(
              label: 'Tiger moves',
              text:
                  'Slide one step along a line to an empty dot, or jump over a goat when the landing spot beyond it is empty. A jumped goat is captured and removed.',
            ),
            TutorialBullet(
              label: 'Goat placement',
              text:
                  'After each tiger turn, place one new goat on any empty dot until all 23 are on the board.',
            ),
            TutorialBullet(
              label: 'Goat movement',
              text:
                  'Once every goat is placed, goats slide one step to an adjacent empty dot — like tigers, but goats cannot jump or capture.',
            ),
          ],
          accentColor: AppTheme.primary,
        ),
        const TutorialStepData(
          index: 2,
          title: 'How to win',
          body: 'The game ends as soon as either side meets its win condition.',
          bullets: const [
            TutorialBullet(
              label: 'Tigers win',
              text: 'Capture 12 goats (jump over them).',
            ),
            TutorialBullet(
              label: 'Goats win',
              text: 'Surround both tigers so neither can move on its next turn.',
            ),
            TutorialBullet(
              label: 'Tips',
              text:
                  'Goats should work together to block tiger paths. Tigers should look for jump captures early before goats fill the board.',
            ),
          ],
          accentColor: AppTheme.goatAccent,
        ),
      ];

  static UiGameState get opening => const UiGameState(
        pieces: _openingPieces,
        currentTurn: PieceType.tiger,
      );

  /// Tiger selected at game start — valid first moves highlighted.
  static UiGameState get tigerStarts {
    final engine = GameState.initial();
    const tiger = 'r2-c2';
    return _uiFromEngine(
      engine,
      selectedNode: tiger,
      validTargets: engine.getTigerMoves(tiger).map((m) => m.target).toSet(),
    );
  }

  /// Tiger piece selected with slide targets (after opening).
  static UiGameState get tigerMove => tigerStarts;

  /// Tiger jump capture — goat between tiger and landing node.
  static UiGameState get tigerCapture => tigerCaptureDemo;

  static UiGameState get tigerCaptureDemo {
    final engine = GameState.initial();
    engine.pieceState['r2-c3'] = null;
    engine.pieceState['r2-c4'] = null;
    engine.pieceState['r2-c5'] = PieceType.goat;
    engine.pieceState['r2-c6'] = PieceType.tiger;
    const tiger = 'r2-c2';
    final jumps = engine.getTigerMoves(tiger).where((m) => m.isJump).toList();
    if (jumps.isNotEmpty) {
      final jump = jumps.first;
      return _uiFromEngine(
        engine,
        selectedNode: tiger,
        validTargets: {jump.target},
        hintHighlightNodes: {tiger, jump.jumped!, jump.target},
      );
    }
    return tigerStarts;
  }

  /// Goat placement turn — empty nodes highlighted.
  static UiGameState get goatPlacement {
    final engine = GameState.initial();
    final moves = engine.getTigerMoves('r2-c2');
    if (moves.isNotEmpty) {
      engine.applyMove('r2-c2', moves.first.target);
    }
    return _uiFromEngine(
      engine,
      validTargets: engine.placementTargets.toSet(),
      showPlacementDots: true,
    );
  }

  /// Movement phase — goat selected with slide targets.
  static UiGameState get goatMove {
    final engine = GameState.initial();
    engine.gamePhase = 'movement';
    engine.goatsToPlace = 0;
    const goat = 'r2-c3';
    return _uiFromEngine(
      engine,
      selectedNode: goat,
      validTargets: engine.getGoatMoves(goat).map((m) => m.target).toSet(),
    );
  }

  /// Goats win — tigers surrounded.
  static UiGameState get goatsWin {
    final engine = GameState.initial();
    engine.gamePhase = 'movement';
    engine.goatsToPlace = 0;
    engine.winner = 'goats';
    return _uiFromEngine(engine);
  }

  /// Tigers win — 12 goats captured.
  static UiGameState get tigersWin {
    final engine = GameState.initial();
    engine.gamePhase = 'movement';
    engine.goatsToPlace = 0;
    engine.capturedGoats = GameConstants.goatsToCaptureForTigerWin;
    engine.winner = 'tigers';
    for (final node in ['r1-c4', 'r3-c4', 'r2-c3', 'r2-c5']) {
      engine.pieceState[node] = null;
    }
    return _uiFromEngine(engine);
  }

  static UiGameState _uiFromEngine(
    GameState engine, {
    String? selectedNode,
    Set<String>? validTargets,
    bool showPlacementDots = false,
    Set<String> hintHighlightNodes = const {},
  }) {
    final pieces = <BoardPiece>[];
    for (final entry in engine.pieceState.entries) {
      final piece = entry.value;
      if (piece != null) {
        pieces.add(BoardPiece(type: piece, node: entry.key));
      }
    }
    return UiGameState(
      pieces: pieces,
      currentTurn: engine.currentTurn,
      validTargets: validTargets ?? const {},
      selectedNode: selectedNode,
      winner: engine.winner,
      capturedGoats: engine.capturedGoats,
      showPlacementDots: showPlacementDots,
      hintHighlightNodes: hintHighlightNodes,
    );
  }
}

class TutorialStepData {
  const TutorialStepData({
    required this.index,
    required this.title,
    required this.body,
    required this.bullets,
    required this.accentColor,
    this.board,
    this.boardCaption,
  });

  final int index;
  final String title;
  final String body;
  final List<TutorialBullet> bullets;
  final Color accentColor;
  final UiGameState? board;
  final String? boardCaption;
}

class TutorialBullet {
  const TutorialBullet({required this.label, required this.text});

  final String label;
  final String text;
}
