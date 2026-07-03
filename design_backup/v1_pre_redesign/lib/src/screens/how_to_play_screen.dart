import 'package:flutter/material.dart';

import '../content/hint_help_content.dart';
import '../theme/app_theme.dart';
import '../widgets/help_section.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const routeName = '/how-to-play';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('How to Play'),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnDark,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          children: [
            const HelpSection(
              title: 'Objective',
              children: [
                HelpParagraph(
                  'Puli Meka is a strategy game between Tigers and Goats.',
                ),
                HelpParagraph(
                  'Tigers win by capturing 12 goats (jumps over a goat into an empty node).',
                ),
                HelpParagraph(
                  'Goats win by trapping all tigers so they cannot move.',
                ),
              ],
            ),
            const HelpSection(
              title: 'Gameplay',
              children: [
                HelpBullet('Tigers move first.'),
                HelpBullet(
                  'Goats start by placing pieces from hand onto empty board nodes (green dots).',
                ),
                HelpBullet(
                  'After placement, goats and tigers alternate turns moving to adjacent empty nodes.',
                ),
                HelpBullet(
                  'Tigers may also jump over a goat to capture it when the landing node is empty.',
                ),
                HelpBullet('Select your piece, then tap a highlighted node to move.'),
              ],
            ),
            HelpSection(
              title: HintHelpContent.sectionTitle,
              children: [
                HelpParagraph(HintHelpContent.intro),
                ...HintHelpContent.bullets.map(HelpBullet.new),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
