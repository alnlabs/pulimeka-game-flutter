import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:puli_meka_game_flutter/src/theme/app_theme.dart';
import 'package:puli_meka_game_flutter/src/tutorial/tutorial_snapshots.dart';
import 'package:puli_meka_game_flutter/src/widgets/tutorial_board_panel.dart';
import 'package:puli_meka_game_flutter/tools/board_screenshot_capture.dart';
import 'package:puli_meka_game_flutter/tools/board_screenshot_catalog.dart';
import 'package:puli_meka_game_flutter/tools/board_screenshot_frame.dart';

/// Headless-ish desktop runner: renders each phase once, saves PNG, exits.
///
/// Run: ./scripts/capture_board_screenshots.sh
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _CaptureScreenshotsApp());
}

class _CaptureScreenshotsApp extends StatefulWidget {
  const _CaptureScreenshotsApp();

  @override
  State<_CaptureScreenshotsApp> createState() => _CaptureScreenshotsAppState();
}

class _CaptureScreenshotsAppState extends State<_CaptureScreenshotsApp> {
  final _boundaryKey = GlobalKey();

  static final _phasesDir = Platform.environment['BOARD_SCREENSHOT_DIR'] ??
      'docs/board-screenshots/phases';
  static final _tutorialDir = Platform.environment['TUTORIAL_SCREENSHOT_DIR'] ??
      'docs/board-screenshots/tutorial-pages';
  static final _captureTutorial =
      Platform.environment['CAPTURE_TUTORIAL'] == 'true';

  int _taskIndex = 0;
  late final List<_CaptureTask> _tasks = [
    ...BoardScreenshotCatalog.phases.map(
      (p) => _CaptureTask(
        path: '$_phasesDir/${p.filename}',
        builder: () => BoardScreenshotFrame(
          title: p.title,
          subtitle: p.subtitle,
          ui: p.ui,
        ),
        size: const Size(390, 520),
      ),
    ),
    if (_captureTutorial)
      ...TutorialSnapshots.allSteps.map(
        (s) => _CaptureTask(
          path:
              '$_tutorialDir/${(s.index + 1).toString().padLeft(2, '0')}-${_slug(s.title)}.png',
          builder: () => _TutorialPageCapture(step: s),
          size: Size(390, s.layout == TutorialBoardLayout.dualWin ? 560 : 420),
        ),
      ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureCurrent());
  }

  Future<void> _captureCurrent() async {
    if (_taskIndex >= _tasks.length) {
      stderr.writeln('Saved ${_tasks.length} screenshot(s).');
      exit(0);
    }

    final task = _tasks[_taskIndex];
    stderr.writeln('Capturing ${task.path}...');

    await Future<void>.delayed(const Duration(milliseconds: 120));

    final context = _boundaryKey.currentContext;
    if (context == null) {
      throw StateError('Capture boundary not mounted for ${task.path}');
    }

    final boundary = context.findRenderObject()! as RenderRepaintBoundary;
    await BoardScreenshotCapture.savePng(
      boundary: boundary,
      path: task.path,
      pixelRatio: 2.0,
    );

    setState(() => _taskIndex++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureCurrent());
  }

  @override
  Widget build(BuildContext context) {
    if (_taskIndex >= _tasks.length) {
      return const SizedBox.shrink();
    }

    final task = _tasks[_taskIndex];
    return MaterialApp(
      theme: AppTheme.materialTheme(),
      home: MediaQuery(
        data: MediaQueryData(size: task.size),
        child: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: SizedBox(
                width: task.size.width,
                height: task.size.height,
                child: task.builder(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _slug(String title) {
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class _CaptureTask {
  const _CaptureTask({
    required this.path,
    required this.builder,
    required this.size,
  });

  final String path;
  final Widget Function() builder;
  final Size size;
}

class _TutorialPageCapture extends StatelessWidget {
  const _TutorialPageCapture({required this.step});

  final TutorialStepData step;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Step ${step.index + 1}: ${step.title}',
              style: AppTheme.text(
                size: 18,
                weight: FontWeight.bold,
                color: step.accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Expanded(child: TutorialBoardPanel(step: step)),
          ],
        ),
      ),
    );
  }
}
