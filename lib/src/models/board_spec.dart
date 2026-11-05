/// Grid coordinate for a named board node (`r{row}-c{col}`).
class NodeCoord {
  final int row;
  final int col;

  const NodeCoord({required this.row, required this.col});
}

/// Playable board graph for classic or level templates.
class BoardSpec {
  const BoardSpec({
    required this.id,
    required this.allNodes,
    required this.coords,
    required this.connections,
    required this.maxRow,
    required this.maxCol,
  });

  final String id;
  final List<String> allNodes;
  final Map<String, NodeCoord> coords;
  final Map<String, List<String>> connections;
  final int maxRow;
  final int maxCol;

  List<String> neighbors(String node) => connections[node] ?? const [];

  NodeCoord? nodeCoord(String node) => coords[node];

  bool hasNode(String node) => coords.containsKey(node);

  /// Build from explicit node list + undirected edges.
  factory BoardSpec.fromGraph({
    required String id,
    required Map<String, NodeCoord> coords,
    required List<(String, String)> edges,
  }) {
    final nodes = coords.keys.toList()..sort();
    final defined = nodes.toSet();
    final adj = <String, Set<String>>{};

    void addEdge(String a, String b) {
      if (!defined.contains(a) || !defined.contains(b)) return;
      adj.putIfAbsent(a, () => <String>{}).add(b);
      adj.putIfAbsent(b, () => <String>{}).add(a);
    }

    for (final e in edges) {
      addEdge(e.$1, e.$2);
    }

    var maxR = 0;
    var maxC = 0;
    for (final c in coords.values) {
      if (c.row > maxR) maxR = c.row;
      if (c.col > maxC) maxC = c.col;
    }

    return BoardSpec(
      id: id,
      allNodes: List.unmodifiable(nodes),
      coords: Map.unmodifiable(coords),
      connections: Map.unmodifiable(
        adj.map((k, v) => MapEntry(k, v.toList()..sort())),
      ),
      maxRow: maxR,
      maxCol: maxC,
    );
  }

  static String _n(int r, int c) => 'r$r-c$c';

  /// Teaching board — diamond with center (like a mini Tiger-Goat board).
  ///
  /// ```
  ///       ·
  ///     · · ·
  ///   · · · · ·
  ///     · · ·
  ///       ·
  /// ```
  static final BoardSpec seed = () {
    final coords = <String, NodeCoord>{
      _n(0, 2): const NodeCoord(row: 0, col: 2),
      _n(1, 1): const NodeCoord(row: 1, col: 1),
      _n(1, 2): const NodeCoord(row: 1, col: 2),
      _n(1, 3): const NodeCoord(row: 1, col: 3),
      _n(2, 0): const NodeCoord(row: 2, col: 0),
      _n(2, 1): const NodeCoord(row: 2, col: 1),
      _n(2, 2): const NodeCoord(row: 2, col: 2),
      _n(2, 3): const NodeCoord(row: 2, col: 3),
      _n(2, 4): const NodeCoord(row: 2, col: 4),
      _n(3, 1): const NodeCoord(row: 3, col: 1),
      _n(3, 2): const NodeCoord(row: 3, col: 2),
      _n(3, 3): const NodeCoord(row: 3, col: 3),
      _n(4, 2): const NodeCoord(row: 4, col: 2),
    };
    final edges = <(String, String)>[
      // Vertical spine
      (_n(0, 2), _n(1, 2)),
      (_n(1, 2), _n(2, 2)),
      (_n(2, 2), _n(3, 2)),
      (_n(3, 2), _n(4, 2)),
      // Horizontal mid
      (_n(2, 0), _n(2, 1)),
      (_n(2, 1), _n(2, 2)),
      (_n(2, 2), _n(2, 3)),
      (_n(2, 3), _n(2, 4)),
      // Upper diamond
      (_n(0, 2), _n(1, 1)),
      (_n(0, 2), _n(1, 3)),
      (_n(1, 1), _n(1, 2)),
      (_n(1, 2), _n(1, 3)),
      (_n(1, 1), _n(2, 0)),
      (_n(1, 1), _n(2, 1)),
      (_n(1, 1), _n(2, 2)),
      (_n(1, 3), _n(2, 2)),
      (_n(1, 3), _n(2, 3)),
      (_n(1, 3), _n(2, 4)),
      // Lower diamond
      (_n(4, 2), _n(3, 1)),
      (_n(4, 2), _n(3, 3)),
      (_n(3, 1), _n(3, 2)),
      (_n(3, 2), _n(3, 3)),
      (_n(3, 1), _n(2, 0)),
      (_n(3, 1), _n(2, 1)),
      (_n(3, 1), _n(2, 2)),
      (_n(3, 3), _n(2, 2)),
      (_n(3, 3), _n(2, 3)),
      (_n(3, 3), _n(2, 4)),
    ];
    return BoardSpec.fromGraph(id: 'seed', coords: coords, edges: edges);
  }();

