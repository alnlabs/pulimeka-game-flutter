import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// Writes a [RenderRepaintBoundary] to a PNG file.
class BoardScreenshotCapture {
  BoardScreenshotCapture._();

  static Future<void> savePng({
    required RenderRepaintBoundary boundary,
    required String path,
    double pixelRatio = 2.0,
  }) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Failed to encode PNG for $path');
    }
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List());
  }
}
