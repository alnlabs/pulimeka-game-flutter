import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puli_meka_game_flutter/src/theme/app_theme.dart';
import 'package:puli_meka_game_flutter/tools/board_screenshot_capture.dart';
import 'package:puli_meka_game_flutter/tools/board_screenshot_catalog.dart';
import 'package:puli_meka_game_flutter/tools/board_screenshot_frame.dart';

/// Fast headless fallback (macOS runner is preferred — see script).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final outputDir = Platform.environment['BOARD_SCREENSHOT_DIR'] ??
      'docs/board-screenshots/phases';

  for (final phase in BoardScreenshotCatalog.phases) {
    testWidgets('capture ${phase.filename}', (tester) async {
      const size = Size(390, 520);
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.materialTheme(),
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: BoardScreenshotFrame(
                  title: phase.title,
                  subtitle: phase.subtitle,
                  ui: phase.ui,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(BoardScreenshotFrame.captureKey),
      );

      await tester.runAsync(() async {
        await BoardScreenshotCapture.savePng(
          boundary: boundary,
          path: '$outputDir/${phase.filename}',
          pixelRatio: 1.0,
        );
      });

      expect(File('$outputDir/${phase.filename}').existsSync(), isTrue);
    });
  }
}
