class LeaderboardEntry {
  LeaderboardEntry({
    required this.playerName,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    required this.lastPlayed,
  });

  final String playerName;
  final int wins;
  final int losses;
  final int draws;
  final DateTime lastPlayed;

  String get canonicalKey => playerName.trim().toLowerCase();

  int get totalGames => wins + losses + draws;

  LeaderboardEntry copyWith({
    String? playerName,
    int? wins,
    int? losses,
    int? draws,
    DateTime? lastPlayed,
  }) {
    return LeaderboardEntry(
      playerName: playerName ?? this.playerName,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'lastPlayed': lastPlayed.toIso8601String(),
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerName: json['playerName'] as String? ?? 'Player',
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      lastPlayed: DateTime.tryParse(json['lastPlayed'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
