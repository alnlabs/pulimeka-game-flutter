import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/campaign_level.dart';
import '../services/campaign_progress_service.dart';
import '../theme/app_theme.dart';
import '../utils/layout_insets.dart';
import '../widgets/ad_banner.dart';
import 'campaign_game_screen.dart';

class CampaignMapScreen extends StatefulWidget {
  const CampaignMapScreen({super.key});

  static const routeName = '/campaign';

  @override
  State<CampaignMapScreen> createState() => _CampaignMapScreenState();
}

class _CampaignMapScreenState extends State<CampaignMapScreen> {
  int _unlocked = 1;
  Map<int, int> _stars = {};
  bool _loading = true;

  static const _nodeSpacing = 168.0;
  static const _topPad = 36.0;
  static const _bottomPad = 56.0;
  static const _regionExtra = 56.0;
  static const _sideMargin = 28.0;
  static const _labelWidth = 118.0;
  static const _nodeSize = 72.0;

  static const _regions = <({int fromId, String label})>[
    (fromId: 1, label: 'Seed Clearing'),
    (fromId: 8, label: 'Deep Grove'),
    (fromId: 14, label: 'Arena Woods'),
    (fromId: 18, label: 'Classic Grounds'),
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final unlocked = await CampaignProgressService.instance.highestUnlocked();
    final stars = await CampaignProgressService.instance.allStars();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked;
      _stars = stars;
      _loading = false;
    });
  }

  Future<void> _openLevel(CampaignLevel level) async {
    if (level.id > _unlocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clear level $_unlocked first to unlock this stage.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.pushNamed(
      context,
      CampaignGameScreen.routeName,
      arguments: level.id,
    );
    await _reload();
  }

  bool _isRegionStart(int levelId) =>
      _regions.any((r) => r.fromId == levelId);

  String? _regionLabel(int levelId) {
    for (final r in _regions) {
      if (r.fromId == levelId) return r.label;
    }
    return null;
  }

  /// Y positions with room for region banners — nothing hangs above y=0.
  List<double> _nodeYs() {
    final levels = CampaignLevels.all;
    final ys = <double>[];
    var y = _topPad + 44; // room for first region banner
    for (var i = 0; i < levels.length; i++) {
      if (i > 0 && _isRegionStart(levels[i].id)) {
        y += _regionExtra;
      }
      ys.add(y);
      y += _nodeSpacing;
    }
    return ys;
  }

  List<Offset> _pathPoints(double width, List<double> ys) {
    final cx = width / 2;
    final sideLabels = width >= 370;
    // Reserve space for side title cards when the screen is wide enough.
    final edge = sideLabels
        ? (_sideMargin + _labelWidth + _nodeSize / 2)
        : (_nodeSize / 2 + 40);
    var minX = edge;
    var maxX = width - edge;
    if (maxX - minX < 48) {
      minX = cx - 24;
      maxX = cx + 24;
    }
    const factors = <double>[
      -0.55, 0.50, -0.70, 0.35, -0.45, 0.65, -0.25, 0.55, -0.68, 0.20,
      -0.40, 0.60, -0.72, 0.38, -0.18, 0.70, -0.50, 0.48, -0.62, 0.32,
    ];
    return List.generate(ys.length, (i) {
      final f = i < factors.length ? factors[i] : (i.isEven ? -0.5 : 0.5);
      final half = (maxX - minX) / 2;
      final x = (cx + f * half * 0.8).clamp(minX, maxX);
      return Offset(x, ys[i]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final levels = CampaignLevels.all;

    return Scaffold(
      backgroundColor: const Color(0xFFE4EDDF),
      appBar: AppBar(
        title: Text(
          'Career',
          style: AppTheme.text(
            size: 18,
            weight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '★ ${_stars.values.fold<int>(0, (a, b) => a + b)}/${CampaignLevels.count * 3}',
                  style: AppTheme.text(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ),
        ],
        backgroundColor: const Color(0xFFE8F0E4),
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Wander the forest path · clear stages · earn stars',
                textAlign: TextAlign.center,
                style: AppTheme.text(
                  size: 13,
                  color: AppTheme.goatAccent,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final ys = _nodeYs();
                        final points = _pathPoints(width, ys);
                        final mapHeight =
                            ys.last + _nodeSize / 2 + _bottomPad + 56;
                        final sideLabels = width >= 370;

                        return SingleChildScrollView(
                          child: SizedBox(
                            width: width,
                            height: mapHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _ForestBackdropPainter(),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter:
                                          _ForestPathPainter(points: points),
                                    ),
                                  ),
                                  // Region banners — full width, never cropped
                                  ...levels.asMap().entries.expand((e) {
                                    final label = _regionLabel(e.value.id);
                                    if (label == null) {
                                      return const <Widget>[];
                                    }
                                    final p = points[e.key];
                                    return [
                                      Positioned(
                                        left: 16,
                                        right: 16,
                                        top: p.dy - 78,
                                        child: _RegionBanner(label: label),
                                      ),
                                    ];
                                  }),
                                  ...List.generate(levels.length, (i) {
                                    final level = levels[i];
                                    final locked = level.id > _unlocked;
                                    final stars = _stars[level.id] ?? 0;
                                    final p = points[i];
                                    final labelOnRight = p.dx < width / 2;
                                    return Positioned(
                                      left: 0,
                                      right: 0,
                                      top: p.dy - _nodeSize / 2,
                                      height: sideLabels
                                          ? _nodeSize + 8
                                          : _nodeSize + 52,
                                      child: _ForestLevelRow(
                                        level: level,
                                        locked: locked,
                                        stars: stars,
                                        nodeCenterX: p.dx,
                                        labelOnRight: labelOnRight,
                                        sideLabels: sideLabels,
                                        mapWidth: width,
                                        nodeSize: _nodeSize,
                                        labelWidth: _labelWidth,
                                        onTap: () => _openLevel(level),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                        );
                      },
                    ),
            ),
            const AdBanner(),
            SizedBox(
              height: AppTheme.spacingMedium + bottomChromePadding(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionBanner extends StatelessWidget {
  const _RegionBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7EEDC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF8D6E63), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.14),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.park_rounded, size: 16, color: AppTheme.goatAccent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTheme.text(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForestLevelRow extends StatelessWidget {
  const _ForestLevelRow({
    required this.level,
    required this.locked,
    required this.stars,
    required this.nodeCenterX,
    required this.labelOnRight,
    required this.sideLabels,
    required this.mapWidth,
    required this.nodeSize,
    required this.labelWidth,
    required this.onTap,
  });

  final CampaignLevel level;
  final bool locked;
  final int stars;
  final double nodeCenterX;
  final bool labelOnRight;
  final bool sideLabels;
  final double mapWidth;
  final double nodeSize;
  final double labelWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nodeLeft = nodeCenterX - nodeSize / 2;
    final card = _LevelLabelCard(
      title: level.title,
      locked: locked,
      stars: stars,
      width: sideLabels ? labelWidth : math.min(160.0, mapWidth * 0.42),
    );

    if (!sideLabels) {
      final cardW = math.min(160.0, mapWidth * 0.42);
      final cardLeft =
          (nodeCenterX - cardW / 2).clamp(8.0, mapWidth - cardW - 8);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: nodeLeft.clamp(8.0, mapWidth - nodeSize - 8),
            top: 0,
            child: _ForestLevelNode(
              levelId: level.id,
              locked: locked,
              size: nodeSize,
              onTap: onTap,
            ),
          ),
          Positioned(
            left: cardLeft,
            top: nodeSize + 2,
            child: _LevelLabelCard(
              title: level.title,
              locked: locked,
              stars: stars,
              width: cardW,
            ),
          ),
        ],
      );
    }

    final leftLabelX =
        (nodeLeft - 8 - labelWidth).clamp(8.0, mapWidth - labelWidth - 8);
    final rightLabelX =
        (nodeLeft + nodeSize + 8).clamp(8.0, mapWidth - labelWidth - 8);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: nodeLeft.clamp(8.0, mapWidth - nodeSize - 8),
          top: 0,
          child: _ForestLevelNode(
            levelId: level.id,
            locked: locked,
            size: nodeSize,
            onTap: onTap,
          ),
        ),
        Positioned(
          left: labelOnRight ? rightLabelX : leftLabelX,
          top: 8,
          child: card,
        ),
      ],
    );
  }
}

class _LevelLabelCard extends StatelessWidget {
  const _LevelLabelCard({
    required this.title,
    required this.locked,
    required this.stars,
    required this.width,
  });

  final String title;
  final bool locked;
  final int stars;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
      decoration: BoxDecoration(
        color: locked
            ? const Color(0xFFE8E0D4)
            : AppTheme.background.withOpacity(0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: locked
              ? AppTheme.textTertiary.withOpacity(0.35)
              : AppTheme.goatAccent.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.text(
              size: 12,
              weight: FontWeight.w600,
              color: locked ? AppTheme.textTertiary : AppTheme.textPrimary,
            ),
          ),
          if (!locked) ...[
            const SizedBox(height: 3),
            Row(
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: Icon(
                    i < stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _ForestLevelNode extends StatelessWidget {
  const _ForestLevelNode({
    required this.levelId,
    required this.locked,
    required this.size,
    required this.onTap,
  });

  final int levelId;
  final bool locked;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _StumpNodePainter(locked: locked),
            child: Center(
              child: locked
                  ? Icon(
                      Icons.lock_rounded,
                      color: AppTheme.textOnDark.withOpacity(0.9),
                      size: 22,
                    )
                  : Text(
                      '$levelId',
                      style: AppTheme.text(
                        size: 22,
                        weight: FontWeight.w800,
                        color: AppTheme.textOnDark,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StumpNodePainter extends CustomPainter {
  _StumpNodePainter({required this.locked});

  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.40;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + 16),
        width: r * 2.0,
        height: r * 0.5,
      ),
      Paint()..color = AppTheme.goatAccent.withOpacity(0.25),
    );

    canvas.drawCircle(
      c,
      r + 3.5,
      Paint()
        ..color =
            locked ? const Color(0xFF8D6E63) : const Color(0xFF5D4037),
    );

    if (locked) {
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFA1887F));
      canvas.drawCircle(
        c,
        r * 0.78,
        Paint()..color = const Color(0xFFBCAAA4),
      );
    } else {
      final fill = Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-5, -7),
          r * 1.15,
          const [
            AppTheme.primaryLighter,
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
          const [0.0, 0.55, 1.0],
        );
      canvas.drawCircle(c, r, fill);

      final ringPaint = Paint()
        ..color = AppTheme.primaryDark.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (var i = 1; i <= 3; i++) {
        canvas.drawCircle(c, r * (0.35 + i * 0.15), ringPaint);
      }
    }

    canvas.drawArc(
      Rect.fromCircle(center: c.translate(-3, -5), radius: r * 0.52),
      -2.2,
      1.4,
      false,
      Paint()
        ..color = Colors.white.withOpacity(locked ? 0.12 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StumpNodePainter oldDelegate) =>
      oldDelegate.locked != locked;
}

class _ForestBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF6F0E2),
          Color(0xFFE6EEDF),
          Color(0xFFD4E4CC),
          Color(0xFFC5D9BC),
        ],
        stops: [0.0, 0.3, 0.65, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final rng = math.Random(17);

    // Meadow grass wash (soft field texture)
    for (var i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 40 + rng.nextDouble() * 90,
          height: 18 + rng.nextDouble() * 36,
        ),
        Paint()
          ..color = Color.lerp(
            const Color(0xFF8FBC7A),
            AppTheme.goatAccent,
            rng.nextDouble(),
          )!
              .withOpacity(0.08 + rng.nextDouble() * 0.07),
      );
    }

    void grassTuft(double x, double y, double s) {
      final blade = Paint()
        ..color = const Color(0xFF5D8A4A).withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * s
        ..strokeCap = StrokeCap.round;
      for (var b = -2; b <= 2; b++) {
        final lean = b * 3.2 * s;
        canvas.drawLine(
          Offset(x + b * 2.2 * s, y),
          Offset(x + lean, y - (10 + (b.abs() % 2) * 4) * s),
          blade,
        );
      }
      // tip highlight
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 1.5 * s, y - 12 * s),
        Paint()
          ..color = const Color(0xFF9CCC65).withOpacity(0.5)
          ..strokeWidth = 1.2 * s
          ..strokeCap = StrokeCap.round,
      );
    }

    void lake(double cx, double cy, double w, double h) {
      // Shore ring
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 2), width: w + 14, height: h + 10),
        Paint()..color = const Color(0xFF8D6E4F).withOpacity(0.35),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: w + 6, height: h + 4),
        Paint()..color = const Color(0xFFA1887F).withOpacity(0.4),
      );
      // Water body
      final waterRect =
          Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
      canvas.drawOval(
        waterRect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, cy - h / 2),
            Offset(cx, cy + h / 2),
            const [
              Color(0xFF7EB8C9),
              Color(0xFF4A8FA0),
              Color(0xFF3A7385),
            ],
            const [0.0, 0.55, 1.0],
          ),
      );
      // Shine
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - w * 0.15, cy - h * 0.18),
          width: w * 0.35,
          height: h * 0.22,
        ),
        Paint()..color = Colors.white.withOpacity(0.28),
      );
      // Ripple arcs
      final ripple = Paint()
        ..color = Colors.white.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + 4, cy + 2), width: w * 0.55, height: h * 0.4),
        0.2,
        2.2,
        false,
        ripple,
      );
      // Reeds / grass on shore
      for (var r = 0; r < 5; r++) {
        grassTuft(
          cx - w * 0.45 + r * (w * 0.22),
          cy + h * 0.38,
          0.7 + (r % 2) * 0.2,
        );
      }
    }

    void cave(double cx, double cy, double scale, {bool faceRight = true}) {
      final w = 54 * scale;
      final h = 48 * scale;
      final dir = faceRight ? 1.0 : -1.0;

      // Rock mound
      final rock = Path()
        ..moveTo(cx - w * 0.55, cy + h * 0.35)
        ..quadraticBezierTo(cx - w * 0.5, cy - h * 0.55, cx, cy - h * 0.65)
        ..quadraticBezierTo(cx + w * 0.5, cy - h * 0.55, cx + w * 0.55, cy + h * 0.35)
        ..close();
      canvas.drawPath(
        rock,
        Paint()..color = const Color(0xFF6D5D4F).withOpacity(0.85),
      );
      canvas.drawPath(
        rock,
        Paint()
          ..color = const Color(0xFF4E4036).withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Dark mouth
      final mouth = Path()
        ..moveTo(cx - 10 * scale * dir, cy + h * 0.28)
        ..quadraticBezierTo(
          cx + 2 * scale * dir,
          cy - h * 0.35,
          cx + 16 * scale * dir,
          cy + h * 0.28,
        )
        ..close();
      canvas.drawPath(
        mouth,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(cx, cy - h * 0.2),
            Offset(cx, cy + h * 0.28),
            const [
              Color(0xFF2A221C),
              Color(0xFF1A1410),
            ],
          ),
      );

      // Inner glow (ember / cool cave light)
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 4 * scale * dir, cy + h * 0.05),
          width: 10 * scale,
          height: 8 * scale,
        ),
        Paint()..color = const Color(0xFF5D8A66).withOpacity(0.25),
      );

      // Stone chips
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - 18 * scale, cy + h * 0.38),
          width: 10 * scale,
          height: 5 * scale,
        ),
        Paint()..color = const Color(0xFF8D7B6A).withOpacity(0.7),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 14 * scale, cy + h * 0.4),
          width: 12 * scale,
          height: 5 * scale,
        ),
        Paint()..color = const Color(0xFF7A6A5A).withOpacity(0.65),
      );
    }

    // Soft canopy — keep center corridor open
    for (var i = 0; i < 16; i++) {
      final edge = i.isEven;
      final x = edge
          ? rng.nextDouble() * size.width * 0.18
          : size.width * (0.82 + rng.nextDouble() * 0.18);
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(
        Offset(x, y),
        55 + rng.nextDouble() * 70,
        Paint()..color = AppTheme.goatAccent.withOpacity(0.07),
      );
    }

    // Lakes tucked to the sides (between level clusters)
    final lakeYs = <double>[
      size.height * 0.12,
      size.height * 0.38,
      size.height * 0.62,
      size.height * 0.86,
    ];
    for (var i = 0; i < lakeYs.length; i++) {
      final left = i.isEven;
      lake(
        left ? size.width * 0.16 : size.width * 0.84,
        lakeYs[i],
        70 + (i % 2) * 18.0,
        36 + (i % 3) * 8.0,
      );
    }

    // Caves along the other edge / mid gaps
    cave(size.width * 0.88, size.height * 0.22, 1.05, faceRight: false);
    cave(size.width * 0.12, size.height * 0.48, 0.95, faceRight: true);
    cave(size.width * 0.86, size.height * 0.72, 1.1, faceRight: false);
    cave(size.width * 0.14, size.height * 0.92, 0.9, faceRight: true);

    void tree(double x, double baseY, double scale) {
      final trunkH = 48 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, baseY - trunkH / 2),
            width: 8 * scale,
            height: trunkH,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF5D4037).withOpacity(0.28),
      );
      final canopyY = baseY - trunkH - 4 * scale;
      canvas.drawCircle(
        Offset(x, canopyY),
        22 * scale,
        Paint()..color = AppTheme.goatAccent.withOpacity(0.22),
      );
      canvas.drawCircle(
        Offset(x - 12 * scale, canopyY + 6 * scale),
        14 * scale,
        Paint()..color = const Color(0xFF4A6B52).withOpacity(0.2),
      );
      canvas.drawCircle(
        Offset(x + 12 * scale, canopyY + 6 * scale),
        14 * scale,
        Paint()..color = const Color(0xFF6B9A72).withOpacity(0.18),
      );
    }

    // Edge trees only — leave trail readable
    for (var i = 0; i < 10; i++) {
      final y = 60.0 + i * 210;
      tree(14.0 + (i % 2) * 4, y, 0.85);
      tree(size.width - 16.0 - (i % 2) * 4, y + 40, 0.9);
    }

    // Grass tufts along trail edges & meadows
    for (var i = 0; i < 55; i++) {
      final nearEdge = i % 3 != 0;
      final x = nearEdge
          ? (i.isEven
              ? 18 + rng.nextDouble() * 48
              : size.width - 66 + rng.nextDouble() * 48)
          : size.width * (0.28 + rng.nextDouble() * 0.44);
      final y = 40 + rng.nextDouble() * (size.height - 80);
      grassTuft(x, y, 0.65 + rng.nextDouble() * 0.55);
    }

    // Leaf / dirt dapples
    for (var i = 0; i < 28; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            rng.nextDouble() * size.width,
            rng.nextDouble() * size.height,
          ),
          width: 10 + rng.nextDouble() * 24,
          height: 5 + rng.nextDouble() * 10,
        ),
        Paint()..color = const Color(0xFF5D4037).withOpacity(0.035),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ForestPathPainter extends CustomPainter {
  _ForestPathPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      final c1 = Offset(prev.dx + (midX - prev.dx) * 0.4, prev.dy + 44);
      final c2 = Offset(curr.dx - (curr.dx - midX) * 0.4, curr.dy - 44);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3E2723).withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF8D6E4F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFC9AB7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE8D4B0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ForestPathPainter oldDelegate) =>
      oldDelegate.points != points;
}
