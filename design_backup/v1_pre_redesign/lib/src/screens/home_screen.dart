import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_route_args.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import '../widgets/home_menu_button.dart';
import '../widgets/start_game_dialog.dart';
import 'ai_game_screen.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';
import 'how_to_play_screen.dart';
import 'online_room_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tigerNameController = TextEditingController();
  final _goatNameController = TextEditingController();
  String? _tigerNameError;
  String? _goatNameError;

  @override
  void dispose() {
    _tigerNameController.dispose();
    _goatNameController.dispose();
    super.dispose();
  }

  void _openOfflineGame() {
    final tiger = _tigerNameController.text.trim().isEmpty
        ? 'Tiger Player'
        : _tigerNameController.text.trim();
    final goat = _goatNameController.text.trim().isEmpty
        ? 'Goat Player'
        : _goatNameController.text.trim();

    Navigator.pushNamed(
      context,
      GameScreen.routeName,
      arguments: GameRouteArgs(
        mode: 'offline',
        tigerPlayerName: tiger,
        goatPlayerName: goat,
      ),
    );

    _tigerNameController.clear();
    _goatNameController.clear();
    setState(() {
      _tigerNameError = null;
      _goatNameError = null;
    });
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
          Navigator.pushNamed(context, OnlineRoomScreen.routeName);
        },
        onPlayAI: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AIGameScreen.routeName);
        },
      ),
    );
  }

  Future<void> _showPlayerNamesDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: const RoundedRectangleBorder(),
        title: Text(
          'Enter Player Names',
          style: AppTheme.text(size: 24, weight: FontWeight.bold, color: AppTheme.primaryLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tigerNameController,
              decoration: InputDecoration(
                labelText: 'Tiger Player Name',
                hintText: 'Enter name for Tiger player',
                errorText: _tigerNameError,
              ),
              maxLength: 20,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goatNameController,
              decoration: InputDecoration(
                labelText: 'Goat Player Name',
                hintText: 'Enter name for Goat player',
                errorText: _goatNameError,
              ),
              maxLength: 20,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final tigerErr = _tigerNameController.text.length > 20
                  ? 'Name must be 20 characters or less'
                  : null;
              final goatErr = _goatNameController.text.length > 20
                  ? 'Name must be 20 characters or less'
                  : null;
              if (tigerErr != null || goatErr != null) {
                setState(() {
                  _tigerNameError = tigerErr;
                  _goatNameError = goatErr;
                });
                return;
              }
              Navigator.pop(context);
              _openOfflineGame();
            },
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMoreMenu() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: const RoundedRectangleBorder(),
        title: Text(
          'More',
          style: AppTheme.text(size: 24, weight: FontWeight.bold, color: AppTheme.primaryLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HomeMenuButton(
              text: 'Game History',
              icon: Icons.list,
              color: AppTheme.primaryLight,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, HistoryScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
            HomeMenuButton(
              text: 'About',
              icon: Icons.info_outline,
              color: AppTheme.primaryLight,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AboutScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
            HomeMenuButton(
              text: 'Privacy Policy',
              icon: Icons.privacy_tip,
              color: AppTheme.primaryLight,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy policy screen coming soon')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showExitDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(
          'Enjoying Puli Meka?',
          style: AppTheme.text(size: 24, weight: FontWeight.bold, color: AppTheme.primaryLight),
        ),
        content: Text(
          'Please rate the app before exiting.',
          style: AppTheme.text(size: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Exit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
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
                        Image.asset(
                          'assets/images/playstore_icon.png',
                          width: AppTheme.logoSize,
                          height: AppTheme.logoSize,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          'Puli Meka',
                          style: AppTheme.text(
                            size: 28,
                            weight: FontWeight.bold,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Classic Indian Board Game',
                          style: AppTheme.text(size: 14, color: AppTheme.textTertiary),
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),
                        HomeMenuButton(
                          text: 'Start Game',
                          icon: Icons.play_arrow,
                          color: AppTheme.primary,
                          onTap: _showStartDialog,
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        HomeMenuButton(
                          text: 'How to Play',
                          icon: Icons.school,
                          color: AppTheme.primary,
                          onTap: () =>
                              Navigator.pushNamed(context, HowToPlayScreen.routeName),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        HomeMenuButton(
                          text: 'Settings',
                          icon: Icons.settings,
                          color: AppTheme.primary,
                          onTap: () =>
                              Navigator.pushNamed(context, SettingsScreen.routeName),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        HomeMenuButton(
                          text: 'More',
                          icon: Icons.more_horiz,
                          color: AppTheme.primary,
                          onTap: _showMoreMenu,
                        ),
                      ],
                    ),
                  ),
                ),
                const AdBanner(),
                const SizedBox(height: AppTheme.spacingMedium),
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
                Text(
                  'Nageshwar Reddy Pandem',
                  style: AppTheme.text(
                    size: 11,
                    weight: FontWeight.w600,
                    color: AppTheme.primary,
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
