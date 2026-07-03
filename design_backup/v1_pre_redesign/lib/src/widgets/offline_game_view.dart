import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/ai_game_controller.dart';
import '../controllers/game_controller.dart';
import '../models/game_constants.dart';
import '../models/game_state.dart';
import '../services/ad_config.dart';
import '../services/ad_service.dart';
import '../services/hint_service.dart';
import '../services/move_hint_calculator.dart';
import '../services/rewarded_ad_manager.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'ad_banner.dart';
import 'hint_unlock_sheet.dart';
import 'puli_meka_board.dart';
import 'timed_ad_overlay.dart';

class OfflineGameView extends StatefulWidget {
  const OfflineGameView({
    required this.tigerPlayerName,
    required this.goatPlayerName,
    this.modeLabel = 'Player Offline',
    this.controller,
    super.key,
  });

  final String tigerPlayerName;
  final String goatPlayerName;
  final String modeLabel;
  final GameController? controller;

  @override
  State<OfflineGameView> createState() => _OfflineGameViewState();
}

class _OfflineGameViewState extends State<OfflineGameView> {
  late final GameController _controller = widget.controller ?? GameController();
  final SoundService _sounds = SoundService.instance;
  final MoveHintCalculator _hintCalculator = MoveHintCalculator();
  final HintService _hintService = HintService.instance;

  String? _previousSelectedNode;
  int _previousCapturedGoats = 0;
  PieceType? _previousTurn;
  Timer? _invalidMessageTimer;

