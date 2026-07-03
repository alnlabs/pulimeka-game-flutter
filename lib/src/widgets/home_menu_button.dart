import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum HomeMenuStyle { primary, secondary, tertiary }

class HomeMenuButton extends StatelessWidget {
  const HomeMenuButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.style = HomeMenuStyle.primary,
    super.key,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final HomeMenuStyle style;

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
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: AppTheme.iconSize),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Text(
                    text,
                    style: AppTheme.text(
                      size: 16,
                      weight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (style != HomeMenuStyle.tertiary)
                  Icon(Icons.chevron_right, color: iconColor.withOpacity(0.7), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
