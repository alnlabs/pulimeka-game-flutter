import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../controllers/game_controller.dart';
import '../models/game_constants.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

/// Game status: turn strip + two compact stat tiles (no overflow).
class GameHud extends StatelessWidget {
  const GameHud({
    required this.ui,
    required this.tigerName,
    required this.goatName,
    required this.showTutorialPlacementHints,
    super.key,
  });

  final UiGameState ui;
  final String tigerName;
  final String goatName;
  final bool showTutorialPlacementHints;

  /// Approximate HUD block height (winner banner uses the same slot).
  static const double blockHeight = 168;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TurnStrip(
          ui: ui,
          tigerName: tigerName,
          goatName: goatName,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: Row(
            children: [
              Expanded(child: _CaptureTile(captured: ui.capturedGoats)),
              const SizedBox(width: 8),
              Expanded(
                child: _PlacementTile(
                  ui: ui,
                  showTutorialHints: showTutorialPlacementHints,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TurnStrip extends StatelessWidget {
  const _TurnStrip({
    required this.ui,
    required this.tigerName,
    required this.goatName,
  });

  final UiGameState ui;
  final String tigerName;
  final String goatName;

  @override
  Widget build(BuildContext context) {
    final isTiger = ui.currentTurn == PieceType.tiger;
    final bg = isTiger ? AppTheme.tigerTurnBg : AppTheme.goatTurnBg;
    final playerName = isTiger ? tigerName : goatName;
    final role = isTiger ? 'Tiger' : 'Goat';
    final action = ui.isGoatPlacementTurn
        ? 'Place a goat on the board'
        : isTiger
            ? 'Move or jump to capture'
            : 'Move a goat to an empty node';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.textOnDark.withOpacity(0.35), width: 1),
        boxShadow: AppTheme.cardShadow(opacity: 0.14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _PieceAvatar(type: ui.currentTurn, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$role's turn",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppTheme.textOnDark.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                    size: 19,
                    weight: FontWeight.bold,
                    color: AppTheme.textOnDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.text(
                    size: 11,
                    color: AppTheme.textOnDark.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({required this.captured});

  final int captured;

  @override
  Widget build(BuildContext context) {
    const goal = GameConstants.goatsToCaptureForTigerWin;
    final progress = (captured / goal).clamp(0.0, 1.0);

    return Container(
      height: double.infinity,
      decoration: AppTheme.panelDecoration(color: AppTheme.cardWhite),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Captures',
            maxLines: 1,
            style: AppTheme.text(size: 11, color: AppTheme.textSecondary),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$captured / $goal',
                maxLines: 1,
                style: AppTheme.text(size: 16, weight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppTheme.backgroundLighter,
                  color: AppTheme.tigerAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlacementTile extends StatelessWidget {
  const _PlacementTile({
    required this.ui,
    required this.showTutorialHints,
  });

  final UiGameState ui;
  final bool showTutorialHints;

  @override
  Widget build(BuildContext context) {
    final active = ui.isPlacementPhase;
    final goatTurn = ui.isGoatPlacementTurn;
    final hint = showTutorialHints && active && goatTurn ? 'Tap a green dot' : null;

    final line1 = active
        ? '${ui.goatsPlacedFromHand}/${ui.goatsToPlaceTotal} placed'
        : 'Movement phase';
    final line2 = active
        ? '${ui.goatsRemainingToPlace} left in hand'
        : 'All goats on board';

    return Container(
      height: double.infinity,
      decoration: AppTheme.panelDecoration(
        color: active && goatTurn ? AppTheme.goatSurface : AppTheme.cardWhite,
        borderColor: active && goatTurn
            ? AppTheme.goatAccent.withOpacity(0.35)
            : AppTheme.borderSubtle,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            active ? 'Placement' : 'Board',
            maxLines: 1,
            style: AppTheme.text(size: 11, color: AppTheme.textSecondary),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.text(size: 13, weight: FontWeight.w600),
              ),
              Text(
                hint ?? line2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.text(
                  size: 11,
                  color: hint != null ? AppTheme.goatAccent : AppTheme.textTertiary,
                  weight: hint != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
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
    final asset = type == PieceType.tiger
        ? GameAssets.tigerIcon
        : GameAssets.goatIcon;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.14),
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

    return Container(
      height: GameHud.blockHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow(opacity: 0.16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: AppTheme.textOnDark, size: 26),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(
                size: 18,
                weight: FontWeight.bold,
                color: AppTheme.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
