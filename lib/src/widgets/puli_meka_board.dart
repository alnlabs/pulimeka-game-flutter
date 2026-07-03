import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../controllers/game_controller.dart';
import '../models/game_state.dart';
import '../models/board_layout.dart';
import '../theme/app_theme.dart';
import 'board_geometry.dart';

/// Canvas board + piece overlays matching native Android `GameScreen`.
class PuliMekaBoard extends StatelessWidget {
  const PuliMekaBoard({
    required this.ui,
    required this.onNodeTap,
    super.key,
  });

  final UiGameState ui;
  final ValueChanged<String> onNodeTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = BoardGeometry.fromSize(size);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final node = geometry.nearestNode(details.localPosition);
            if (node != null) onNodeTap(node);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: size,
                painter: _BoardPainter(
                  geometry: geometry,
                  ui: ui,
                ),
              ),
              ...ui.pieces.map((piece) => _PieceOverlay(
                    piece: piece,
                    geometry: geometry,
                    selected: ui.selectedNode == piece.node,
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.geometry,
    required this.ui,
  });

  final BoardGeometry geometry;
  final UiGameState ui;

  Set<String> get validTargets => ui.validTargets;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppTheme.boardFill,
    );

    final border = size.shortestSide * 0.01;
    final borderPaint = Paint()
      ..color = AppTheme.boardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = border;
    canvas.drawRect(
      Rect.fromLTWH(border, border, size.width - 2 * border, size.height - 2 * border),
      borderPaint,
    );

    final linePaint = Paint()
      ..color = AppTheme.boardLine
      ..strokeWidth = size.shortestSide * 0.01
      ..strokeCap = StrokeCap.round;

    final drawn = <String>{};
    for (final from in BoardLayout.allNodes) {
      for (final to in BoardLayout.neighbors(from)) {
        final key = from.compareTo(to) < 0 ? '$from|$to' : '$to|$from';
        if (drawn.contains(key)) continue;
        drawn.add(key);
        canvas.drawLine(geometry.mapNode(from), geometry.mapNode(to), linePaint);
      }
    }

    final nodeRadius = size.shortestSide * 0.015;
    final nodePaint = Paint()..color = AppTheme.boardNode;
    for (final node in BoardLayout.allNodes) {
      canvas.drawCircle(geometry.mapNode(node), nodeRadius, nodePaint);
    }

    final highlightRadius = size.shortestSide * 0.026;
    final placementDots =
        ui.showPlacementDots && ui.isGoatPlacementTurn && ui.selectedNode == null;
    for (final target in validTargets) {
      if (placementDots) {
        canvas.drawCircle(
          geometry.mapNode(target),
          highlightRadius * 0.5,
          Paint()..color = AppTheme.goatMuted,
        );
      } else {
        canvas.drawCircle(
          geometry.mapNode(target),
          highlightRadius,
          Paint()
            ..color = AppTheme.validMoveStroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.shortestSide * 0.006,
        );
      }
    }

    final hintRadius = size.shortestSide * 0.032;
    for (final node in ui.hintHighlightNodes) {
      canvas.drawCircle(
        geometry.mapNode(node),
        hintRadius,
        Paint()
          ..color = AppTheme.hintNodeStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.008,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.ui != ui;
  }
}

class _PieceOverlay extends StatelessWidget {
  const _PieceOverlay({
    required this.piece,
    required this.geometry,
    required this.selected,
  });

  final BoardPiece piece;
  final BoardGeometry geometry;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final center = geometry.mapNode(piece.node);
    final baseSize = geometry.basePieceSizePx;
    final pieceSize = piece.type == PieceType.tiger ? baseSize * 0.9 : baseSize;
    final bgRadius = baseSize * 0.5;

    final isTiger = piece.type == PieceType.tiger;
    final bgColor = isTiger ? AppTheme.pieceTigerBg : AppTheme.pieceGoatBg;
    final borderColor = isTiger ? AppTheme.pieceTigerBorder : AppTheme.pieceGoatBorder;
    final ringColor = isTiger ? AppTheme.pieceTigerRing : AppTheme.pieceGoatRing;

    final asset = isTiger
        ? GameAssets.tigerIcon
        : GameAssets.goatIcon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: center.dx - bgRadius,
          top: center.dy - bgRadius,
          width: bgRadius * 2,
          height: bgRadius * 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
          ),
        ),
        Positioned(
          left: center.dx - pieceSize / 2,
          top: center.dy - pieceSize / 2,
          width: pieceSize,
          height: pieceSize,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
        if (selected)
          Positioned(
            left: center.dx - pieceSize / 2,
            top: center.dy - pieceSize / 2,
            width: pieceSize,
            height: pieceSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 3),
              ),
            ),
          ),
      ],
    );
  }
}
