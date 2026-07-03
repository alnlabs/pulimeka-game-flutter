import 'package:flutter/material.dart';

import '../models/game_state.dart';
import 'puli_meka_board.dart';
import 'ui_game_state_mapper.dart';

/// Adapter so existing screens can use the canvas board with [GameState].
class GameBoardWidget extends StatelessWidget {
  const GameBoardWidget({
    required this.gameState,
    required this.selectedNode,
    required this.validTargets,
    required this.onNodeTap,
    super.key,
  });

  final GameState gameState;
  final String? selectedNode;
  final Set<String> validTargets;
  final void Function(String node) onNodeTap;

  @override
  Widget build(BuildContext context) {
    final ui = uiStateFromGameState(
      gameState,
      selectedNode: selectedNode,
    ).copyWith(validTargets: validTargets);

    return PuliMekaBoard(ui: ui, onNodeTap: onNodeTap);
  }
}
