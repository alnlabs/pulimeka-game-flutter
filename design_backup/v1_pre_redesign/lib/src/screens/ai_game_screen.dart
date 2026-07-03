import 'package:flutter/material.dart';

import '../controllers/ai_game_controller.dart';
import '../models/game_state.dart';
import '../widgets/offline_game_view.dart';
import 'ai_game_selection_screen.dart';

class AIGameScreen extends StatefulWidget {
  const AIGameScreen({super.key});

  static const routeName = '/ai';

  @override
  State<AIGameScreen> createState() => _AIGameScreenState();
}

class _AIGameScreenState extends State<AIGameScreen> {
  String? _role;
  String? _difficulty;

  @override
  Widget build(BuildContext context) {
    if (_role == null || _difficulty == null) {
      return AiGameSelectionScreen(
        onBack: () => Navigator.pop(context),
        onStartGame: (role, difficulty) {
          setState(() {
            _role = role;
            _difficulty = difficulty;
          });
        },
      );
    }

    final humanIsGoat = _role == 'goat';
    final tigerName = humanIsGoat ? 'AI (Tigers)' : 'You (Tigers)';
    final goatName = humanIsGoat ? 'You (Goats)' : 'AI (Goats)';

    return OfflineGameView(
      key: ValueKey('ai-$_role-$_difficulty'),
      tigerPlayerName: tigerName,
      goatPlayerName: goatName,
      modeLabel: 'Play with AI',
      controller: AiGameController(
        humanRole: humanIsGoat ? PieceType.goat : PieceType.tiger,
      ),
    );
  }
}
