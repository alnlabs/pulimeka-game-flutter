import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../theme/app_theme.dart';
import '../widgets/help_section.dart';

/// Cultural / regional info (Android `AboutGameScreen` / home "Game History").
class AboutGameScreen extends StatelessWidget {
  const AboutGameScreen({super.key});

  static const routeName = '/about-game';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('About the Game'),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnDark,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          children: [
            const HelpSection(
              title: 'Regional names',
              children: [
                HelpParagraph(
                  'Known across South India as Aadu Puli Aatam (Tamil Nadu), Pulijudam, '
                  'Huli Gatta (Karnataka), and similar names. Rules vary slightly by region; '
                  'this app uses the common 2-tiger, 23-goat layout with 12 captures to win.',
                ),
              ],
            ),
            const HelpSection(
              title: 'How it is played',
              children: [
                HelpParagraph(
                  'Two tigers face many goats on a point-to-point board. Tigers jump to capture goats; '
                  'goats place then move to surround and trap the tigers.',
                ),
                HelpParagraph(
                  'Traditional boards were drawn on temple floors or village courtyards — '
                  'a social game passed down for generations.',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Board styles across regions',
              style: AppTheme.text(size: 18, weight: FontWeight.bold, color: AppTheme.primaryLight),
            ),
            const SizedBox(height: 12),
            ...GameAssets.regionalBoards.map(_BoardGalleryCard.new),
          ],
        ),
      ),
    );
  }
}

class _BoardGalleryCard extends StatelessWidget {
  const _BoardGalleryCard(this.item);

  final BoardGalleryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.cardWhite,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              item.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: AppTheme.backgroundLighter,
                child: Center(child: Icon(Icons.image_not_supported_outlined)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTheme.text(size: 16, weight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
