import 'package:flutter/material.dart';

import 'models/game_route_args.dart';
import 'screens/ai_game_screen.dart';
import 'screens/campaign_game_screen.dart';
import 'screens/campaign_map_screen.dart';
import 'screens/game_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/about_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/about_game_screen.dart';
import 'screens/join_game_screen.dart';
import 'screens/online_game_screen.dart';
import 'screens/online_play_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'models/online_play_args.dart';
import 'theme/app_theme.dart';

class PuliMekaApp extends StatelessWidget {
  const PuliMekaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puli Meka',
      theme: AppTheme.materialTheme(),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        HowToPlayScreen.routeName: (context) => const HowToPlayScreen(),
        TutorialScreen.routeName: (context) => const TutorialScreen(),
        AboutScreen.routeName: (context) => const AboutScreen(),
        HistoryScreen.routeName: (context) => const HistoryScreen(),
        AIGameScreen.routeName: (context) => const AIGameScreen(),
        CampaignMapScreen.routeName: (context) => const CampaignMapScreen(),
        JoinGameScreen.routeName: (context) => const JoinGameScreen(),
        OnlineGameScreen.routeName: (context) => const OnlineGameScreen(),
        OnlinePlayScreen.routeName: (context) => const OnlinePlayScreen(),
        PrivacyPolicyScreen.routeName: (context) => const PrivacyPolicyScreen(),
        AboutGameScreen.routeName: (context) => const AboutGameScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == CampaignGameScreen.routeName) {
          final levelId = settings.arguments is int ? settings.arguments as int : 1;
          return MaterialPageRoute(
            builder: (context) => CampaignGameScreen(levelId: levelId),
            settings: settings,
          );
        }
        if (settings.name == GameScreen.routeName) {
          final args = settings.arguments as GameRouteArgs?;
          return MaterialPageRoute(
            builder: (context) => GameScreen(args: args),
          );
        }
        if (settings.name == OnlinePlayScreen.routeName) {
          final args = settings.arguments as OnlinePlayArgs?;
          return MaterialPageRoute(
            builder: (context) => OnlinePlayScreen(key: ValueKey(args?.roomId)),
            settings: settings,
          );
        }
        if (settings.name == '/online' || settings.name == '/online-room') {
          return MaterialPageRoute(
            builder: (context) => const JoinGameScreen(initialTab: 1),
          );
        }
        return null;
      },
    );
  }
}
