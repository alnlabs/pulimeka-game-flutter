import 'dart:math';

import 'package:flutter/material.dart';

import '../services/online_service.dart';
import 'online_room_screen.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key});

  static const routeName = '/online';

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final OnlineService _onlineService = OnlineService();
  final TextEditingController _roomCodeController = TextEditingController();
  String? _status;
  bool _isLoading = false;

  String get _playerId => 'P${Random().nextInt(999999)}';

  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
      _status = null;
    });

    try {
      final room = await _onlineService.createGameRoom(_playerId);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        OnlineRoomScreen.routeName,
        arguments: OnlineRoomRouteArguments(
          roomId: room.roomId,
          playerId: _playerId,
          isOwner: true,
        ),
      );
    } catch (error) {
      setState(() {
        _status = 'Unable to create room: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinRoom() async {
    final roomId = _roomCodeController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _status = 'Enter a room code before joining.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = null;
    });

    try {
      final room = await _onlineService.joinGameRoom(roomId, _playerId);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        OnlineRoomScreen.routeName,
        arguments: OnlineRoomRouteArguments(
          roomId: room.roomId,
          playerId: _playerId,
          isOwner: false,
        ),
      );
    } catch (error) {
      setState(() {
        _status = 'Unable to join room: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Multiplayer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create or join a game room. After creating a room, share the code with a friend so they can join on another device.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_box),
                label: const Text('Create room'),
                onPressed: _isLoading ? null : _createRoom,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _roomCodeController,
                decoration: const InputDecoration(
                  labelText: 'Room code',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Join room'),
                onPressed: _isLoading ? null : _joinRoom,
              ),
              const SizedBox(height: 20),
              if (_status != null) ...[
                Text(_status!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
              ],
              if (_isLoading) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
