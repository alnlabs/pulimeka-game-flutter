import 'board_spec.dart';

export 'board_spec.dart' show NodeCoord;

class BoardLayout {
  static const int rows = 5;
  static const int cols = 9;

  static const List<String> tigerStartNodes = ['r2-c2', 'r2-c6'];
  static const List<String> initialGoatNodes = ['r1-c4', 'r3-c4', 'r2-c3', 'r2-c5'];

  static final List<String> allNodes = _generateAllNodes();
  static final Map<String, NodeCoord> coords = _generateCoords();
  static final Map<String, List<String>> connections = _generateConnections();

  /// Classic board as a [BoardSpec] for campaign / parameterized play.
  static BoardSpec asSpec() {
    return BoardSpec(
      id: 'classic',
      allNodes: List.unmodifiable(allNodes),
      coords: Map.unmodifiable(coords),
      connections: Map.unmodifiable(connections),
      maxRow: rows - 1,
      maxCol: cols - 1,
    );
  }

  static bool exists(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) {
      return false;
    }
    return !((row == 0 || row == 4) && (col == 1 || col == 7));
  }

  static String nodeName(int row, int col) => 'r$row-c$col';

  static List<List<String?>> matrix() {
    return List.generate(rows, (row) {
      return List.generate(cols, (col) {
        return exists(row, col) ? nodeName(row, col) : null;
      });
    });
  }

  static List<String> neighbors(String node) {
    return connections[node] ?? const [];
  }

  static NodeCoord? nodeCoord(String node) => coords[node];

  static List<String> _generateAllNodes() {
    final nodes = <String>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (exists(r, c)) {
          nodes.add(nodeName(r, c));
        }
      }
    }
    return nodes;
  }

  static Map<String, NodeCoord> _generateCoords() {
    final map = <String, NodeCoord>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (exists(r, c)) {
          map[nodeName(r, c)] = NodeCoord(row: r, col: c);
        }
      }
    }
    return map;
  }

  static Map<String, List<String>> _generateConnections() {
    final defined = allNodes.toSet();
    final adj = <String, Set<String>>{};

    void addEdge(String a, String b) {
      if (defined.contains(a) && defined.contains(b)) {
        adj.putIfAbsent(a, () => <String>{}).add(b);
        adj.putIfAbsent(b, () => <String>{}).add(a);
      }
    }

    String n(int row, int col) => nodeName(row, col);

    for (var r = 0; r < rows - 1; r++) {
      for (var c = 2; c < 6; c++) {
        final n0 = n(r, c);
        final n1 = n(r, c + 1);
        final n2 = n(r + 1, c);
        final n3 = n(r + 1, c + 1);
        addEdge(n0, n1);
        addEdge(n0, n2);
        addEdge(n1, n3);
        addEdge(n2, n3);
      }
    }

    addEdge(n(0, 2), n(1, 3));
    addEdge(n(1, 3), n(2, 4));
    addEdge(n(2, 4), n(3, 5));
    addEdge(n(3, 5), n(4, 6));
    addEdge(n(4, 2), n(3, 3));
    addEdge(n(3, 3), n(2, 4));
    addEdge(n(2, 4), n(1, 5));
    addEdge(n(1, 5), n(0, 6));
    addEdge(n(2, 2), n(1, 3));
    addEdge(n(1, 3), n(0, 4));
    addEdge(n(0, 4), n(1, 5));
    addEdge(n(1, 5), n(2, 6));
    addEdge(n(2, 6), n(3, 5));
    addEdge(n(3, 5), n(4, 4));
    addEdge(n(4, 4), n(3, 3));
    addEdge(n(3, 3), n(2, 2));

    final leftHub = n(2, 2);
    for (var r = 0; r < rows - 1; r++) {
      addEdge(n(r, 0), n(r + 1, 0));
    }
    addEdge(n(1, 1), n(2, 1));
    addEdge(n(2, 1), n(3, 1));
    addEdge(n(1, 0), n(1, 1));
    addEdge(n(2, 0), n(2, 1));
    addEdge(n(3, 0), n(3, 1));
    addEdge(n(1, 1), n(0, 0));
    addEdge(n(3, 1), n(4, 0));
    addEdge(n(1, 1), leftHub);
    addEdge(n(2, 1), leftHub);
    addEdge(n(3, 1), leftHub);

    final rightHub = n(2, 6);
    for (var r = 0; r < rows - 1; r++) {
      addEdge(n(r, 8), n(r + 1, 8));
    }
    addEdge(n(1, 7), n(2, 7));
    addEdge(n(2, 7), n(3, 7));
    addEdge(n(1, 7), n(1, 8));
    addEdge(n(2, 7), n(2, 8));
    addEdge(n(3, 7), n(3, 8));
    addEdge(n(1, 7), n(0, 8));
    addEdge(n(3, 7), n(4, 8));
    addEdge(n(1, 7), rightHub);
    addEdge(n(2, 7), rightHub);
    addEdge(n(3, 7), rightHub);

    return adj.map((key, value) => MapEntry(key, value.toList()..sort()));
  }
}
