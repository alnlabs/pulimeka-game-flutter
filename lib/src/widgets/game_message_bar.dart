import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reserved strip below HUD — fixed height so hints never shift the board.
class GameMessageBar extends StatelessWidget {
  const GameMessageBar({
    this.invalidMessage,
    this.hintMessage,
    super.key,
  });

  /// Reserved strip below HUD — grows up to two lines so text is not clipped.
  static const double slotHeight = 64;

  final String? invalidMessage;
  final String? hintMessage;

  @override
  Widget build(BuildContext context) {
    final text = invalidMessage ?? hintMessage;
    final isInvalid = invalidMessage != null;
    final visible = text != null && text.isNotEmpty;

    return SizedBox(
      height: slotHeight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: visible ? 1 : 0,
            child: _MessageTile(
              message: text ?? '',
              icon: isInvalid ? Icons.info_outline : Icons.lightbulb_outline,
              background:
                  isInvalid ? AppTheme.messageErrorBg : AppTheme.messageHintBg,
              foreground:
                  isInvalid ? AppTheme.messageErrorFg : AppTheme.messageHintFg,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: GameMessageBar.slotHeight - 8,
        maxHeight: GameMessageBar.slotHeight + 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: foreground.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: foreground),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.text(
                size: 13,
                weight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
