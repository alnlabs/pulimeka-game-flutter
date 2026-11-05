import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/ai_game_controller.dart';
import '../controllers/game_controller.dart';
import '../models/campaign_level.dart';
import '../models/game_state.dart';
import '../services/ad_config.dart';
import '../services/ad_service.dart';
import '../services/campaign_progress_service.dart';
import '../services/game_history_recorder.dart';
import '../services/hint_service.dart';
import '../services/move_hint_calculator.dart';
import '../services/offline_player_prefs.dart';
import '../services/online_session_prefs.dart';
import '../services/rewarded_ad_manager.dart';
import '../services/sound_prefs.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/layout_insets.dart';
import 'ad_banner.dart';
import 'app_dialog.dart';
import 'game_hud.dart';
import 'game_message_bar.dart';
import 'hint_unlock_sheet.dart';
import 'player_names_dialog.dart';
import '../screens/profile_screen.dart';
import '../screens/tutorial_screen.dart';
import 'game_top_bar.dart';
import 'puli_meka_board.dart';
import 'timed_ad_overlay.dart';

class OfflineGameView extends StatefulWidget {
  const OfflineGameView({
    required this.tigerPlayerName,
    required this.goatPlayerName,
    this.modeLabel = 'Player Offline',
    this.controller,
    this.aiHumanRole,
    this.aiHumanName,
    this.campaignLevel,
    this.onCampaignNext,
    super.key,
  });

  final String tigerPlayerName;
  final String goatPlayerName;
  final String modeLabel;
  final GameController? controller;
  /// When set, opponent is AI and only the human name can be edited.
  final PieceType? aiHumanRole;
  final String? aiHumanName;
  final CampaignLevel? campaignLevel;
  /// Called after a campaign win when user taps Next (parent should open next level).
  final VoidCallback? onCampaignNext;

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

  bool _gameCompletionRecorded = false;
  bool _showHintAdOverlay = false;
  bool _showCompletionAdOverlay = false;
  bool _completionAdHandled = false;
  bool _winDialogPresented = false;
  late final ValueNotifier<bool> _tutorialAutoHintsNotifier;
  String _hintStatusLabel = '';
  late final ValueNotifier<String> _subtitleNotifier;
  late final ValueNotifier<String> _hintLabelNotifier;
  late String _tigerName;
  late String _goatName;
  late String _aiHumanName;

  bool get _isAiGame => widget.aiHumanRole != null;

  String get _displayTigerName => _isAiGame
      ? (widget.aiHumanRole == PieceType.tiger
          ? '$_aiHumanName (Tigers)'
          : 'AI (Tigers)')
      : _tigerName;

  String get _displayGoatName => _isAiGame
      ? (widget.aiHumanRole == PieceType.goat
          ? '$_aiHumanName (Goats)'
          : 'AI (Goats)')
      : _goatName;

  void _syncSubtitle() {
    _subtitleNotifier.value = '$_displayTigerName vs $_displayGoatName';
  }

  void _syncHintLabel() {
    _hintLabelNotifier.value =
        _hintStatusLabel.isEmpty ? 'Tap for hint' : _hintStatusLabel;
  }