  bool _showInstructions = false;
  bool _showMenu = false;
  bool _showConfirmLeave = false;
  bool _showConfirmNewGame = false;
  bool _showWinDialog = false;
  bool _gameCompletionRecorded = false;
  bool _showTimedAdOverlay = false;
  bool _tutorialAutoHints = true;
  String _hintStatusLabel = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUiChanged);
    _previousCapturedGoats = _controller.ui.capturedGoats;
    _previousTurn = _controller.ui.currentTurn;
    _loadHintSettings();
    AdService.preloadHintAds();
  }

  Future<void> _loadHintSettings() async {
    final tutorial = await _hintService.shouldShowAutoHints();
    final label = await _hintService.statusLabel();
    if (!mounted) {
      return;
    }
    setState(() {
      _tutorialAutoHints = tutorial;
      _hintStatusLabel = label;
    });
    _controller.setTutorialAutoHints(tutorial);
  }

  @override
  void dispose() {
    _invalidMessageTimer?.cancel();
    _controller.removeListener(_onUiChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onUiChanged() {
    final ui = _controller.ui;

    if (ui.selectedNode != null && ui.selectedNode != _previousSelectedNode) {
      _sounds.playClick();
    }
    _previousSelectedNode = ui.selectedNode;

    if (ui.capturedGoats > _previousCapturedGoats) {
      _sounds.playCapture();
    }
    _previousCapturedGoats = ui.capturedGoats;

    if (ui.currentTurn != _previousTurn &&
        _previousSelectedNode != null &&
        ui.capturedGoats == _previousCapturedGoats) {
      _sounds.playMove();
    }
    _previousTurn = ui.currentTurn;

    if (ui.invalidMoveMessage != null) {
      _invalidMessageTimer?.cancel();
      _invalidMessageTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted) _controller.clearInvalidMoveMessage();
      });
    }

    if (ui.winner != null && !_showWinDialog) {
      _showWinDialog = true;
      _recordGameIfNeeded();
    }

    setState(() {});
  }

  Future<void> _recordGameIfNeeded() async {
    if (_gameCompletionRecorded) {
      return;
    }
    _gameCompletionRecorded = true;
    await _hintService.recordGameCompleted();
    await _loadHintSettings();
  }

  @override
  Widget build(BuildContext context) {
    final ui = _controller.ui;

    return Stack(
      children: [
        PopScope(
          canPop: ui.winner != null,
          onPopInvoked: (didPop) {
            if (didPop) return;
            if (ui.winner == null) setState(() => _showConfirmLeave = true);
          },
          child: Scaffold(
            backgroundColor: AppTheme.background,
            body: SafeArea(
              child: Column(
                children: [
                  _GameTopBar(
                    modeLabel: widget.modeLabel,
                    subtitle: '${widget.tigerPlayerName} vs ${widget.goatPlayerName}',
                    onBack: () {
                      if (ui.winner == null) {
                        setState(() => _showConfirmLeave = true);
                      } else {
                        Navigator.maybePop(context);
                      }
                    },
                    onInfo: () => setState(() => _showInstructions = true),
                    onHint: _onHintPressed,
                    hintTooltip: _hintStatusLabel,
                    onMenu: () => setState(() => _showMenu = true),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Column(
                        children: [
                          if (ui.winner != null)
                            _WinnerBanner(winner: ui.winner!)
                          else
                            _StatusRow(
                              ui: ui,
                              tigerName: widget.tigerPlayerName,
                              goatName: widget.goatPlayerName,
                              showTutorialPlacementHints: _tutorialAutoHints,
                            ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: PuliMekaBoard(
                                    ui: ui,
                                    onNodeTap: _controller.onNodeTapped,
                                  ),
                                ),
                                if (ui.invalidMoveMessage != null)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: _InvalidMoveBanner(
                                      message: ui.invalidMoveMessage!,
                                    ),
                                  ),
                                if (ui.activeHintMessage != null)
                                  Positioned(
                                    top: ui.invalidMoveMessage != null ? 48 : 0,
                                    left: 0,
                                    right: 0,
                                    child: _HintBanner(message: ui.activeHintMessage!),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: AdBanner(),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                ],
              ),
            ),
          ),
        ),
        if (_showInstructions) _dialogOverlay(_instructionsDialog()),
        if (_showWinDialog && ui.winner != null) _dialogOverlay(_winDialog(ui)),
        if (_showMenu) _dialogOverlay(_menuDialog()),
        if (_showConfirmLeave) _dialogOverlay(_confirmLeaveDialog()),
        if (_showConfirmNewGame) _dialogOverlay(_confirmNewGameDialog()),
        if (_showTimedAdOverlay)
          Positioned.fill(
            child: TimedAdOverlay(
              onComplete: () {
                if (!mounted) {
                  return;
                }
                setState(() => _showTimedAdOverlay = false);
                _deliverHintAfterAd();
              },
            ),
          ),
      ],
    );
  }

  Future<void> _onHintPressed() async {
    final ui = _controller.ui;
    if (ui.winner != null) {
      return;
    }

    final aiController = widget.controller;
    if (aiController is AiGameController &&
        ui.currentTurn != aiController.humanRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hints are available on your turn only.')),
      );
      return;
    }

    final access = await _hintService.checkAccess();
    if (!mounted) {
      return;
    }

    if (access == HintAccess.needsAd) {
      final method = await showHintUnlockSheet(context);
      if (!mounted || method == null) {
        return;
      }
      if (method == HintUnlockMethod.timedAd) {
        setState(() => _showTimedAdOverlay = true);
        return;
      }
      await _showRewardedForHint();
      return;
    }

    await _deliverHint(consumeFree: access == HintAccess.free);
  }

  Future<void> _showRewardedForHint() async {
    if (!AdConfig.shouldRequestLiveAds) {
      await _deliverHintAfterAd();
      return;
    }

    if (!RewardedAdManager.instance.isReady) {
      RewardedAdManager.instance.preload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video ad loading — try again in a moment.')),
        );
      }
      return;
    }

    var earned = false;
    final shown = await RewardedAdManager.instance.show(
      onReward: () => earned = true,
    );
    if (!mounted) {
      return;
    }
    if (shown && earned) {
      await _deliverHintAfterAd();
    } else if (!shown) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not show video. Try the short ad option.')),
      );
    }
  }

  Future<void> _deliverHintAfterAd() async {
    await _deliverHint(consumeFree: false);
  }

  Future<void> _deliverHint({required bool consumeFree}) async {
    final hint = _hintCalculator.suggest(_controller.gameState);
    if (!mounted) {
      return;
    }
    if (hint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hint available for this turn.')),
      );
      return;
    }
    if (consumeFree) {
      await _hintService.consumeFreeHintIfNeeded();
      await _loadHintSettings();
    }
    _controller.showMoveHint(hint);
  }

  Widget _dialogOverlay(Widget dialog) {
    return Positioned.fill(
      child: Material(
        color: Colors.black54,
        child: Center(child: dialog),
      ),
    );
  }

  Widget _instructionsDialog() {
    return AlertDialog(
      title: Text(
        'How to Play Puli Meka',
        style: AppTheme.text(size: 24, weight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Text(
          'Objective:\n'
          '• Tigers: Capture 12 goats to win\n'
          '• Goats: Trap all tigers so they cannot move\n\n'
          'Gameplay:\n'
          '1. Goats start by placing pieces on empty nodes\n'
          '2. Tigers move first, then goats alternate turns\n'
          '3. Tigers can move to adjacent nodes or jump over goats\n'
          '4. Goats can move to adjacent empty nodes\n'
          '5. Select a piece and tap a valid node to move',
          style: AppTheme.text(size: 16),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showInstructions = false),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _winDialog(UiGameState ui) {
    final winner = ui.winner!;
    final title = winner == 'goats'
        ? '${widget.goatPlayerName} Wins!'
        : '${widget.tigerPlayerName} Wins!';
    final body = winner == 'goats'
        ? '${widget.goatPlayerName} (Goats) trapped all tigers!'
        : '${widget.tigerPlayerName} (Tigers) captured 12 goats!';

    return AlertDialog(
      title: Text('🎉 Game Over!', style: AppTheme.text(size: 24, weight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTheme.text(size: 20, weight: FontWeight.bold, color: const Color(0xFFBF360C)),
          ),
          const SizedBox(height: 8),
          Text(body, style: AppTheme.text(size: 16)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _showWinDialog = false;
              _gameCompletionRecorded = false;
              _controller.resetGame();
              _previousCapturedGoats = 0;
              _previousSelectedNode = null;
            });
          },
          child: const Text('Play Again'),
        ),
        TextButton(
          onPressed: () => setState(() => _showWinDialog = false),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            setState(() => _showWinDialog = false);
            Navigator.pop(context);
          },
          child: const Text('Go Back'),
        ),
      ],
    );
  }

  Widget _menuDialog() {
    return AlertDialog(
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(),
      title: Text(
        'Game Menu',
        style: AppTheme.text(size: 24, weight: FontWeight.bold, color: AppTheme.primaryLight),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('New Game'),
            onTap: () => setState(() {
              _showMenu = false;
              _showConfirmNewGame = true;
            }),
          ),
          ListTile(
            title: const Text('How to Play'),
            onTap: () => setState(() {
              _showMenu = false;
              _showInstructions = true;
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showMenu = false),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _confirmLeaveDialog() {
    return AlertDialog(
      title: const Text('Leave Game?'),
      content: const Text('Are you sure you want to leave? Progress will be lost.'),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showConfirmLeave = false),
          child: const Text('Stay'),
        ),
        TextButton(
          onPressed: () {
            setState(() => _showConfirmLeave = false);
            Navigator.pop(context);
          },
          child: const Text('Leave'),
        ),
      ],
    );
  }

  Widget _confirmNewGameDialog() {
    return AlertDialog(
      title: const Text('Start New Game?'),
      content: const Text('Current progress will be lost.'),
      actions: [
        TextButton(
          onPressed: () => setState(() => _showConfirmNewGame = false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _showConfirmNewGame = false;
              _showWinDialog = false;
              _controller.resetGame();
            });
          },
          child: const Text('New Game'),
        ),
      ],
    );
  }
}

