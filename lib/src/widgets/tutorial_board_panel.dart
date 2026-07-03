import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../theme/app_theme.dart';
import 'puli_meka_board.dart';

/// Single live board diagram for the tutorial intro (no screenshot assets).
class TutorialBoardPanel extends StatelessWidget {
  const TutorialBoardPanel({
    required this.board,
    this.caption,
    super.key,
  });

  final UiGameState board;
  final String? caption;

  static const double _boardHeight = 260;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              caption!,
              textAlign: TextAlign.center,
              style: AppTheme.text(
                size: 12,
                weight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        SizedBox(
          height: _boardHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.boardFill,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.boardBorder.withOpacity(0.25)),
              boxShadow: AppTheme.cardShadow(opacity: 0.06),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: IgnorePointer(
                child: PuliMekaBoard(ui: board, onNodeTap: (_) {}),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
