import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../tutorial/tutorial_snapshots.dart';
import '../widgets/tutorial_board_panel.dart';

/// Short text-first tutorial — one board diagram, then written rules.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  static const routeName = '/tutorial';

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  late final List<TutorialStepData> _steps = TutorialSnapshots.allSteps;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_pageIndex];
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('How to play (${_pageIndex + 1}/${_steps.length})'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_pageIndex + 1) / _steps.length,
            backgroundColor: AppTheme.backgroundLighter,
            color: step.accentColor,
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _pageIndex = i),
              itemBuilder: (context, index) => _TutorialPage(step: _steps[index]),
            ),
          ),
          _PageIndicator(count: _steps.length, index: _pageIndex, accent: step.accentColor),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Row(
              children: [
                if (_pageIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: step.accentColor,
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_pageIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (_pageIndex < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: step.accentColor,
                      foregroundColor: AppTheme.textOnDark,
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(_pageIndex < _steps.length - 1 ? 'Next' : 'Start playing'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.step});

  final TutorialStepData step;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            step.title,
            style: AppTheme.text(size: 20, weight: FontWeight.bold, color: step.accentColor),
          ),
          const SizedBox(height: 8),
          Text(
            step.body,
            style: AppTheme.text(size: 15, color: AppTheme.textSecondary, weight: FontWeight.w500),
          ),
          if (step.board != null) ...[
            const SizedBox(height: 16),
            TutorialBoardPanel(board: step.board!, caption: step.boardCaption),
          ],
          if (step.bullets.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...step.bullets.map((bullet) => _RuleBullet(bullet: bullet, accent: step.accentColor)),
          ],
        ],
      ),
    );
  }
}

class _RuleBullet extends StatelessWidget {
  const _RuleBullet({required this.bullet, required this.accent});

  final TutorialBullet bullet;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTheme.text(size: 14, color: AppTheme.textPrimary).copyWith(height: 1.45),
                children: [
                  TextSpan(
                    text: '${bullet.label}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: bullet.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.index, required this.accent});

  final int count;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 18 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: active ? accent : AppTheme.backgroundLighter,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
