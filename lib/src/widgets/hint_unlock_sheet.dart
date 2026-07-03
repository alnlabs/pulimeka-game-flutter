import 'package:flutter/material.dart';

import '../models/hint_policy.dart';
import '../theme/app_theme.dart';

enum HintUnlockMethod { rewardedVideo, timedAd }

Future<HintUnlockMethod?> showHintUnlockSheet(
  BuildContext context, {
  bool showRewardedOption = true,
}) {
  return showModalBottomSheet<HintUnlockMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: AppTheme.panelDecoration(
            color: AppTheme.cardWhite,
            borderColor: AppTheme.primary.withOpacity(0.2),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Get a hint',
                    textAlign: TextAlign.center,
                    style: AppTheme.text(size: 18, weight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Watch a short ad to unlock ${HintPolicy.hintsPerAdBatch} hints.',
                    textAlign: TextAlign.center,
                    style: AppTheme.text(size: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  if (showRewardedOption) ...[
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        HintUnlockMethod.rewardedVideo,
                      ),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Watch video'),
                      style: AppTheme.filledButtonStyle,
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, HintUnlockMethod.timedAd),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Short ad · skip when ready'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
