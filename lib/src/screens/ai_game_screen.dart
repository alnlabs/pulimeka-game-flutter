import 'package:flutter/material.dart';

import '../controllers/ai_game_controller.dart';
import '../models/ai_difficulty.dart';
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
  String? _humanName;

  @override
  Widget build(BuildContext context) {
    if (_role == null || _difficulty == null || _humanName == null) {
      return AiGameSelectionScreen(
        onBack: () => Navigator.pop(context),
        onStartGame: (role, difficulty, humanName) {
          setState(() {
            _role = role;
            _difficulty = difficulty;
            _humanName = humanName;
          });
        },
      );
    }

    final humanIsGoat = _role == 'goat';
    final humanRole = humanIsGoat ? PieceType.goat : PieceType.tiger;
    final difficulty = AiDifficulty.parse(_difficulty);
    final tigerName =
        humanIsGoat ? 'AI (Tigers)' : '$_humanName (Tigers)';
    final goatName =
        humanIsGoat ? '$_humanName (Goats)' : 'AI (Goats)';

    return OfflineGameView(
      key: ValueKey('ai-$_role-$_difficulty-$_humanName'),
      tigerPlayerName: tigerName,
      goatPlayerName: goatName,
      modeLabel: 'AI · ${difficulty.label}',
      aiHumanRole: humanRole,
      aiHumanName: _humanName,
      controller: AiGameController(
        humanRole: humanRole,
        difficulty: difficulty,
      ),
    );
  }
}
