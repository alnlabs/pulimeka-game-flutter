import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_dialog.dart';

class StartGameDialog extends StatelessWidget {
  const StartGameDialog({
    required this.onDismiss,
    required this.onPlayOffline,
    required this.onPlayOnline,
    required this.onPlayAI,
    super.key,
  });

  final VoidCallback onDismiss;
  final VoidCallback onPlayOffline;
  final VoidCallback onPlayOnline;
  final VoidCallback onPlayAI;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Start Game',
      icon: Icons.sports_esports_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeCard(
            icon: Icons.smartphone_outlined,
            title: 'Play Offline',
            subtitle: 'Two players on this device',
            onTap: onPlayOffline,
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.public_outlined,
            title: 'Play Online',
            subtitle: 'Room with a friend',
            onTap: onPlayOnline,
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.smart_toy_outlined,
            title: 'Play with AI',
            subtitle: 'Single player vs computer',
            onTap: onPlayAI,
          ),
        ],
      ),
      actions: [
        AppDialogButton(label: 'Cancel', onPressed: onDismiss),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundLight,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.text(size: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.text(size: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
