class GameResult {
  final String id;
  final String mode;
  final String winner;
  final int capturedGoats;
  final int goatsPlaced;
  final DateTime playedAt;

  GameResult({
    required this.id,
    required this.mode,
    required this.winner,
    required this.capturedGoats,
    required this.goatsPlaced,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode,
      'winner': winner,
      'capturedGoats': capturedGoats,
      'goatsPlaced': goatsPlaced,
      'playedAt': playedAt.toIso8601String(),
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      id: json['id'] as String,
      mode: json['mode'] as String,
      winner: json['winner'] as String,
      capturedGoats: json['capturedGoats'] as int,
      goatsPlaced: json['goatsPlaced'] as int,
      playedAt: DateTime.parse(json['playedAt'] as String),
    );
  }
}
