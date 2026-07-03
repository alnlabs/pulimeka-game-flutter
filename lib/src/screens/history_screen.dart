import 'package:flutter/material.dart';

import '../models/game_result.dart';
import '../models/leaderboard_entry.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<GameResult>> _historyFuture;
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _historyFuture = _historyService.loadHistory();
      _leaderboardFuture = _historyService.loadLeaderboard();
    });
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stats'),
          centerTitle: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textOnDark,
          iconTheme: const IconThemeData(color: AppTheme.textOnDark),
          bottom: TabBar(
            labelColor: AppTheme.textOnDark,
            unselectedLabelColor: AppTheme.textOnDark.withOpacity(0.65),
            indicatorColor: AppTheme.textOnDark,
            indicatorWeight: 3,
            labelStyle: AppTheme.text(size: 14, weight: FontWeight.w600),
            unselectedLabelStyle: AppTheme.text(size: 14, weight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Leaderboard'),
              Tab(text: 'History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear all stats',
              onPressed: _clearHistory,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            FutureBuilder<List<LeaderboardEntry>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final board = snapshot.data ?? [];
                if (board.isEmpty) {
                  return const Center(child: Text('No stats yet. Play a game!'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: board.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final e = board[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.textOnDark,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(e.playerName),
                      subtitle: Text(
                        'W ${e.wins} · L ${e.losses} · D ${e.draws}',
                      ),
                    );
                  },
                );
              },
            ),
            FutureBuilder<List<GameResult>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return const Center(
                    child: Text('No game history yet. Play a game to save results.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(item.mode.substring(0, 1).toUpperCase()),
                        ),
                        title: Text('${item.mode} — ${item.winner}'),
                        subtitle: Text(
                          'Captured ${item.capturedGoats} goats • ${item.playedAt.toLocal()}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
