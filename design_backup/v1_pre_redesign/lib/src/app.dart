import 'package:flutter/material.dart';

import 'models/game_route_args.dart';
import 'screens/ai_game_screen.dart';
import 'screens/game_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/about_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/online_game_screen.dart';
import 'screens/online_room_screen.dart';
import 'screens/settings_screen.dart';
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
        HowToPlayScreen.routeName: (context) => const HowToPlayScreen(),
        AboutScreen.routeName: (context) => const AboutScreen(),
        HistoryScreen.routeName: (context) => const HistoryScreen(),
        AIGameScreen.routeName: (context) => const AIGameScreen(),
        OnlineGameScreen.routeName: (context) => const OnlineGameScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == GameScreen.routeName) {
          final args = settings.arguments as GameRouteArgs?;
          return MaterialPageRoute(
            builder: (context) => GameScreen(args: args),
          );
        }
        if (settings.name == OnlineRoomScreen.routeName) {
          final args = settings.arguments as OnlineRoomRouteArguments?;
          return MaterialPageRoute(
            builder: (context) => OnlineRoomScreen(arguments: args),
          );
        }
        if (settings.name == '/online') {
          return MaterialPageRoute(
            builder: (context) => const OnlineRoomScreen(),
          );
        }
        return null;
      },
    );
  }
}
