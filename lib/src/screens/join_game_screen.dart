import 'dart:async';

import 'package:flutter/material.dart';

import '../models/online_play_args.dart';
import '../services/online_game_service.dart';
import '../services/online_session_prefs.dart';
import '../theme/app_theme.dart';
import 'online_play_screen.dart';

/// Online lobby: Create / Join list / Join by code (Android `JoinGameActivity`).
class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({this.initialTab = 1, super.key});

  static const routeName = '/join-online';

  final int initialTab;

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String _role = 'tiger';
  String? _playerId;
  String? _error;
  bool _loading = false;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _init();
  }

  Future<void> _init() async {
    final name = await OnlineSessionPrefs.getPlayerName();
    _playerId = await OnlineSessionPrefs.getPlayerId();
    if (mounted) {
      _nameController.text = name;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _playerName {
    final n = _nameController.text.trim();
    return n.isEmpty ? 'Player' : n;
  }

  Future<void> _saveName() async {
    await OnlineSessionPrefs.setPlayerName(_playerName);
  }

  void _openPlay(OnlinePlayArgs args) {
    Navigator.pushReplacementNamed(
      context,
      OnlinePlayScreen.routeName,
      arguments: args,
    );
  }

  Future<void> _createRoom() async {
    if (_playerId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _saveName();
    try {
      if (!OnlineGameService.instance.isAvailable) {
        throw StateError('Firebase is not available. Check your connection.');
      }
      await OnlineGameService.instance.deleteMyRooms(_playerId!);
      final roomId = await OnlineGameService.instance.createRoom(
        playerId: _playerId!,
        playerName: _playerName,
        playerRole: _role,
      );
      await OnlineSessionPrefs.saveActiveSession(
        roomId: roomId,
        playerId: _playerId!,
        isHost: true,
        playerRole: _role,
      );
      if (!mounted) return;
      _openPlay(OnlinePlayArgs(
        roomId: roomId,
        playerId: _playerId!,
        isHost: true,
        playerRole: _role,
        playerName: _playerName,
        waitingForGuest: true,
      ));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom(String roomId) async {
    if (_playerId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _saveName();
    try {
      final room = await OnlineGameService.instance.joinRoom(
        roomId: roomId,
        playerId: _playerId!,
        playerName: _playerName,
      );
      final guestRole = room['guestRole']?.toString() ?? 'goat';
      await OnlineSessionPrefs.saveActiveSession(
        roomId: roomId,
        playerId: _playerId!,
        isHost: false,
        playerRole: guestRole,
      );
      if (!mounted) return;
      _openPlay(OnlinePlayArgs(
        roomId: roomId,
        playerId: _playerId!,
        isHost: false,
        playerRole: guestRole,
        playerName: _playerName,
        opponentName: room['hostName']?.toString(),
      ));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a room code');
      return;
    }
    await _joinRoom(code);
  }

  @override
  Widget build(BuildContext context) {
    if (!OnlineGameService.instance.isAvailable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Online Multiplayer')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Online play needs Firebase. Ensure google-services / GoogleService-Info.plist are configured and you have network access.',
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Online Multiplayer'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnDark,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.textOnDark,
          labelColor: AppTheme.textOnDark,
          unselectedLabelColor: AppTheme.textOnDark.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Create'),
            Tab(text: 'Join'),
            Tab(text: 'Code'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: TextField(
              controller: _nameController,
              maxLength: 20,
              decoration: AppTheme.inputDecoration(
                label: 'Your name',
                hint: 'Max 20 characters',
              ),
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: AppTheme.text(size: 14, color: const Color(0xFFC62828)),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _CreateTab(
                  role: _role,
                  loading: _loading,
                  onRoleChanged: (r) => setState(() => _role = r),
                  onCreate: _createRoom,
                ),
                _JoinListTab(
                  rooms: _rooms,
                  loading: _loading,
                  onRefresh: () async {
                    // Rooms stream handled in tab state
                  },
                  onJoin: _joinRoom,
                ),
                _CodeTab(
                  controller: _codeController,
                  loading: _loading,
                  onJoin: _joinByCode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateTab extends StatelessWidget {
  const _CreateTab({
    required this.role,
    required this.loading,
    required this.onRoleChanged,
    required this.onCreate,
  });

  final String role;
  final bool loading;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose your role', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tiger', label: Text('Tiger')),
              ButtonSegment(value: 'goat', label: Text('Goat')),
            ],
            selected: {role},
            onSelectionChanged: (s) => onRoleChanged(s.first),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading ? null : onCreate,
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create room'),
          ),
        ],
      ),
    );
  }
}

class _JoinListTab extends StatefulWidget {
  const _JoinListTab({
    required this.rooms,
    required this.loading,
    required this.onRefresh,
    required this.onJoin,
  });

  final List<Map<String, dynamic>> rooms;
  final bool loading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String roomId) onJoin;

  @override
  State<_JoinListTab> createState() => _JoinListTabState();
}

class _JoinListTabState extends State<_JoinListTab> {
  StreamSubscription? _sub;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _sub = OnlineGameService.instance.subscribeToAvailableRooms((rooms) {
      if (mounted) setState(() => _rooms = rooms);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_rooms.isEmpty) {
      return Center(
        child: Text(
          'No open rooms. Create one or join by code.',
          style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final id = room['roomId']?.toString() ?? '';
        final host = room['hostName']?.toString() ?? 'Host';
        final hostRole = room['hostRole']?.toString() ?? 'tiger';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(host),
            subtitle: Text('Room: $id • Host: $hostRole'),
            trailing: widget.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            onTap: widget.loading ? null : () => widget.onJoin(id),
          ),
        );
      },
    );
  }
}

class _CodeTab extends StatelessWidget {
  const _CodeTab({
    required this.controller,
    required this.loading,
    required this.onJoin,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: AppTheme.inputDecoration(
              label: 'Room code',
              hint: 'Paste room ID from host',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : onJoin,
            child: const Text('Join room'),
          ),
        ],
      ),
    );
  }
}
