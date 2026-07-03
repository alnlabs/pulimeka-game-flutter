import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../assets/game_assets.dart';
import '../models/game_route_args.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/app_dialog.dart';
import '../widgets/home_menu_button.dart';
import '../widgets/player_names_dialog.dart';
import '../widgets/start_game_dialog.dart';
import 'ai_game_screen.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';
import 'tutorial_screen.dart';
import '../models/online_play_args.dart';
import '../services/online_game_service.dart';
import '../services/offline_player_prefs.dart';
import '../services/online_session_prefs.dart';
import '../utils/external_links.dart';
import '../utils/layout_insets.dart';
import 'join_game_screen.dart';
import 'online_play_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_game_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryResumeOnlineGame());
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
    _openOfflineGameWithNames(result.tiger, result.goat);
  }

  void _openOfflineGameWithNames(String tiger, String goat) {
    Navigator.pushNamed(
      context,
      GameScreen.routeName,
      arguments: GameRouteArgs(
        mode: 'offline',
        tigerPlayerName: tiger,
        goatPlayerName: goat,
      ),
    );
  }

  Future<void> _showStartDialog() async {
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
        onPlayAI: () {
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
        title: 'About',
        icon: Icons.info_outline,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          AppDialogButton(label: 'Close', onPressed: () => Navigator.pop(context)),
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
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: AppTheme.spacingLarge),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: AppTheme.panelDecoration(
                              color: AppTheme.cardWhite,
                              borderColor: AppTheme.borderSubtle,
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  GameAssets.playstoreIcon,
                                  width: AppTheme.logoSize,
                                  height: AppTheme.logoSize,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: AppTheme.spacingMedium),
                                Text(
                                  'Puli Meka',
                                  style: AppTheme.text(
                                    size: 30,
                                    weight: FontWeight.bold,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tigers vs Goats',
                                  style: AppTheme.text(
                                    size: 15,
                                    weight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Classic Indian board game',
                                  style: AppTheme.text(
                                    size: 13,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLarge),
                          HomeMenuButton(
                            text: 'Start Game',
                            icon: Icons.play_arrow,
                            onTap: _showStartDialog,
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          HomeMenuButton(
                            text: 'How to play',
                            icon: Icons.menu_book_outlined,
                            style: HomeMenuStyle.secondary,
                            onTap: () =>
                                Navigator.pushNamed(context, TutorialScreen.routeName),
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          HomeMenuButton(
                            text: 'Profile',
                            icon: Icons.person_outline,
                            style: HomeMenuStyle.secondary,
                            onTap: () =>
                                Navigator.pushNamed(context, ProfileScreen.routeName),
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          HomeMenuButton(
                            text: 'Stats',
                            icon: Icons.leaderboard_outlined,
                            style: HomeMenuStyle.secondary,
                            onTap: () =>
                                Navigator.pushNamed(context, HistoryScreen.routeName),
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          HomeMenuButton(
                            text: 'Settings',
                            icon: Icons.settings_outlined,
                            style: HomeMenuStyle.secondary,
                            onTap: () =>
                                Navigator.pushNamed(context, SettingsScreen.routeName),
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          HomeMenuButton(
                            text: 'About',
                            icon: Icons.info_outline,
                            style: HomeMenuStyle.secondary,
                            onTap: _showMoreMenu,
                          ),
                      ],
                    ),
                  ),
                ),
                const AdBanner(),
                SizedBox(height: AppTheme.spacingMedium + bottomChromePadding(context)),
                Text(
                  'Tigers vs Goats',
                  style: AppTheme.text(
                    size: 12,
                    weight: FontWeight.w500,
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  'Designed and developed by',
                  style: AppTheme.text(size: 10, color: AppTheme.textTertiary),
                ),
                GestureDetector(
                  onTap: () => ExternalLinks.openLinkedIn(),
                  child: Text(
                    'Nageshwar Reddy Pandem',
                    style: AppTheme.text(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppTheme.primary,
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
