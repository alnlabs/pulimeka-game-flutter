import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomeMenuButton extends StatelessWidget {
  const HomeMenuButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = color == AppTheme.primary ||
        color == AppTheme.primaryDark ||
        color == AppTheme.primaryLight ||
        color == AppTheme.primaryLighter;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final iconColor = isDark ? Colors.white : AppTheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 6,
      shape: const RoundedRectangleBorder(),
      color: color,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppTheme.buttonHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: AppTheme.iconSize),
                const SizedBox(width: AppTheme.spacingMedium),
                Text(
                  text,
                  style: AppTheme.text(
                    size: 16,
                    weight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
