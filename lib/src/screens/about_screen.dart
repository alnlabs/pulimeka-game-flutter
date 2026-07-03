import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../content/hint_help_content.dart';
import '../theme/app_theme.dart';
import '../widgets/help_section.dart';
import 'how_to_play_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const routeName = '/about';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnDark,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          children: [
            Center(
              child: Image.asset(
                GameAssets.playstoreIcon,
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Puli Meka',
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 24, weight: FontWeight.bold, color: AppTheme.primaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              'Classic Indian board game — Tigers vs Goats',
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Designed and developed by Nageshwar Reddy Pandem',
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 12, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 24),
            const HelpSection(
              title: 'About the game',
              children: [
                HelpParagraph(
                  'Also known as Aadu Puli Aatam, Pulijudam, and similar names across South India. '
                  'This digital version uses a traditional grid board with tigers and goats.',
                ),
                HelpParagraph(
                  'Play offline with a friend, against AI, or online (when available).',
                ),
              ],
            ),
            HelpSection(
              title: HintHelpContent.sectionTitle,
              children: [
                HelpParagraph(HintHelpContent.intro),
                ...HintHelpContent.bullets.map(HelpBullet.new),
                const HelpParagraph(
                  'Banner ads may appear at the bottom of some screens. '
                  'Hint unlock ads are optional and only shown when you request an extra hint.',
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, HowToPlayScreen.routeName),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Full how to play'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
