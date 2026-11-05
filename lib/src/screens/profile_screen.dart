import 'package:flutter/material.dart';
import '../models/hint_policy.dart';
import '../models/player_profile.dart';
import '../services/campaign_progress_service.dart';
import '../services/hint_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<PlayerProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _profileFuture = HintService.instance.loadProfile();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Hints & activity'),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnDark,
      ),
      bottomNavigationBar: const ScreenAdBar(),
      body: FutureBuilder<PlayerProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              children: [
                FutureBuilder<(int, int)>(
                  future: () async {
                    final stars =
                        await CampaignProgressService.instance.totalStars();
                    final unlocked = await CampaignProgressService.instance
                        .highestUnlocked();
                    return (stars, unlocked);
                  }(),
                  builder: (context, snap) {
                    final stars = snap.data?.$1 ?? 0;
                    final unlocked = snap.data?.$2 ?? 1;
                    return _Card(
                      title: 'Career',
                      child: _StatRow(
                        label: 'Stars · continue at level $unlocked',
                        value:
                            '$stars/${CampaignProgressService.maxStars}',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _Card(
                  title: 'Started playing',
                  child: Text(
                    _formatDate(p.firstPlayDate),
                    style: AppTheme.text(size: 18, weight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: 'Games completed',
                  child: Text(
                    '${p.gamesCompleted}',
                    style: AppTheme.text(size: 18, weight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: 'Hint status',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.hintPhaseLabel,
                        style: AppTheme.text(
                          size: 16,
                          weight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.hintCountSummary,
                        style: AppTheme.text(
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: 'Hint counts',
                  child: Column(
                    children: [
                      _StatRow(
                        label: 'Total hints used',
                        value: '${p.totalHintsUsed}',
                      ),
                      const Divider(height: 20),
                      _StatRow(
                        label: 'Free hints left',
                        value: '${p.freeHintsRemaining}',
                      ),
                      _StatRow(
                        label: 'Current pack (${HintPolicy.hintsPerAdBatch} per ad)',
                        value: '${p.batchHintsRemaining}',
                      ),
                      if (p.isTutorialPhase) ...[
                        const Divider(height: 20),
                        Text(
                          'Tutorial: unlimited auto hints for your first '
                          '${HintPolicy.tutorialGames} completed games.',
                          style: AppTheme.text(
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ] else ...[
                        const Divider(height: 20),
                        Text(
                          'After free hints run out, tap the hint button to unlock '
                          '${HintPolicy.hintsPerAdBatch} more hints.',
                          style: AppTheme.text(
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.panelDecoration(color: AppTheme.cardWhite),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.text(
              size: 13,
              weight: FontWeight.w600,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.text(size: 14)),
          Text(
            value,
            style: AppTheme.text(size: 14, weight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
