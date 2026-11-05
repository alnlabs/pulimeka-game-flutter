import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets/game_assets.dart';
import '../models/game_route_args.dart';
import '../models/online_play_args.dart';
import '../services/campaign_progress_service.dart';
import '../services/offline_player_prefs.dart';
import '../services/online_game_service.dart';
import '../services/online_session_prefs.dart';
import '../theme/app_theme.dart';
import '../utils/external_links.dart';
import '../utils/layout_insets.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_dialog.dart';
import '../widgets/home_menu_button.dart';
import '../widgets/player_names_dialog.dart';
import '../widgets/start_game_dialog.dart';
import 'about_game_screen.dart';
import 'about_screen.dart';
import 'ai_game_screen.dart';
import 'campaign_map_screen.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'how_to_play_screen.dart';
import 'join_game_screen.dart';
import 'online_play_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _careerLevel = 1;
  int _careerStars = 0;

  @override
  void initState() {
    super.initState();
    _loadCareerSummary();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryResumeOnlineGame());
  }

  Future<void> _loadCareerSummary() async {
    try {
      final unlocked =
          await CampaignProgressService.instance.continueLevelId();
      final stars = await CampaignProgressService.instance.totalStars();
      if (!mounted) return;
      setState(() {
        _careerLevel = unlocked;
        _careerStars = stars;
      });
    } catch (_) {}
  }

  Future<void> _tryResumeOnlineGame() async {
    await OnlineGameService.instance.tryResumeActiveSession(
      onSuccess: (session) async {
        final name = await OnlineSessionPrefs.getPlayerName();
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          OnlinePlayScreen.routeName,
          arguments: OnlinePlayArgs(
            roomId: session.roomId,
            playerId: session.playerId,
            isHost: session.isHost,
            playerRole: session.playerRole,
            playerName: name,
            waitingForGuest: session.isHost,
          ),
        );
      },
      onUnavailable: () {},
    );
  }

  Future<void> _showPlayerNamesDialog() async {
    final saved = await OfflinePlayerPrefs.getNames();
    if (!mounted) return;

    final result = await showOfflinePlayerNamesDialog(
      context,
      initialTiger: saved.tiger,
      initialGoat: saved.goat,
      title: 'Player names',
    );
    if (!mounted || result == null) return;

    await OfflinePlayerPrefs.setNames(tiger: result.tiger, goat: result.goat);
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      GameScreen.routeName,
      arguments: GameRouteArgs(
        mode: 'offline',
        tigerPlayerName: result.tiger,
        goatPlayerName: result.goat,
      ),
    );
  }

  Future<void> _showPlayDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => StartGameDialog(
        onDismiss: () => Navigator.pop(context),
        onPlayOffline: () {
          Navigator.pop(context);
          _showPlayerNamesDialog();
        },
        onPlayOnline: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, JoinGameScreen.routeName);
        },
        onPlayAi: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AIGameScreen.routeName);
        },
      ),
    );
  }

  Future<void> _showMoreMenu() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        title: 'More',
        icon: Icons.more_horiz,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDialogMenuTile(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, ProfileScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
            AppDialogMenuTile(
              icon: Icons.leaderboard_outlined,
              label: 'Stats',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, HistoryScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
            AppDialogMenuTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, SettingsScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
            AppDialogMenuTile(
              icon: Icons.history_edu_outlined,
              label: 'About the game',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AboutGameScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
            AppDialogMenuTile(
              icon: Icons.smartphone_outlined,
              label: 'About this app',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AboutScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
            AppDialogMenuTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy policy',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, PrivacyPolicyScreen.routeName);
              },
            ),
          ],
        ),
        actions: [
          AppDialogButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: 'Enjoying Puli Meka?',
        icon: Icons.star_outline,
        content: const AppDialogBodyText(
          'Your rating helps others discover this game. You can rate now or exit without rating.',
        ),
        actions: [
          AppDialogButton(
            label: 'Stay',
            onPressed: () => Navigator.pop(context),
          ),
          AppDialogButton(
            label: 'Exit',
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
          ),
          AppDialogButton(
            label: 'Rate & exit',
            primary: true,
            onPressed: () async {
              Navigator.pop(context);
              await ExternalLinks.openAppStoreListing();
              if (mounted) SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppTheme.spacingLarge),
                            Image.asset(
                              GameAssets.playstoreIcon,
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Puli Meka',
                              style: AppTheme.text(
                                size: 32,
                                weight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tigers vs Goats',
                              style: AppTheme.text(
                                size: 15,
                                weight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 28),
                            HomeMenuButton(
                              text: 'Play',
                              icon: Icons.play_arrow_rounded,
                              onTap: _showPlayDialog,
                            ),
                            const SizedBox(height: 10),
                            HomeMenuButton(
                              text: 'Career',
                              icon: Icons.emoji_events_outlined,
                              style: HomeMenuStyle.secondary,
                              subtitle: _careerStars > 0
                                  ? 'Continue level $_careerLevel · $_careerStars★'
                                  : '20 stages · start at level $_careerLevel',
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  CampaignMapScreen.routeName,
                                );
                                await _loadCareerSummary();
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _HomeLink(
                                  label: 'How to play',
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    HowToPlayScreen.routeName,
                                  ),
                                ),
                                _HomeDot(),
                                _HomeLink(
                                  label: 'More',
                                  onTap: _showMoreMenu,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const AdBanner(),
                SizedBox(
                  height: AppTheme.spacingSmall + bottomChromePadding(context),
                ),
                GestureDetector(
                  onTap: () => ExternalLinks.openWebsite(),
                  child: Text(
                    'by ALN Labs',
                    style: AppTheme.text(
                      size: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeLink extends StatelessWidget {
  const _HomeLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(
        label,
        style: AppTheme.text(
          size: 14,
          weight: FontWeight.w600,
          color: AppTheme.primaryDark,
        ),
      ),
    );
  }
}

class _HomeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '·',
      style: AppTheme.text(size: 16, color: AppTheme.textTertiary),
    );
  }
}