  /// Mid board — wider diamond with side hubs (feels closer to classic).
  static final BoardSpec grove = () {
    final coords = <String, NodeCoord>{};
    void put(int r, int c) => coords[_n(r, c)] = NodeCoord(row: r, col: c);

    // Central 3×5 diamond band
    for (final c in [2, 3, 4]) {
      put(0, c);
    }
    for (final c in [1, 2, 3, 4, 5]) {
      put(1, c);
    }
    for (final c in [0, 1, 2, 3, 4, 5, 6]) {
      put(2, c);
    }
    for (final c in [1, 2, 3, 4, 5]) {
      put(3, c);
    }
    for (final c in [2, 3, 4]) {
      put(4, c);
    }

    final edges = <(String, String)>[];
    void link(int r1, int c1, int r2, int c2) =>
        edges.add((_n(r1, c1), _n(r2, c2)));

    // Rows
    for (final r in [0, 1, 2, 3, 4]) {
      final cols = coords.entries
          .where((e) => e.value.row == r)
          .map((e) => e.value.col)
          .toList()
        ..sort();
      for (var i = 0; i < cols.length - 1; i++) {
        link(r, cols[i], r, cols[i + 1]);
      }
    }
    // Columns through center
    for (final c in [2, 3, 4]) {
      link(0, c, 1, c);
      link(1, c, 2, c);
      link(2, c, 3, c);
      link(3, c, 4, c);
    }
    link(1, 1, 2, 1);
    link(2, 1, 3, 1);
    link(1, 5, 2, 5);
    link(2, 5, 3, 5);
    link(2, 0, 1, 1);
    link(2, 0, 3, 1);
    link(2, 6, 1, 5);
    link(2, 6, 3, 5);

    // Diagonals toward center (jump-friendly)
    link(0, 2, 1, 1);
    link(0, 2, 1, 3);
    link(0, 4, 1, 3);
    link(0, 4, 1, 5);
    link(1, 1, 2, 2);
    link(1, 5, 2, 4);
    link(1, 2, 2, 1);
    link(1, 2, 2, 3);
    link(1, 4, 2, 3);
    link(1, 4, 2, 5);
    link(4, 2, 3, 1);
    link(4, 2, 3, 3);
    link(4, 4, 3, 3);
    link(4, 4, 3, 5);
    link(3, 1, 2, 2);
    link(3, 5, 2, 4);
    link(3, 2, 2, 1);
    link(3, 2, 2, 3);
    link(3, 4, 2, 3);
    link(3, 4, 2, 5);
    link(1, 3, 2, 2);
    link(1, 3, 2, 4);
    link(3, 3, 2, 2);
    link(3, 3, 2, 4);

    return BoardSpec.fromGraph(id: 'grove', coords: coords, edges: edges);
  }();

  /// Large board — classic-inspired with left/right hubs, before full 41-node.
  static final BoardSpec arena = () {
    final coords = <String, NodeCoord>{};
    void put(int r, int c) => coords[_n(r, c)] = NodeCoord(row: r, col: c);

    // Main field 5×7 (rows 0–4, cols 1–7) plus outer hubs at col 0 and 8
    for (var r = 0; r < 5; r++) {
      for (var c = 1; c <= 7; c++) {
        if ((r == 0 || r == 4) && (c == 1 || c == 7)) continue;
        put(r, c);
      }
    }
    for (final r in [1, 2, 3]) {
      put(r, 0);
      put(r, 8);
    }

    final edges = <(String, String)>[];
    void link(int r1, int c1, int r2, int c2) {
      final a = _n(r1, c1);
      final b = _n(r2, c2);
      if (coords.containsKey(a) && coords.containsKey(b)) {
        edges.add((a, b));
      }
    }

    // Inner grid horizontals / verticals (cols 2–6)
    for (var r = 0; r < 5; r++) {
      for (var c = 2; c < 6; c++) {
        link(r, c, r, c + 1);
      }
    }
    for (var c = 2; c <= 6; c++) {
      for (var r = 0; r < 4; r++) {
        link(r, c, r + 1, c);
      }
    }
    // Box diagonals
    for (var r = 0; r < 4; r++) {
      for (var c = 2; c < 6; c++) {
        link(r, c, r + 1, c + 1);
        link(r, c + 1, r + 1, c);
      }
    }
    // Long diagonals through center (classic feel)
    link(0, 2, 1, 3);
    link(1, 3, 2, 4);
    link(2, 4, 3, 5);
    link(3, 5, 4, 6);
    link(4, 2, 3, 3);
    link(3, 3, 2, 4);
    link(2, 4, 1, 5);
    link(1, 5, 0, 6);
    link(2, 2, 1, 3);
    link(1, 3, 0, 4);
    link(0, 4, 1, 5);
    link(1, 5, 2, 6);
    link(2, 6, 3, 5);
    link(3, 5, 4, 4);
    link(4, 4, 3, 3);
    link(3, 3, 2, 2);

    // Left hub
    link(1, 0, 2, 0);
    link(2, 0, 3, 0);
    link(1, 0, 1, 2);
    link(2, 0, 2, 2);
    link(3, 0, 3, 2);
    link(1, 0, 0, 2);
    link(3, 0, 4, 2);
    link(1, 0, 2, 2);
    link(3, 0, 2, 2);

    // Right hub
    link(1, 8, 2, 8);
    link(2, 8, 3, 8);
    link(1, 8, 1, 6);
    link(2, 8, 2, 6);
    link(3, 8, 3, 6);
    link(1, 8, 0, 6);
    link(3, 8, 4, 6);
    link(1, 8, 2, 6);
    link(3, 8, 2, 6);

    return BoardSpec.fromGraph(id: 'arena', coords: coords, edges: edges);
  }();

  static BoardSpec byId(String id) {
    switch (id) {
      case 'seed':
        return seed;
      case 'grove':
        return grove;
      case 'arena':
        return arena;
      default:
        throw ArgumentError(
          'Unknown board id "$id" — use BoardLayout.asSpec for classic',
        );
    }
  }
}