  @override
  void initState() {
    super.initState();
    _tigerName = widget.tigerPlayerName;
    _goatName = widget.goatPlayerName;
    _aiHumanName = widget.aiHumanName ?? 'You';
    _subtitleNotifier = ValueNotifier('');
    _hintLabelNotifier = ValueNotifier('Tap for hint');
    _tutorialAutoHintsNotifier = ValueNotifier(true);
    _syncSubtitle();
    _controller.addListener(_onUiChanged);
    _previousCapturedGoats = _controller.ui.capturedGoats;
    _previousTurn = _controller.ui.currentTurn;
    _loadHintSettings();
    AdService.preloadHintAds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showGoalToWinDialog();
    });
  }

  Future<void> _loadHintSettings() async {
    final level = widget.campaignLevel;
    final tutorial = level != null && level.usesTeachingHints
        ? true
        : await _hintService.shouldShowAutoHints();
    final label = await _hintService.statusLabel();
    if (!mounted) {
      return;
    }
    _tutorialAutoHintsNotifier.value = tutorial;
    _hintStatusLabel = label;
    _syncHintLabel();
    _controller.setTutorialAutoHints(tutorial);
  }

  @override
  void dispose() {
    _invalidMessageTimer?.cancel();
    _subtitleNotifier.dispose();
    _hintLabelNotifier.dispose();
    _tutorialAutoHintsNotifier.dispose();
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

    if (ui.winner != null) {
      _recordGameIfNeeded();
      if (!_completionAdHandled) {
        _completionAdHandled = true;
        if (AdConfig.shouldShowAds && AdConfig.canLoadInterstitial) {
          setState(() => _showCompletionAdOverlay = true);
        } else {
          _presentWinDialogIfNeeded();
        }
      }
      return;
    }
  }

  void _onCompletionAdFinished() {
    if (!mounted) return;
    setState(() => _showCompletionAdOverlay = false);
    _presentWinDialogIfNeeded();
  }

  Future<void> _recordGameIfNeeded() async {
    if (_gameCompletionRecorded) {
      return;
    }
    _gameCompletionRecorded = true;
    await _hintService.recordGameCompleted();
    await _loadHintSettings();

    final winner = _controller.ui.winner;
    if (winner == null) return;

    final captured = _controller.ui.capturedGoats;
    final placed = _controller.ui.goatsPlacedFromHand;

    if (_isAiGame) {
      final mode = widget.campaignLevel != null ? 'campaign' : 'ai';
      final aiController = widget.controller;
      final humanRole = aiController is AiGameController
          ? aiController.humanRole
          : widget.aiHumanRole;
      if (humanRole == null) return;

      final humanIsTiger = humanRole == PieceType.tiger;
      final humanWon = (winner == 'tigers' && humanIsTiger) ||
          (winner == 'goats' && !humanIsTiger);
      await GameHistoryRecorder.instance.recordMatch(
        playerName: _aiHumanName,
        opponentName: 'AI',
        mode: mode,
        humanWon: humanWon,
        capturedGoats: captured,
        goatsPlaced: placed,
      );
      return;
    }

    await GameHistoryRecorder.instance.recordMatch(
      playerName: _tigerName,
      opponentName: _goatName,
      mode: 'offline',
      humanWon: winner == 'tigers',
      capturedGoats: captured,
      goatsPlaced: placed,
    );
    await GameHistoryRecorder.instance.recordMatch(
      playerName: _goatName,
      opponentName: _tigerName,
      mode: 'offline',
      humanWon: winner == 'goats',
      capturedGoats: captured,
      goatsPlaced: placed,
    );
  }

  void _requestRestart() {
    if (_controller.ui.winner != null) {
      _restartMatch();
      return;
    }
    _showConfirmRestartDialog();
  }

  void _restartMatch() {
    _invalidMessageTimer?.cancel();
    Navigator.of(context, rootNavigator: true).popUntil((route) {
      return route is! DialogRoute && route is! PopupRoute;
    });
    setState(() {
      _completionAdHandled = false;
      _showCompletionAdOverlay = false;
      _gameCompletionRecorded = false;
      _winDialogPresented = false;
      _controller.clearActiveHint();
      _controller.resetGame();
      _previousCapturedGoats = 0;
      _previousSelectedNode = null;
      _previousTurn = _controller.ui.currentTurn;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showGoalToWinDialog();
    });
  }

  String _goalToWinBody() {
    final level = widget.campaignLevel;
    final ui = _controller.ui;
    if (level != null) {
      final youAre = level.humanIsGoat ? 'Goats' : 'Tigers';
      final howYouWin = level.humanIsGoat
          ? (level.rules.winByTrapOnly
              ? 'You win by trapping the tiger(s) so they cannot move.'
              : 'You win by trapping the tiger(s) before they capture ${level.rules.goatsToCapture} goats.')
          : 'You win by capturing ${level.rules.goatsToCapture} goats.';
      final goatsLeftToLose = level.rules.totalGoats - level.rules.goatsToCapture;
      final howTheyWin = level.humanIsGoat
          ? (level.rules.winByTrapOnly
              ? 'The tiger wins if it eats your whole herd.'
              : goatsLeftToLose > 0
                  ? 'The tiger wins when only $goatsLeftToLose goats are left '
                      '(${level.rules.goatsToCapture} captures).'
                  : 'The tiger wins by capturing ${level.rules.goatsToCapture} goats.')
          : 'The goats win by trapping all of your tigers.';
      final jumpRule = level.rules.allowTigerJumps
          ? 'Tigers can jump over a goat onto an empty square to capture.'
          : 'On this level the tiger can only step to an empty neighbor — it cannot jump.';
      return '${level.goalText}\n\n'
          'You play as $youAre.\n'
          '$howYouWin\n'
          '$howTheyWin\n'
          '$jumpRule';
    }

    return 'Tigers win by capturing ${ui.goatsToCaptureGoal} goats '
        '(or eating the whole herd).\n\n'
        'Goats win by trapping all tigers so they cannot move.\n\n'
        'Place goats on empty nodes, then move. Tigers can jump over goats to capture.';
  }

  Future<void> _showGoalToWinDialog() async {
    if (!mounted || _controller.ui.winner != null) return;
    final level = widget.campaignLevel;
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AppDialog(
        title: level != null ? 'Level ${level.id} goal' : 'Goal to win',
        icon: Icons.flag_outlined,
        onClose: () => Navigator.pop(ctx),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (level != null) ...[
              Text(
                level.title,
                style: AppTheme.text(
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
            ],
            AppDialogBodyText(_goalToWinBody()),
          ],
        ),
        actions: [
          AppDialogButton(
            label: 'Let’s play',
            primary: true,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _editPlayerNames() async {
    if (_isAiGame) {
      final result = await showSinglePlayerNameDialog(
        context,
        initialName: _aiHumanName,
        title: 'Change your name',
      );
      if (result == null || !mounted) return;

      setState(() => _aiHumanName = result);
      _syncSubtitle();
      await OnlineSessionPrefs.setPlayerName(result);
      return;
    }

    final result = await showOfflinePlayerNamesDialog(
      context,
      initialTiger: _tigerName,
      initialGoat: _goatName,
      title: 'Change player names',
    );
    if (result == null || !mounted) return;

    setState(() {
      _tigerName = result.tiger;
      _goatName = result.goat;
    });
    _syncSubtitle();
    await OfflinePlayerPrefs.setNames(tiger: result.tiger, goat: result.goat);
  }

  Future<void> _openGameMenu() async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => _GameMenuDialog(
        isAiGame: _isAiGame,
        onRestart: _requestRestart,
        onEditNames: _editPlayerNames,
        onGoal: _showGoalToWinDialog,
        onRules: _showInstructionsDialog,
        onProfile: () => Navigator.pushNamed(
          context,
          ProfileScreen.routeName,
        ).then((_) => _loadHintSettings()),
        onTutorial: () =>
            Navigator.pushNamed(context, TutorialScreen.routeName),
      ),
    );
  }

  Future<void> _showInstructionsDialog() async {
    final level = widget.campaignLevel;
    final captureGoal = level?.rules.goatsToCapture ??
        _controller.ui.goatsToCaptureGoal;
    final trapOnly = level?.rules.winByTrapOnly ?? false;
    final tigerFirst = level == null ||
        level.rules.firstTurn == PieceType.tiger;
    final jumps = level?.rules.allowTigerJumps ?? true;
    final jumpLine = jumps
        ? 'Tigers jump in a straight line over a goat onto an empty point.'
        : 'This level: tigers only step to empty neighbors. They cannot jump or capture.';
    final body = trapOnly
        ? 'Goats win by trapping all tigers so they cannot move.\n\n'
            'Tigers can still win by eating the whole herd.\n\n'
            '1. Place goats on empty nodes next to the tiger.\n'
            '2. ${tigerFirst ? 'Tigers move first' : 'Goats move first'}, then turns alternate.\n'
            '3. $jumpLine\n'
            '4. Select your piece, then tap a highlighted node.'
        : 'Tigers win by capturing $captureGoal goats '
            '(or eating the whole herd).\n\n'
            'Goats win by trapping all tigers.\n\n'
            '1. Place goats on empty nodes.\n'
            '2. ${tigerFirst ? 'Tigers move first' : 'Goats move first'}, then turns alternate.\n'
            '3. $jumpLine\n'
            '4. Select your piece, then tap a highlighted node.';
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AppDialog(
        title: 'How to Play',
        icon: Icons.menu_book_outlined,
        content: SingleChildScrollView(
          child: AppDialogBodyText(body),
        ),
        actions: [
          AppDialogButton(
            label: 'Got it',
            primary: true,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmLeaveDialog() async {
    final leave = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AppDialog(
        title: 'Leave game?',
        icon: Icons.logout,
        content: const AppDialogBodyText(
          'Your current match will be lost if you leave now.',
        ),
        actions: [
          AppDialogButton(
            label: 'Stay',
            primary: true,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDialogButton(
            label: 'Leave',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _showConfirmRestartDialog() async {
    final restart = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AppDialog(
        title: 'Restart game?',
        icon: Icons.restart_alt,
        content: const AppDialogBodyText(
          'The board will reset to the starting position. Current progress will be lost.',
        ),
        actions: [
          AppDialogButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDialogButton(
            label: 'Restart',
            primary: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (restart == true && mounted) {
      _restartMatch();
    }
  }

  void _presentWinDialogIfNeeded() {
    final ui = _controller.ui;
    if (_winDialogPresented || ui.winner == null || !mounted) return;
    _winDialogPresented = true;

    final level = widget.campaignLevel;
    if (level != null) {
      _presentCampaignResultDialog(level, ui.winner!);
      return;
    }

    final winner = ui.winner!;
    final title = winner == 'goats'
        ? '$_displayGoatName Wins!'
        : '$_displayTigerName Wins!';
    final herdWiped = ui.pieces.where((p) => p.type == PieceType.goat).isEmpty &&
        ui.goatsRemainingToPlace == 0;
    final body = winner == 'goats'
        ? '$_displayGoatName (Goats) trapped all tigers!'
        : herdWiped
            ? '$_displayTigerName (Tigers) ate the whole herd!'
            : '$_displayTigerName (Tigers) captured ${ui.goatsToCaptureGoal} goats!';

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: 'Game Over',
        icon: Icons.emoji_events_outlined,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.text(
                size: 18,
                weight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            AppDialogBodyText(body),
          ],
        ),
        actions: [
          AppDialogButton(
            label: 'Restart',
            primary: true,
            onPressed: () {
              Navigator.pop(ctx);
              _gameCompletionRecorded = false;
              _restartMatch();
            },
          ),
          AppDialogButton(
            label: 'Close',
            onPressed: () => Navigator.pop(ctx),
          ),
          AppDialogButton(
            label: 'Home',
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _presentCampaignResultDialog(
    CampaignLevel level,
    String winner,
  ) async {
    final humanWon = (winner == 'goats' && level.humanIsGoat) ||
        (winner == 'tigers' && !level.humanIsGoat);

    var stars = 0;
    if (humanWon) {
      stars = await CampaignProgressService.instance.recordWin(
        levelId: level.id,
        capturedGoats: _controller.ui.capturedGoats,
        goatsToCapture: level.rules.goatsToCapture,
        humanIsGoat: level.humanIsGoat,
        goatsOnBoard: _controller.ui.goatsOnBoard,
      );
    }
    if (!mounted) return;

    final hasNext = humanWon && level.id < CampaignLevels.count;

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: humanWon ? 'Level ${level.id} cleared!' : 'Try again',
        icon: humanWon ? Icons.emoji_events_outlined : Icons.refresh,
        onClose: () => Navigator.pop(ctx),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              level.title,
              style: AppTheme.text(
                size: 18,
                weight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            AppDialogBodyText(
              humanWon
                  ? 'You completed "${level.title}".'
                  : winner == 'tigers'
                      ? 'The tiger ate enough goats. ${level.goalText}'
                      : 'Keep practicing — ${level.goalText}.',
            ),
            if (humanWon) ...[
              const SizedBox(height: 12),
              Row(
                children: List.generate(3, (i) {
                  return Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: AppTheme.primary,
                    size: 28,
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                CampaignProgressService.starCriteriaHint(
                  humanIsGoat: level.humanIsGoat,
                ),
                style: AppTheme.text(
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (hasNext)
            AppDialogButton(
              label: 'Next level',
              primary: true,
              onPressed: () {
                Navigator.pop(ctx);
                widget.onCampaignNext?.call();
              },
            ),
          AppDialogButton(
            label: 'Retry',
            primary: !hasNext,
            onPressed: () {
              Navigator.pop(ctx);
              _gameCompletionRecorded = false;
              _restartMatch();
            },
          ),
          AppDialogButton(
            label: 'Career',
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PopScope(
          canPop: _controller.ui.winner != null,
          onPopInvoked: (didPop) {
            if (didPop) return;
            if (_controller.ui.winner == null) {
              _showConfirmLeaveDialog();
            }
          },
          child: Scaffold(
            backgroundColor: AppTheme.background,
            body: Column(
              children: [
                GameTopBar(
                  key: const ValueKey('offline_game_top_bar'),
                  modeLabel: widget.modeLabel,
                  subtitle: _subtitleNotifier.value,
                  subtitleListenable: _subtitleNotifier,
                  hintLabel: _hintLabelNotifier.value,
                  hintLabelListenable: _hintLabelNotifier,
                  showHintBar: false,
                  editNamesLabel:
                      _isAiGame ? 'Change your name' : 'Change names',
                  onBack: () {
                    if (_controller.ui.winner == null) {
                      _showConfirmLeaveDialog();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                  onHint: _onHintPressed,
                  onRules: _showInstructionsDialog,
                  onRestart: _restartMatch,
                  onMenu: _openGameMenu,
                  onEditNames: _editPlayerNames,
                  onProfile: () => Navigator.pushNamed(
                    context,
                    ProfileScreen.routeName,
                  ).then((_) => _loadHintSettings()),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      final ui = _controller.ui;
                      return ValueListenableBuilder<bool>(
                        valueListenable: _tutorialAutoHintsNotifier,
                        builder: (context, tutorialAutoHints, _) {
                          return SafeArea(
                            top: false,
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                              child: Column(
                              children: [
                                if (ui.winner != null)
                                  GameWinnerBanner(
                                    winner: ui.winner!,
                                    tigerName: _displayTigerName,
                                    goatName: _displayGoatName,
                                  )
                                else
                                  GameHud(
                                    ui: ui,
                                    tigerName: _displayTigerName,
                                    goatName: _displayGoatName,
                                    showTutorialPlacementHints:
                                        tutorialAutoHints,
                                  ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      DecoratedBox(
                                        decoration: AppTheme.panelDecoration(
                                          color: AppTheme.boardFill,
                                          borderColor: AppTheme.borderSubtle,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMedium,
                                          ),
                                          child: PuliMekaBoard(
                                            ui: ui,
                                            onNodeTap: _controller.onNodeTapped,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        right: 8,
                                        child: GameMessageBar(
                                          invalidMessage: ui.invalidMoveMessage,
                                          hintMessage: ui.activeHintMessage,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    4,
                    0,
                    bottomChromePadding(context),
                  ),
                  child: const AdBanner(),
                ),
              ],
            ),
          ),
        ),
        if (_showHintAdOverlay)
          Positioned.fill(
            child: TimedAdOverlay(
              onComplete: () {
                if (!mounted) return;
                setState(() => _showHintAdOverlay = false);
                _deliverHintAfterAd();
              },
            ),
          ),
        if (_showCompletionAdOverlay)
          Positioned.fill(
            child: TimedAdOverlay(
              skipSeconds: AdConfig.completionAdSkipSeconds,
              title: 'Thanks for playing!',
              subtitle: 'A short message from our sponsor',
              onComplete: _onCompletionAdFinished,
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
      showAppSnackBar(context, 'Hints are available on your turn only.');
      return;
    }

    final access = await _hintService.checkAccess();
    if (!mounted) {
      return;
    }

    if (access == HintAccess.needsAd) {
      if (!AdConfig.canUseRewardedAd && !AdConfig.canLoadInterstitial) {
        await _deliverHintAfterAd();
        return;
      }
      final method = await showHintUnlockSheet(
        context,
        showRewardedOption: AdConfig.canUseRewardedAd,
      );
      if (!mounted || method == null) {
        return;
      }
      if (method == HintUnlockMethod.timedAd) {
        setState(() => _showHintAdOverlay = true);
        return;
      }
      await _showRewardedForHint();
      return;
    }

    await _deliverHint(
      shouldConsume: access != HintAccess.tutorial,
    );
  }

  Future<void> _showRewardedForHint() async {
    if (!AdConfig.shouldLoadAds) {
      await _deliverHintAfterAd();
      return;
    }

    if (!RewardedAdManager.instance.isReady) {
      RewardedAdManager.instance.preload();
      if (mounted) {
        setState(() => _showHintAdOverlay = true);
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
      showAppSnackBar(context, 'Could not show video. Try the short ad option.');
    }
  }

  Future<void> _deliverHintAfterAd() async {
    await _hintService.grantAdHintBatch();
    await _deliverHint();
  }

  Future<void> _deliverHint({bool shouldConsume = true}) async {
    final hint = _hintCalculator.suggest(_controller.gameState);
    if (!mounted) {
      return;
    }
    if (hint == null) {
      showAppSnackBar(context, 'No hint available for this turn.');
      return;
    }
    if (shouldConsume) {
      await _hintService.consumeHintOnUse();
      await _loadHintSettings();
    }
    _controller.showMoveHint(hint);
  }
}

class _GameMenuDialog extends StatefulWidget {
  const _GameMenuDialog({
    required this.isAiGame,
    required this.onRestart,
    required this.onEditNames,
    required this.onGoal,
    required this.onRules,
    required this.onProfile,
    required this.onTutorial,
  });

  final bool isAiGame;
  final VoidCallback onRestart;
  final Future<void> Function() onEditNames;
  final Future<void> Function() onGoal;
  final Future<void> Function() onRules;
  final VoidCallback onProfile;
  final VoidCallback onTutorial;

  @override
  State<_GameMenuDialog> createState() => _GameMenuDialogState();
}

class _GameMenuDialogState extends State<_GameMenuDialog> {
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SoundService.instance.enabled;
  }

  Future<void> _setSoundEnabled(bool value) async {
    await SoundPrefs.setEnabled(value);
    SoundService.instance.enabled = value;
    setState(() => _soundEnabled = value);
  }

  void _closeAnd(VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  Future<void> _closeAndAsync(Future<void> Function() action) async {
    Navigator.pop(context);
    await action();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Game Menu',
      icon: Icons.menu,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GameMenuSoundTile(
            enabled: _soundEnabled,
            onChanged: _setSoundEnabled,
          ),
          const SizedBox(height: 8),
          AppDialogMenuTile(
            icon: Icons.flag_outlined,
            label: 'Goal to win',
            onTap: () => _closeAndAsync(widget.onGoal),
          ),
          const SizedBox(height: 8),
          AppDialogMenuTile(
            icon: Icons.restart_alt,
            label: 'Restart game',
            onTap: () => _closeAnd(widget.onRestart),
          ),
          const SizedBox(height: 8),
          AppDialogMenuTile(
            icon: Icons.edit_outlined,
            label: widget.isAiGame ? 'Change your name' : 'Change player names',
            onTap: () => _closeAndAsync(widget.onEditNames),
          ),
          const SizedBox(height: 8),
          AppDialogMenuTile(
            icon: Icons.help_outline,
            label: 'Quick rules',
            onTap: () => _closeAndAsync(widget.onRules),
          ),
          const SizedBox(height: 8),
          AppDialogMenuTile(
            icon: Icons.person_outline,
            label: 'Profile & hints',
            onTap: () => _closeAnd(widget.onProfile),
          ),
          const SizedBox(height: 8),
          AppDialogMenuTile(
            icon: Icons.menu_book_outlined,
            label: 'Visual tutorial',
            onTap: () => _closeAnd(widget.onTutorial),
          ),
        ],
      ),
      actions: [
        AppDialogButton(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _GameMenuSoundTile extends StatelessWidget {
  const _GameMenuSoundTile({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundLight,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
              color: AppTheme.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game sounds',
                    style: AppTheme.text(size: 16, weight: FontWeight.w600),
                  ),
                  Text(
                    'Tap, move, and capture effects',
                    style: AppTheme.text(
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              activeColor: AppTheme.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
