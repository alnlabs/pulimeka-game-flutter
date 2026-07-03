import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
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
