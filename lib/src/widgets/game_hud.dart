import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../controllers/game_controller.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

/// Compact one-line status so the board can fill the screen.
class GameHud extends StatelessWidget {
  const GameHud({
    required this.ui,
    required this.tigerName,
    required this.goatName,
    this.showTutorialPlacementHints = false,
    super.key,
  });

  final UiGameState ui;
  final String tigerName;
  final String goatName;
  final bool showTutorialPlacementHints;

  static const double blockHeight = 48;

  @override
  Widget build(BuildContext context) {
    final isTiger = ui.currentTurn == PieceType.tiger;
    final accent = isTiger ? AppTheme.tigerTurnBg : AppTheme.goatTurnBg;
    final playerName = isTiger ? tigerName : goatName;
    final action = ui.isGoatPlacementTurn
        ? 'Place a goat'
        : isTiger
            ? 'Tiger to move'
            : 'Goat to move';
    final captureLabel = ui.winByTrapOnly
        ? (ui.capturedGoats == 0 ? 'Trap' : 'Lost ${ui.capturedGoats}')
        : '${ui.capturedGoats}/${ui.goatsToCaptureGoal}';
    final placeLabel = ui.isPlacementPhase
        ? '${ui.goatsRemainingToPlace} in hand'
        : 'Moving';

    return SizedBox(
      height: blockHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppTheme.radiusSmall - 1),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PieceAvatar(type: ui.currentTurn, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.text(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.text(
                      size: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(child: _HudStat(label: captureLabel)),
            const SizedBox(width: 6),
            Flexible(
              child: _HudStat(
                label: placeLabel,
                highlight: ui.isGoatPlacementTurn,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat({required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.goatSurface : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.text(
          size: 11,
          weight: FontWeight.w700,
          color: highlight ? AppTheme.goatAccent : AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _PieceAvatar extends StatelessWidget {
  const _PieceAvatar({required this.type, required this.size});

  final PieceType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset =
        type == PieceType.tiger ? GameAssets.tigerIcon : GameAssets.goatIcon;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

class GameWinnerBanner extends StatelessWidget {
  const GameWinnerBanner({
    required this.winner,
    required this.tigerName,
    required this.goatName,
    super.key,
  });

  final String winner;
  final String tigerName;
  final String goatName;

  @override
  Widget build(BuildContext context) {
    final isGoats = winner == 'goats';
    final bg = isGoats ? AppTheme.goatTurnBg : AppTheme.tigerTurnBg;
    final text = isGoats ? '$goatName wins!' : '$tigerName wins!';

    return SizedBox(
      height: GameHud.blockHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, color: AppTheme.textOnDark, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.text(
                  size: 16,
                  weight: FontWeight.bold,
                  color: AppTheme.textOnDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
