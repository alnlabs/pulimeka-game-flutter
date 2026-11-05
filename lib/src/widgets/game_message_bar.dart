import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hint / error line. Collapses when empty so it does not steal board space.
class GameMessageBar extends StatelessWidget {
  const GameMessageBar({
    this.invalidMessage,
    this.hintMessage,
    super.key,
  });

  final String? invalidMessage;
  final String? hintMessage;

  @override
  Widget build(BuildContext context) {
    final text = invalidMessage ?? hintMessage;
    final isInvalid = invalidMessage != null;
    final visible = text != null && text.isNotEmpty;
    if (!visible) return const SizedBox.shrink();

    final background =
        isInvalid ? AppTheme.messageErrorBg : AppTheme.messageHintBg;
    final foreground =
        isInvalid ? AppTheme.messageErrorFg : AppTheme.messageHintFg;

    return Material(
      color: background.withOpacity(0.94),
      elevation: 2,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Icon(
              isInvalid ? Icons.info_outline : Icons.lightbulb_outline,
              size: 16,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.text(
                  size: 12,
                  weight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
