import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'how_to_play_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnDark,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.school_outlined, color: AppTheme.primary),
              title: Text('How to Play', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
              subtitle: Text(
                'Rules, objectives, and hints',
                style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
              ),
              onTap: () => Navigator.pushNamed(context, HowToPlayScreen.routeName),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primary),
              title: Text('About', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
              subtitle: Text(
                'App info and how hints & ads work',
                style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
              ),
              onTap: () => Navigator.pushNamed(context, AboutScreen.routeName),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Text(
                'Sound, ads, and online preferences will be added here in a future update.',
                style: AppTheme.text(size: 14, color: AppTheme.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
