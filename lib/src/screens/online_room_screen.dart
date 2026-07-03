import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/online_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/game_board_widget.dart';

class OnlineRoomRouteArguments {
  final String roomId;
  final String playerId;
  final bool isOwner;

  const OnlineRoomRouteArguments({
    required this.roomId,
    required this.playerId,
    required this.isOwner,
  });
}

class OnlineRoomScreen extends StatefulWidget {
  const OnlineRoomScreen({
    this.arguments,
    super.key,
  });

  static const routeName = '/online-room';

  final OnlineRoomRouteArguments? arguments;

  @override
  State<OnlineRoomScreen> createState() => _OnlineRoomScreenState();
}

class _OnlineRoomScreenState extends State<OnlineRoomScreen> {
  final OnlineService _onlineService = OnlineService();
  OnlineRoom? _room;
  StreamSubscription<OnlineRoom>? _subscription;
  String? _selectedNode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupRoom();
  }

  void _setupRoom() {
    final args = widget.arguments;
    if (args == null) return;

    final room = _onlineService.getRoom(args.roomId);
    if (room == null) {
      setState(() {
        _error = 'Room not found.';
      });
      return;
    }

    _room = room;
    _subscription = room.updates.listen((updatedRoom) {
      if (mounted) {
        setState(() {
          _room = updatedRoom;
        });
      }
    });
  }

  Future<void> _createRoom() async {
    final ownerId = 'player-${DateTime.now().millisecondsSinceEpoch}';
    final room = await _onlineService.createGameRoom(ownerId);
    if (!mounted) return;
    final args = OnlineRoomRouteArguments(
      roomId: room.roomId,
      playerId: room.ownerId,
      isOwner: true,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OnlineRoomScreen(arguments: args),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  PieceType? get _myRole {
    final args = widget.arguments;
    if (args == null) return null;
    return _room?.roleFor(args.playerId);
  }

  bool get _canPlay {
    if (_room == null || !_room!.started || _myRole == null) {
      return false;
    }
    return _room!.gameState.currentTurn == _myRole;
  }

  void _handleTap(String node) {
    if (_room == null || !_canPlay || _room!.gameState.winner != null) {
      return;
    }
    final gameState = _room!.gameState;
    final piece = gameState.pieceAt(node);
    final validTargets = _selectedNode != null ? gameState.getValidTargets(_selectedNode!) : <String>{};

    setState(() {
      if (gameState.isPlacementPhase && _myRole == PieceType.goat && piece == null) {
        gameState.applyPlacement(node);
        _selectedNode = null;
        _room!.updateState();
        return;
      }

      if (_selectedNode != null && validTargets.contains(node)) {
        gameState.applyMove(_selectedNode!, node);
        _selectedNode = null;
        _room!.updateState();
        return;
      }

      if (piece == _myRole) {
        _selectedNode = _selectedNode == node ? null : node;
        return;
      }

      _selectedNode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.arguments == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Play Online'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Play with friends online',
                style: AppTheme.text(size: 18, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _createRoom,
                child: const Text('Create Room (Host as Tiger)'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Join flow uses Firebase in the native Android app. '
                'Use Create Room for local testing in Flutter.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Online Room')),
        body: Center(child: Text(_error!)),
      );
    }

    final room = _room;
    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Online Room')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final myRole = _myRole;
    final roleLabel = myRole == PieceType.tiger ? 'Tiger' : 'Goat';
    final status = room.started
        ? room.gameState.winner != null
            ? '${room.gameState.winner} win!'
            : room.gameState.currentTurn == myRole
                ? 'Your turn ($roleLabel).'
                : 'Waiting for opponent...'
        : 'Waiting for a friend to join room.';

    final validTargets = _selectedNode != null ? room.gameState.getValidTargets(_selectedNode!) : <String>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Room'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoomHeader(
                room: room,
                roleLabel: roleLabel,
                status: status,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GameBoardWidget(
                  gameState: room.gameState,
                  selectedNode: _selectedNode,
                  validTargets: validTargets,
                  onNodeTap: _handleTap,
                ),
              ),
              const SizedBox(height: 16),
              Text('Room code: ${room.roomId}',textAlign: TextAlign.center),
              const SizedBox(height: 8),
              if (!room.started)
                const Text(
                  'Share this code with your friend. They will join as Goat.',
                  textAlign: TextAlign.center,
                ),
              if (room.started && room.gameState.winner != null)
                const Text('Game complete. Return to Home to create a new room.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const AdBanner(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.room,
    required this.roleLabel,
    required this.status,
  });

  final OnlineRoom room;
  final String roleLabel;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _HeaderChip(label: 'Room', value: room.roomId),
            _HeaderChip(label: 'You are', value: roleLabel),
            _HeaderChip(label: 'Guest', value: room.guestId ?? 'Waiting'),
          ],
        ),
        const SizedBox(height: 12),
        Text(status, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.brown.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
