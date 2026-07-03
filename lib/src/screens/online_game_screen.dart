import 'package:flutter/material.dart';

import 'join_game_screen.dart';

/// Legacy route — redirects to [JoinGameScreen].
class OnlineGameScreen extends StatelessWidget {
  const OnlineGameScreen({super.key});

  static const routeName = '/online';

  @override
  Widget build(BuildContext context) {
    return const JoinGameScreen(initialTab: 1);
  }
}
