import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../controllers/game_controller.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'board_geometry.dart';

/// Canvas board + piece overlays — warm wooden board look.
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
        final geometry = BoardGeometry.fromSize(size, board: ui.boardOrClassic);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final node = geometry.nearestNode(details.localPosition);
            if (node != null) onNodeTap(node);
          },
          child: Stack(
            clipBehavior: Clip.hardEdge,
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
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.02,
        size.height * 0.02,
        size.width * 0.96,
        size.height * 0.96,
      ),
      Radius.circular(size.shortestSide * 0.04),
    );

    // Soft outer shadow
    canvas.drawRRect(
      boardRect.shift(Offset(0, size.shortestSide * 0.008)),
      Paint()
        ..color = const Color(0x332F241B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Wood / parchment fill
    final fillRect = boardRect.outerRect;
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF8EE),
          Color(0xFFF3E4D0),
          Color(0xFFEAD7BC),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(fillRect);
    canvas.drawRRect(boardRect, fillPaint);

    // Inner rim
    canvas.drawRRect(
      boardRect.deflate(size.shortestSide * 0.012),
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.008,
    );
    canvas.drawRRect(
      boardRect.deflate(size.shortestSide * 0.004),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.006,
    );

    final board = ui.boardOrClassic;
    final stroke = math.max(1.5, size.shortestSide * 0.009);

    // Lines — warm brown with light undertone
    final underPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = stroke + 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final linePaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final drawn = <String>{};
    for (final from in board.allNodes) {
      for (final to in board.neighbors(from)) {
        final key = from.compareTo(to) < 0 ? '$from|$to' : '$to|$from';
        if (drawn.contains(key)) continue;
        drawn.add(key);
        final a = geometry.mapNode(from);
        final b = geometry.mapNode(to);
        canvas.drawLine(a, b, underPaint);
        canvas.drawLine(a, b, linePaint);
      }
    }

    // Intersection nodes — filled discs with rim
    final nodeR = math.max(3.5, size.shortestSide * 0.018);
    for (final node in board.allNodes) {
      final c = geometry.mapNode(node);
      canvas.drawCircle(c, nodeR + 1.2, Paint()..color = const Color(0x55FFFFFF));
      canvas.drawCircle(c, nodeR, Paint()..color = const Color(0xFF8D6E63));
      canvas.drawCircle(
        c,
        nodeR,
        Paint()
          ..color = const Color(0xFF4E342E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(c, nodeR * 0.35, Paint()..color = const Color(0xFFEFEBE9));
    }

    final highlightRadius = math.max(8.0, size.shortestSide * 0.028);
    final placementDots =
        ui.showPlacementDots && ui.isGoatPlacementTurn && ui.selectedNode == null;
    for (final target in validTargets) {
      final c = geometry.mapNode(target);
      if (placementDots) {
        canvas.drawCircle(c, highlightRadius * 0.55, Paint()..color = AppTheme.goatMuted);
      } else {
        canvas.drawCircle(
          c,
          highlightRadius,
          Paint()
            ..color = AppTheme.validMoveStroke.withOpacity(0.2),
        );
        canvas.drawCircle(
          c,
          highlightRadius,
          Paint()
            ..color = AppTheme.validMoveStroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.shortestSide * 0.007,
        );
      }
    }

    final hintRadius = math.max(10.0, size.shortestSide * 0.034);
    for (final node in ui.hintHighlightNodes) {
      canvas.drawCircle(
        geometry.mapNode(node),
        hintRadius,
        Paint()
          ..color = AppTheme.hintNodeStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.009,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.ui != ui || oldDelegate.geometry.board.id != geometry.board.id;
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
    final pieceSize = piece.type == PieceType.tiger ? baseSize * 0.92 : baseSize;
    final bgRadius = baseSize * 0.52;

    final isTiger = piece.type == PieceType.tiger;
    final bgColor = isTiger ? AppTheme.pieceTigerBg : AppTheme.pieceGoatBg;
    final borderColor = isTiger ? AppTheme.pieceTigerBorder : AppTheme.pieceGoatBorder;
    final ringColor = isTiger ? AppTheme.pieceTigerRing : AppTheme.pieceGoatRing;

    final asset = isTiger ? GameAssets.tigerIcon : GameAssets.goatIcon;

    return Stack(
      clipBehavior: Clip.hardEdge,
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
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
