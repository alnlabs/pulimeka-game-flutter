import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact in-game header: back, title, hint chip, overflow menu.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    required this.modeLabel,
    required this.subtitle,
    required this.hintLabel,
    this.subtitleListenable,
    this.hintLabelListenable,
    required this.onBack,
    required this.onHint,
    required this.onRules,
    required this.onRestart,
    required this.onMenu,
    this.onProfile,
    this.onEditNames,
    this.editNamesLabel = 'Change names',
    this.showHintBar = true,
    this.showHintActions = true,
    this.showRestartInMenu = true,
    super.key,
  });

  final String modeLabel;
  final String subtitle;
  final ValueListenable<String>? subtitleListenable;
  final String hintLabel;
  final ValueListenable<String>? hintLabelListenable;
  final VoidCallback onBack;
  final VoidCallback onHint;
  final VoidCallback onRules;
  final VoidCallback onRestart;
  final VoidCallback onMenu;
  final VoidCallback? onProfile;
  final VoidCallback? onEditNames;
  final String editNamesLabel;
  final bool showHintBar;
  final bool showHintActions;
  final bool showRestartInMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.topBarDecoration(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          4,
          4 + MediaQuery.paddingOf(context).top,
          8,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _IconBtn(icon: Icons.arrow_back, onPressed: onBack),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          modeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.text(
                            size: 17,
                            weight: FontWeight.bold,
                            color: AppTheme.textOnDark,
                          ),
                        ),
                        _SubtitleText(
                          text: subtitle,
                          listenable: subtitleListenable,
                        ),
                      ],
                    ),
                  ),
                ),
                _OverflowMenuButton(
                  showHintActions: showHintActions,
                  showRestartInMenu: showRestartInMenu,
                  editNamesLabel: editNamesLabel,
                  hasEditNames: onEditNames != null,
                  hasProfile: onProfile != null,
                  onHint: onHint,
                  onEditNames: onEditNames,
                  onProfile: onProfile,
                  onRules: onRules,
                  onRestart: onRestart,
                  onMenu: onMenu,
                ),
              ],
            ),
            if (showHintBar) ...[
              const SizedBox(height: 6),
              _HintBar(
                hintLabel: hintLabel,
                hintLabelListenable: hintLabelListenable,
                onHint: showHintActions ? onHint : null,
                showHintActions: showHintActions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Uses [showMenu] instead of [PopupMenuButton] so the menu stays open even
/// when the header rebuilds during gameplay.
class _OverflowMenuButton extends StatefulWidget {
  const _OverflowMenuButton({
    required this.showHintActions,
    required this.showRestartInMenu,
    required this.editNamesLabel,
    required this.hasEditNames,
    required this.hasProfile,
    required this.onHint,
    required this.onEditNames,
    required this.onProfile,
    required this.onRules,
    required this.onRestart,
    required this.onMenu,
  });

  final bool showHintActions;
  final bool showRestartInMenu;
  final String editNamesLabel;
  final bool hasEditNames;
  final bool hasProfile;
  final VoidCallback onHint;
  final VoidCallback? onEditNames;
  final VoidCallback? onProfile;
  final VoidCallback onRules;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  State<_OverflowMenuButton> createState() => _OverflowMenuButtonState();
}

class _OverflowMenuButtonState extends State<_OverflowMenuButton> {
  final _anchorKey = GlobalKey();

  Future<void> _openMenu() async {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screen = MediaQuery.sizeOf(context);

    final selected = await showMenu<String>(
      context: context,
      color: AppTheme.cardWhite,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        screen.width - offset.dx - size.width,
        screen.height - offset.dy - size.height,
      ),
      items: [
        if (widget.showHintActions)
          const PopupMenuItem(
            value: 'hint',
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline),
              title: Text('Get hint'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (widget.hasEditNames)
          PopupMenuItem(
            value: 'names',
            child: ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(widget.editNamesLabel),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        if (widget.hasProfile)
          const PopupMenuItem(
            value: 'profile',
            child: ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Profile & hints'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: 'rules',
          child: ListTile(
            leading: Icon(Icons.menu_book_outlined),
            title: Text('Quick rules'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (widget.showRestartInMenu)
          const PopupMenuItem(
            value: 'restart',
            child: ListTile(
              leading: Icon(Icons.restart_alt),
              title: Text('Restart'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: 'menu',
          child: ListTile(
            leading: Icon(Icons.menu),
            title: Text('Game menu'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );

    if (!mounted || selected == null) return;

    switch (selected) {
      case 'hint':
        widget.onHint();
      case 'names':
        widget.onEditNames?.call();
      case 'profile':
        widget.onProfile?.call();
      case 'rules':
        widget.onRules();
      case 'restart':
        widget.onRestart();
      case 'menu':
        widget.onMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _anchorKey,
      icon: const Icon(Icons.more_vert, color: AppTheme.textOnDark),
      tooltip: 'Menu',
      onPressed: _openMenu,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppTheme.textOnDark, size: 22),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _SubtitleText extends StatelessWidget {
  const _SubtitleText({
    required this.text,
    this.listenable,
  });

  final String text;
  final ValueListenable<String>? listenable;

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.text(
      size: 12,
      color: AppTheme.textOnDark.withOpacity(0.85),
    );
    if (listenable == null) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return ValueListenableBuilder<String>(
      valueListenable: listenable!,
      builder: (context, value, _) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar({
    required this.hintLabel,
    required this.hintLabelListenable,
    required this.onHint,
    required this.showHintActions,
  });

  final String hintLabel;
  final ValueListenable<String>? hintLabelListenable;
  final VoidCallback? onHint;
  final bool showHintActions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: InkWell(
        onTap: onHint,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppTheme.textOnDark,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HintLabelText(
                  text: hintLabel,
                  listenable: hintLabelListenable,
                ),
              ),
              if (showHintActions)
                const Icon(
                  Icons.touch_app,
                  size: 14,
                  color: AppTheme.textOnDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintLabelText extends StatelessWidget {
  const _HintLabelText({
    required this.text,
    this.listenable,
  });

  final String text;
  final ValueListenable<String>? listenable;

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.text(
      size: 12,
      weight: FontWeight.w600,
      color: AppTheme.textOnDark,
    );
    if (listenable == null) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return ValueListenableBuilder<String>(
      valueListenable: listenable!,
      builder: (context, value, _) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
