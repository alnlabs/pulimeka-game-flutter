import 'package:flutter/material.dart';

import '../models/game_route_args.dart';
import '../widgets/offline_game_view.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, this.args});

  static const routeName = '/game';
  final GameRouteArgs? args;

  @override
  Widget build(BuildContext context) {
    final resolved = args ??
        ModalRoute.of(context)?.settings.arguments as GameRouteArgs? ??
        const GameRouteArgs();

    final modeLabel = switch (resolved.mode) {
      'ai' => 'Play with AI',
      'online' => 'Online Game',
      _ => 'Player Offline',
    };

    return OfflineGameView(
      tigerPlayerName: resolved.tigerPlayerName,
      goatPlayerName: resolved.goatPlayerName,
      modeLabel: modeLabel,
    );
  }
}
