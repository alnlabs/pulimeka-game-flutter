import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum HomeMenuStyle { primary, secondary, tertiary }

class HomeMenuButton extends StatelessWidget {
  const HomeMenuButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.style = HomeMenuStyle.primary,
    this.compact = false,
    this.subtitle,
    super.key,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final HomeMenuStyle style;
  final String? subtitle;
  /// Narrow layouts (e.g. half-width row): no chevron, tighter padding.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color textColor;
    late final Color iconColor;
    late final double elevation;
    BorderSide? border;

    switch (style) {
      case HomeMenuStyle.primary:
        bg = AppTheme.primary;
        textColor = AppTheme.textOnDark;
        iconColor = AppTheme.textOnDark;
        elevation = 6;
      case HomeMenuStyle.secondary:
        bg = AppTheme.cardWhite;
        textColor = AppTheme.primaryDark;
        iconColor = AppTheme.primary;
        elevation = 2;
        border = BorderSide(color: AppTheme.primary.withOpacity(0.35), width: 1.5);
      case HomeMenuStyle.tertiary:
        bg = AppTheme.primaryLightBackground;
        textColor = AppTheme.primaryDark;
        iconColor = AppTheme.primary;
        elevation = 0;
        border = BorderSide(color: AppTheme.borderSubtle);
    }

    final showChevron = !compact && style != HomeMenuStyle.tertiary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: elevation,
      shadowColor: AppTheme.textPrimary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: border ?? BorderSide.none,
      ),
      color: bg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: SizedBox(
          height: AppTheme.buttonHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : AppTheme.spacingMedium,
            ),
            child: Row(
              mainAxisAlignment:
                  compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor, size: compact ? 20 : AppTheme.iconSize),
                SizedBox(width: compact ? 8 : AppTheme.spacingMedium),
                if (compact)
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTheme.text(
                        size: 14,
                        weight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: subtitle == null
                        ? Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.text(
                              size: 16,
                              weight: FontWeight.w600,
                              color: textColor,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.text(
                                  size: 16,
                                  weight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.text(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: textColor.withOpacity(0.72),
                                ),
                              ),
                            ],
                          ),
                  ),
                if (showChevron)
                  Icon(Icons.chevron_right, color: iconColor.withOpacity(0.7), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