class _GameTopBar extends StatelessWidget {
  const _GameTopBar({
    required this.modeLabel,
    required this.subtitle,
    required this.onBack,
    required this.onInfo,
    required this.onHint,
    required this.hintTooltip,
    required this.onMenu,
  });

  final String modeLabel;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onInfo;
  final VoidCallback onHint;
  final String hintTooltip;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textOnDark),
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modeLabel,
                    style: AppTheme.text(
                      size: 20,
                      weight: FontWeight.w600,
                      color: AppTheme.textOnDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.text(
                      size: 14,
                      color: AppTheme.textOnDark.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: AppTheme.textOnDark),
              onPressed: onInfo,
            ),
            Tooltip(
              message: hintTooltip.isEmpty ? 'Hint' : hintTooltip,
              child: IconButton(
                icon: const Icon(Icons.lightbulb_outline, color: AppTheme.textOnDark),
                onPressed: onHint,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textOnDark),
              onPressed: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.winner});
  final String winner;

  @override
  Widget build(BuildContext context) {
    final text = winner == 'goats'
        ? '🏆 Goats Win! Tigers are trapped.'
        : '🏆 Tigers Win! Enough goats captured.';
    return Container(
      width: double.infinity,
      height: _StatusRow._rowHeight,
      alignment: Alignment.center,
      color: const Color(0xFFFFE082),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.text(size: 18, weight: FontWeight.w600, color: const Color(0xFFBF360C)),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  const _HintBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(4),
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Color(0xFFFF8F00), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTheme.text(size: 13, color: const Color(0xFFE65100)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvalidMoveBanner extends StatelessWidget {
  const _InvalidMoveBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(4),
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.text(size: 14, color: const Color(0xFFE65100)),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.ui,
    required this.tigerName,
    required this.goatName,
    required this.showTutorialPlacementHints,
  });

  final UiGameState ui;
  final String tigerName;
  final String goatName;
  final bool showTutorialPlacementHints;

  /// Fixed height so turn / placement / capture cards never push the board.
  static const double _rowHeight = 108;

  @override
  Widget build(BuildContext context) {
    final currentName = ui.currentTurn == PieceType.tiger ? tigerName : goatName;
    final turnBorder = ui.currentTurn == PieceType.tiger
        ? const Color(0xFF8B4513)
        : const Color(0xE6C8FFC8);

    return SizedBox(
      height: _rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: turnBorder, width: 3),
                color: AppTheme.cardYellow,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Current Turn',
                        style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _TurnIcon(type: ui.currentTurn),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.text(size: 18, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PlacementPanel(
              ui: ui,
              showTutorialHints: showTutorialPlacementHints,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              color: AppTheme.cardYellow,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Goats Captured',
                    style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ui.capturedGoats} / ${GameConstants.goatsToCaptureForTigerWin}',
                    style: AppTheme.text(size: 18, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Middle column: always same size; content fades when placement phase ends.
class _PlacementPanel extends StatelessWidget {
  const _PlacementPanel({
    required this.ui,
    required this.showTutorialHints,
  });

  final UiGameState ui;
  final bool showTutorialHints;

  static const double _hintHeight = 28;

  @override
  Widget build(BuildContext context) {
    final hint = showTutorialHints && ui.isPlacementPhase
        ? (ui.isGoatPlacementTurn
            ? 'Tap a green dot to place'
            : 'Tigers move now')
        : '';

    return Container(
      color: ui.isPlacementPhase && ui.isGoatPlacementTurn
          ? const Color(0xFFE8F5E9)
          : AppTheme.cardWhite,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Goat Placement',
            style: AppTheme.text(size: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: ui.isPlacementPhase ? 1 : 0,
            child: Text(
              '${ui.goatsPlacedFromHand}/${ui.goatsToPlaceTotal}',
              style: AppTheme.text(size: 12, weight: FontWeight.w600),
            ),
          ),
          Opacity(
            opacity: ui.isPlacementPhase ? 1 : 0,
            child: Text(
              'Left ${ui.goatsRemainingToPlace}',
              style: AppTheme.text(size: 11, color: AppTheme.textSecondary),
            ),
          ),
          SizedBox(
            height: _hintHeight,
            child: Center(
              child: Text(
                hint,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.text(
                  size: 10,
                  weight: ui.isGoatPlacementTurn ? FontWeight.w600 : FontWeight.normal,
                  color: ui.isGoatPlacementTurn
                      ? const Color(0xFF2E7D32)
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnIcon extends StatelessWidget {
  const _TurnIcon({required this.type});
  final PieceType type;

  @override
  Widget build(BuildContext context) {
    final asset = type == PieceType.tiger
        ? 'assets/images/tiger_icon.png'
        : 'assets/images/goat_icon.png';
    final bg = type == PieceType.tiger ? const Color(0xE6FFC896) : const Color(0xE6C8FFC8);
    final border = type == PieceType.tiger ? const Color(0xFF8B4513) : const Color(0xFF556B2F);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      padding: const EdgeInsets.all(2),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
