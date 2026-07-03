import 'package:flutter/material.dart';

import '../content/hint_help_content.dart';
import '../theme/app_theme.dart';
import '../utils/external_links.dart';
import '../widgets/help_section.dart';
import 'tutorial_screen.dart';

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
            Material(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, TutorialScreen.routeName),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLightBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.grid_on,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visual board tutorial',
                              style: AppTheme.text(
                                size: 16,
                                weight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Step-by-step diagrams on the real board',
                              style: AppTheme.text(
                                size: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ExternalLinks.openYouTubeTutorial(),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch videos on YouTube'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryDark,
                side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
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
