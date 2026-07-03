import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum HintUnlockMethod { rewardedVideo, timedAd }

/// Choose how to unlock a hint after free hints are used.
Future<HintUnlockMethod?> showHintUnlockSheet(BuildContext context) {
  return showModalBottomSheet<HintUnlockMethod>(
    context: context,
    backgroundColor: AppTheme.cardWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Get a hint',
                style: AppTheme.text(size: 20, weight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Watch a short ad to see a suggested move.',
                textAlign: TextAlign.center,
                style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, HintUnlockMethod.rewardedVideo),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch video'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.textOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, HintUnlockMethod.timedAd),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Short ad (tap Skip when ready)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
