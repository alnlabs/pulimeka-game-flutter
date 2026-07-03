import 'package:flutter/material.dart';

import '../models/game_result.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<GameResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _historyService.loadHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _historyService.loadHistory();
    });
    await _historyFuture;
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear history',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<GameResult>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Unable to load history: ${snapshot.error}'));
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const Center(child: Text('No game history yet. Play a game to save results.'));
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(item.mode.substring(0, 1)),
                      ),
                      title: Text('${item.mode} — ${item.winner}'),
                      subtitle: Text(
                        'Captured ${item.capturedGoats} goats • ${item.goatsPlaced} placed • ${item.playedAt.toLocal()}',
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
