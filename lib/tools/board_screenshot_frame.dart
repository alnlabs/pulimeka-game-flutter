import 'package:flutter/material.dart';

import 'package:puli_meka_game_flutter/src/controllers/game_controller.dart';
import 'package:puli_meka_game_flutter/src/models/game_state.dart';
import 'package:puli_meka_game_flutter/src/theme/app_theme.dart';
import 'package:puli_meka_game_flutter/src/widgets/puli_meka_board.dart';

/// In-game-style board frame for screenshot / tutorial export.
class BoardScreenshotFrame extends StatelessWidget {
  const BoardScreenshotFrame({
    required this.title,
    required this.subtitle,
    required this.ui,
    super.key,
  });

  final String title;
  final String subtitle;
  final UiGameState ui;

  static const Key captureKey = Key('board_screenshot_capture');

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: captureKey,
      child: ColoredBox(
        color: AppTheme.background,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PhaseHeader(title: title, subtitle: subtitle, ui: ui),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.boardFill,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.boardBorder.withOpacity(0.35)),
                    boxShadow: AppTheme.cardShadow(opacity: 0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: PuliMekaBoard(ui: ui, onNodeTap: (_) {}),
                        ),
                        if (ui.capturedGoats > 0)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _Badge(
                              label: '${ui.capturedGoats} captured',
                              color: AppTheme.primaryDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({
    required this.title,
    required this.subtitle,
    required this.ui,
  });

  final String title;
  final String subtitle;
  final UiGameState ui;

  @override
  Widget build(BuildContext context) {
    final isTiger = ui.currentTurn == PieceType.tiger;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.text(size: 16, weight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: AppTheme.text(size: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isTiger ? AppTheme.tigerTurnBg : AppTheme.goatTurnBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(
            isTiger ? "Tiger's turn" : "Goat's turn",
            style: AppTheme.text(
              size: 11,
              weight: FontWeight.w600,
              color: AppTheme.textOnDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        label,
        style: AppTheme.text(size: 11, weight: FontWeight.w600, color: AppTheme.textOnDark),
      ),
    );
  }
}
