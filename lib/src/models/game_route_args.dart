class GameRouteArgs {
  const GameRouteArgs({
    this.mode = 'offline',
    this.tigerPlayerName = 'Tiger Player',
    this.goatPlayerName = 'Goat Player',
  });

  final String mode;
  final String tigerPlayerName;
  final String goatPlayerName;
}
