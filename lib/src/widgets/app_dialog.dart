import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared modal styling (replaces default AlertDialog look).
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    this.content,
    this.actions = const [],
    this.icon,
    super.key,
  });

  final String title;
  final Widget? content;
  final List<Widget> actions;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxW = (width - 40).clamp(280.0, 400.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: DecoratedBox(
          decoration: AppTheme.panelDecoration(
            color: AppTheme.cardWhite,
            borderColor: AppTheme.borderSubtle,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogHeader(title: title, icon: icon),
              if (content != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: content,
                ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: _DialogActions(children: actions),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.textOnDark, size: 24),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTheme.text(
                size: 18,
                weight: FontWeight.bold,
                color: AppTheme.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.length == 1) {
      return SizedBox(width: double.infinity, child: children.first);
    }
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

class AppDialogButton extends StatelessWidget {
  const AppDialogButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: AppTheme.filledButtonStyle,
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
      child: Text(label),
    );
  }
}

class AppDialogBodyText extends StatelessWidget {
  const AppDialogBodyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.text(size: 15, color: AppTheme.textSecondary, weight: FontWeight.w500),
    );
  }
}

class AppDialogMenuTile extends StatelessWidget {
  const AppDialogMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.text(size: 16, weight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
