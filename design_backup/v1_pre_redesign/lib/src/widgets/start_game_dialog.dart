import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    return AlertDialog(
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(),
      title: Text(
        '🎮 Start Game',
        style: AppTheme.text(size: 24, weight: FontWeight.bold, color: AppTheme.primaryLight),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeCard(
            icon: Icons.smartphone,
            title: 'Play Offline',
            subtitle: 'Play locally on this device',
            onTap: onPlayOffline,
          ),
          const SizedBox(height: 8),
          _ModeCard(
            icon: Icons.public,
            title: 'Play Online',
            subtitle: 'Play with friends online',
            onTap: onPlayOnline,
          ),
          const SizedBox(height: 8),
          _ModeCard(
            icon: Icons.lightbulb_outline,
            title: 'Play with AI',
            subtitle: 'Challenge the computer',
            onTap: onPlayAI,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onDismiss, child: const Text('Cancel')),
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
    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.primaryLight,
      elevation: 4,
      shape: const RoundedRectangleBorder(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: AppTheme.iconSize),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.text(size: 16, weight: FontWeight.w600, color: Colors.white),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.text(size: 14, color: const Color(0xFFF5F5F5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
