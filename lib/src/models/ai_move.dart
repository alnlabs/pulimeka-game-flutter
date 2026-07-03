/// Tiger/goat move or goat placement for minimax.
class AiMove {
  const AiMove._({
    this.from,
    this.target,
    this.jumped,
    this.placement,
  });

  const AiMove({
    required String from,
    required String target,
    String? jumped,
  }) : this._(from: from, target: target, jumped: jumped);

  const AiMove.placement(String node) : this._(placement: node);

  final String? from;
  final String? target;
  final String? jumped;
  final String? placement;

  bool get isPlacement => placement != null;
  bool get isJump => jumped != null;
}
