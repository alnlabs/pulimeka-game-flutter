class OnlinePlayArgs {
  const OnlinePlayArgs({
    required this.roomId,
    required this.playerId,
    required this.isHost,
    required this.playerRole,
    required this.playerName,
    this.opponentName,
    this.waitingForGuest = false,
  });

  final String roomId;
  final String playerId;
  final bool isHost;
  final String playerRole;
  final String playerName;
  final String? opponentName;
  final bool waitingForGuest;
}
