import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/board_layout.dart';

/// Board layout math ported from Android `GameScreen.kt` Canvas/overlay code.
class BoardGeometry {
  BoardGeometry._({
    required this.size,
    required this.scale,
    required this.originX,
    required this.originY,
    required this.padX,
    required this.padY,
    required this.unitX,
    required this.unitY,
  });

  final Size size;
  final double scale;
  final double originX;
  final double originY;
  final double padX;
  final double padY;
  final double unitX;
  final double unitY;

  factory BoardGeometry.fromSize(
    Size size, {
    double padding = 25,
    double unit = 100,
    double fitFactor = 0.95,
  }) {
    final contentW = 4 * unit;
    final contentH = 8 * unit;
    final totalW = contentW + 2 * padding;
    final totalH = contentH + 2 * padding;
    final s = math.min(size.width / totalW, size.height / totalH) * fitFactor;
    final scaledW = totalW * s;
    final scaledH = totalH * s;
    return BoardGeometry._(
      size: size,
      scale: s,
      originX: (size.width - scaledW) / 2,
      originY: (size.height - scaledH) / 2,
      padX: padding * s,
      padY: padding * s,
      unitX: unit * s,
      unitY: unit * s,
    );
  }

  Offset mapNode(String name) {
    final coord = BoardLayout.nodeCoord(name);
    if (coord == null) return Offset.zero;
    final c = coord.col.toDouble();
    final r = coord.row.toDouble();
    final nx = originX + padX + (r * unitX);
    final ny = originY + padY + ((8 - c) * unitY);
    return Offset(nx, ny);
  }

  String? nearestNode(Offset tap, {double thresholdFactor = 0.08}) {
    final minDim = math.min(size.width, size.height);
    final threshold = thresholdFactor * minDim;
    String? bestName;
    var bestDist = double.infinity;

    for (final node in BoardLayout.allNodes) {
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

  double get basePieceSizePx => 60 * scale;
}
