import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/external_links.dart';
import '../widgets/ad_banner.dart';
import '../widgets/help_section.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routeName = '/privacy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnDark,
      ),
      bottomNavigationBar: const ScreenAdBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          children: [
            TextButton.icon(
              onPressed: ExternalLinks.openPrivacyPolicy,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('View full policy on alnlabs.com'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 8),
            const HelpSection(
              title: 'Your privacy',
              children: [
                HelpParagraph(
                  'We respect your privacy. This app uses Firebase Realtime Database for online '
                  'gameplay sync and Google AdMob for optional ads. We do not collect personal profile '
                  'data for marketing.',
                ),
              ],
            ),
            const HelpSection(
              title: 'Data collection',
              children: [
                HelpParagraph(
                  'Online rooms store player display names and game state on Firebase while a match is active. '
                  'Local device storage keeps game history, leaderboard stats, sound settings, and hint preferences.',
                ),
              ],
            ),
            const HelpSection(
              title: 'Ads',
              children: [
                HelpParagraph(
                  'Banner ads may appear on some screens. Android does not show '
                  'rewarded or full-screen video ads.',
                ),
              ],
            ),
            const HelpSection(
              title: 'Contact',
              children: [
                HelpParagraph(
                  'For questions, email alnlabs.com@gmail.com or use the full policy link above.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
