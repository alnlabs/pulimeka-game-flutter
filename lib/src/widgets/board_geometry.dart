import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/board_spec.dart';

/// Board layout math — scales to any [BoardSpec] and sizes pieces from spacing.
class BoardGeometry {
  BoardGeometry._({
    required this.board,
    required this.size,
    required this.scale,
    required this.originX,
    required this.originY,
    required this.padX,
    required this.padY,
    required this.unitX,
    required this.unitY,
    required this.avgSpacing,
  });

  final BoardSpec board;
  final Size size;
  final double scale;
  final double originX;
  final double originY;
  final double padX;
  final double padY;
  final double unitX;
  final double unitY;
  final double avgSpacing;

  factory BoardGeometry.fromSize(
    Size size, {
    required BoardSpec board,
    double? padding,
    double unit = 100,
    double fitFactor = 0.94,
  }) {
    // Leave room for piece radius at the rim so goats/tigers stay on-board.
    final pad = padding ?? math.max(32.0, size.shortestSide * 0.08);
    final contentW = math.max(board.maxRow, 1) * unit;
    final contentH = math.max(board.maxCol, 1) * unit;
    final totalW = contentW + 2 * pad;
    final totalH = contentH + 2 * pad;
    final s = math.min(size.width / totalW, size.height / totalH) * fitFactor;
    final scaledW = totalW * s;
    final scaledH = totalH * s;
    final geometry = BoardGeometry._(
      board: board,
      size: size,
      scale: s,
      originX: (size.width - scaledW) / 2,
      originY: (size.height - scaledH) / 2,
      padX: pad * s,
      padY: pad * s,
      unitX: unit * s,
      unitY: unit * s,
      avgSpacing: 0,
    );
    return BoardGeometry._(
      board: board,
      size: size,
      scale: s,
      originX: geometry.originX,
      originY: geometry.originY,
      padX: geometry.padX,
      padY: geometry.padY,
      unitX: geometry.unitX,
      unitY: geometry.unitY,
      avgSpacing: geometry._computeAvgSpacing(),
    );
  }

  double _computeAvgSpacing() {
    if (board.allNodes.length < 2) return unitX;
    var sum = 0.0;
    var count = 0;
    final drawn = <String>{};
    for (final from in board.allNodes) {
      for (final to in board.neighbors(from)) {
        final key = from.compareTo(to) < 0 ? '$from|$to' : '$to|$from';
        if (drawn.contains(key)) continue;
        drawn.add(key);
        sum += (mapNode(from) - mapNode(to)).distance;
        count++;
      }
    }
    return count == 0 ? unitX : sum / count;
  }

  Offset mapNode(String name) {
    final coord = board.nodeCoord(name);
    if (coord == null) return Offset.zero;
    final c = coord.col.toDouble();
    final r = coord.row.toDouble();
    final nx = originX + padX + (r * unitX);
    final ny = originY + padY + ((board.maxCol - c) * unitY);
    return Offset(nx, ny);
  }

  String? nearestNode(Offset tap, {double thresholdFactor = 0.1}) {
    final minDim = math.min(size.width, size.height);
    final threshold = math.max(avgSpacing * 0.45, thresholdFactor * minDim);
    String? bestName;
    var bestDist = double.infinity;

    for (final node in board.allNodes) {
      final pos = mapNode(node);
      final d = (tap - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestName = node;
      }
    }
    if (bestName != null && bestDist <= threshold) {
      return bestName;
    }
    return null;
  }

  /// Piece size tracks node spacing, but never larger than the rim padding.
  double get basePieceSizePx {
    final maxByPad = math.min(padX, padY) * 1.55;
    final fromSpacing = avgSpacing * 0.5;
    final fromScale = 48 * scale;
    return math.max(
      20,
      math.min(maxByPad, math.min(fromSpacing, fromScale * 1.2)),
    );
  }
}
