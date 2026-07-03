import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/online_game_controller.dart';
import '../models/online_play_args.dart';
import '../services/game_history_recorder.dart';
import '../services/online_game_service.dart';
import '../services/online_session_prefs.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/layout_insets.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_dialog.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_message_bar.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/player_names_dialog.dart';
import '../widgets/ui_game_state_mapper.dart';
import 'home_screen.dart';

class OnlinePlayScreen extends StatefulWidget {
  const OnlinePlayScreen({super.key});

  static const routeName = '/online-play';

  @override
  State<OnlinePlayScreen> createState() => _OnlinePlayScreenState();
}

class _OnlinePlayScreenState extends State<OnlinePlayScreen> {
  OnlinePlayArgs? _args;
  OnlineGameController? _controller;
  StreamSubscription? _roomSub;
  Map<String, dynamic>? _room;
  bool _gameStarted = false;
  bool _winRecorded = false;
  bool _watchStarted = false;
  String _playerName = 'Player';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)?.settings.arguments as OnlinePlayArgs?;
    if (_args != null && _playerName == 'Player') {
      _playerName = _args!.playerName;
    }
    if (!_watchStarted && _args != null) {
      _watchStarted = true;
      _startRoomWatch();
    }
  }

  void _startRoomWatch() {
    final args = _args;
    if (args == null) return;

    _roomSub = OnlineGameService.instance.subscribeToRoom(
      args.roomId,
      (room) {
        if (!mounted) return;
        if (room == null) {
          _showRoomClosed();
          return;
        }
        final status = room['status']?.toString();
        final shouldStartGame = status == 'playing' && !_gameStarted;
        final statusChanged = _room?['status']?.toString() != status;
        final namesChanged = _room == null ||
            room['hostName']?.toString() != _room!['hostName']?.toString() ||
            room['guestName']?.toString() != _room!['guestName']?.toString();

        if (_gameStarted && !shouldStartGame && !statusChanged && !namesChanged) {
          return;
        }

        setState(() {
          _room = room;
          if (shouldStartGame) {
            _gameStarted = true;
            _startGame(args);
          }
        });
      },
    );

    OnlineGameService.instance.updateRoomActivity(args.roomId, args.playerId);
  }

  void _startGame(OnlinePlayArgs args) {
    _controller?.dispose();
    _controller = OnlineGameController(
      roomId: args.roomId,
      playerId: args.playerId,
      playerRole: args.playerRole,
      isHost: args.isHost,
    )..start();
    _controller!.addListener(_onGameUpdate);
  }

  void _onGameUpdate() {
    final c = _controller;
    if (c == null || _winRecorded) return;
    if (c.gameState.winner != null) {
      _winRecorded = true;
      _recordWin(c.gameState.winner!);
      setState(() {});
      return;
    }
  }

  String _nameForRole(String role) {
    final args = _args;
    final room = _room;
    if (args == null) {
      return role == 'tiger' ? 'Tiger' : 'Goat';
    }
    if (room == null) {
      if (args.playerRole == role) return _playerName;
      return args.opponentName ?? (role == 'tiger' ? 'Tiger' : 'Goat');
    }

    final hostRole = room['hostRole']?.toString() ?? 'tiger';
    final hostName = room['hostName']?.toString() ?? 'Host';
    final guestName = room['guestName']?.toString() ?? 'Guest';
    if (role == hostRole) return hostName;
    return guestName;
  }

  String get _tigerName => _nameForRole('tiger');
  String get _goatName => _nameForRole('goat');

  Future<void> _editPlayerName() async {
    final args = _args;
    if (args == null) return;

    final result = await showSinglePlayerNameDialog(
      context,
      initialName: _playerName,
      title: 'Change your name',
    );
    if (result == null || !mounted) return;

    setState(() => _playerName = result);
    await OnlineSessionPrefs.setPlayerName(result);
    try {
      await OnlineGameService.instance.updatePlayerName(
        roomId: args.roomId,
        playerId: args.playerId,
        playerName: result,
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Name saved on device; room sync failed.');
      }
    }
  }

  Future<void> _showOnlineRules() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Quick rules',
        icon: Icons.menu_book_outlined,
        content: const AppDialogBodyText(
          'Tigers win by capturing 12 goats.\n\n'
          'Goats win by trapping all tigers.\n\n'
          'Take turns when it is your move. Select a piece, then tap a highlighted node.',
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

  Future<void> _recordWin(String winner) async {
    final args = _args;
    if (args == null) return;
    final humanWon = (winner == 'tigers' && args.playerRole == 'tiger') ||
        (winner == 'goats' && args.playerRole == 'goat');
    await GameHistoryRecorder.instance.recordMatch(
      playerName: _playerName,
      opponentName: _opponentName,
      mode: 'online',
      humanWon: humanWon,
      capturedGoats: _controller?.gameState.capturedGoats ?? 0,
      goatsPlaced: 0,
    );
  }

  String? get _opponentName {
    final args = _args;
    final room = _room;
    if (args == null || room == null) return args?.opponentName;
    if (args.isHost) {
      return room['guestName']?.toString();
    }
    return room['hostName']?.toString();
  }

  Future<void> _copyCode() async {
    final id = _args?.roomId;
    if (id == null) return;
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) {
      showAppSnackBar(context, 'Room code copied');
    }
  }

  Future<void> _shareCode() async {
    final id = _args?.roomId;
    if (id == null) return;
    await Share.share('Join my Puli Meka game! Room code: $id');
  }

  Future<void> _leave() async {
    final args = _args;
    if (args == null) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Leave game?',
        icon: Icons.logout,
        content: const AppDialogBodyText('You will leave this online room.'),
        actions: [
          AppDialogButton(label: 'Stay', onPressed: () => Navigator.pop(ctx, false)),
          AppDialogButton(
            label: 'Leave',
            primary: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    await OnlineGameService.instance.leaveRoom(args.roomId, args.playerId);
    await OnlineSessionPrefs.clearActiveSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      HomeScreen.routeName,
      (route) => false,
    );
  }

  Future<void> _cancelRoom() async {
    final args = _args;
    if (args == null || !args.isHost) return;
    try {
      await OnlineGameService.instance.cancelRoom(args.roomId, args.playerId);
      await OnlineSessionPrefs.clearActiveSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          HomeScreen.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.toString());
      }
    }
  }

  void _showRoomClosed() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppDialog(
        title: 'Room closed',
        icon: Icons.cloud_off,
        content: const AppDialogBodyText('This room is no longer available.'),
        actions: [
          AppDialogButton(
            label: 'Home',
            primary: true,
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                HomeScreen.routeName,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _controller?.removeListener(_onGameUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args == null) {
      return const Scaffold(body: Center(child: Text('Invalid session')));
    }

    if (!_gameStarted && (args.waitingForGuest || _room?['status'] == 'waiting')) {
      return _WaitingView(
        roomId: args.roomId,
        isHost: args.isHost,
        playerName: _playerName,
        onEditName: _editPlayerName,
        onCopy: _copyCode,
        onShare: _shareCode,
        onCancel: args.isHost ? _cancelRoom : null,
        onLeave: _leave,
      );
    }

    final c = _controller;
    if (c == null || c.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Online game')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (c.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Online game')),
        body: Center(child: Text(c.error!)),
      );
    }

    final gs = c.gameState;
    final roleLabel = args.playerRole == 'tiger' ? 'Tiger' : 'Goat';
    final turnLabel = gs.winner != null
        ? (gs.winner == 'tigers' ? '$_tigerName wins!' : '$_goatName wins!')
        : c.isMyTurn
            ? 'Your turn ($roleLabel)'
            : 'Opponent\'s turn';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          GameTopBar(
            key: const ValueKey('online_game_top_bar'),
            modeLabel: 'Online game',
            subtitle: '$_tigerName vs $_goatName',
            hintLabel: turnLabel,
            showHintBar: true,
            showHintActions: false,
            showRestartInMenu: false,
            editNamesLabel: 'Change your name',
            onBack: _leave,
            onHint: _showOnlineRules,
            onRules: _showOnlineRules,
            onRestart: _leave,
            onMenu: _leave,
            onEditNames: _editPlayerName,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) {
                final state = c.gameState;
                final ui = uiStateFromGameState(state, selectedNode: c.selectedNode);
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Column(
                      children: [
                        if (state.winner != null)
                          GameWinnerBanner(
                            winner: state.winner!,
                            tigerName: _tigerName,
                            goatName: _goatName,
                          )
                        else
                          GameHud(
                            ui: ui,
                            tigerName: _tigerName,
                            goatName: _goatName,
                            showTutorialPlacementHints: false,
                          ),
                        GameMessageBar(
                          hintMessage: c.isMyTurn ? null : 'Waiting for opponent…',
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GameBoardWidget(
                              gameState: state,
                              selectedNode: c.selectedNode,
                              validTargets: c.validTargets,
                              onNodeTap: c.onNodeTap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              AppTheme.spacingSmall,
              12,
              AppTheme.spacingSmall + bottomChromePadding(context),
            ),
            child: const AdBanner(),
          ),
        ],
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView({
    required this.roomId,
    required this.isHost,
    required this.playerName,
    required this.onEditName,
    required this.onCopy,
    required this.onShare,
    required this.onLeave,
    this.onCancel,
  });

  final String roomId;
  final bool isHost;
  final String playerName;
  final VoidCallback onEditName;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onLeave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Waiting for opponent'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onLeave),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Playing as',
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              playerName,
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 18, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onEditName,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Change your name'),
            ),
            const SizedBox(height: 20),
            Text(
              isHost
                  ? 'Share this room code with your friend:'
                  : 'Connecting…',
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 16),
            ),
            const SizedBox(height: 12),
            SelectableText(
              roomId,
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 14, weight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy),
              label: const Text('Copy room code'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text('Share room code'),
            ),
            if (onCancel != null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel room'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
