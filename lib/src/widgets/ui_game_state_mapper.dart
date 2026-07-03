import '../controllers/game_controller.dart';
import '../models/game_state.dart';

UiGameState uiStateFromGameState(
  GameState state, {
  String? selectedNode,
}) {
  final pieces = <BoardPiece>[];
  for (final entry in state.pieceState.entries) {
    final piece = entry.value;
    if (piece != null) {
      pieces.add(BoardPiece(type: piece, node: entry.key));
    }
  }

  final validTargets = selectedNode != null
      ? state.getValidTargets(selectedNode)
      : const <String>{};

  return UiGameState(
    pieces: pieces,
    currentTurn: state.currentTurn,
    validTargets: validTargets,
    selectedNode: selectedNode,
    winner: state.winner,
    capturedGoats: state.capturedGoats,
  );
}
