import 'package:flutter/material.dart';

import '../services/offline_player_prefs.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';

/// Offline: edit tiger + goat player names.
Future<({String tiger, String goat})?> showOfflinePlayerNamesDialog(
  BuildContext context, {
  required String initialTiger,
  required String initialGoat,
  String title = 'Player names',
}) {
  return showDialog<({String tiger, String goat})>(
    context: context,
    builder: (ctx) => _OfflinePlayerNamesDialog(
      title: title,
      initialTiger: initialTiger,
      initialGoat: initialGoat,
    ),
  );
}

/// Online: edit the local player's display name.
Future<String?> showSinglePlayerNameDialog(
  BuildContext context, {
  required String initialName,
  String title = 'Your name',
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _SinglePlayerNameDialog(
      title: title,
      initialName: initialName,
    ),
  );
}

class _OfflinePlayerNamesDialog extends StatefulWidget {
  const _OfflinePlayerNamesDialog({
    required this.title,
    required this.initialTiger,
    required this.initialGoat,
  });

  final String title;
  final String initialTiger;
  final String initialGoat;

  @override
  State<_OfflinePlayerNamesDialog> createState() =>
      _OfflinePlayerNamesDialogState();
}

class _OfflinePlayerNamesDialogState extends State<_OfflinePlayerNamesDialog> {
  late final TextEditingController _tigerController;
  late final TextEditingController _goatController;
  String? _tigerError;
  String? _goatError;

  @override
  void initState() {
    super.initState();
    _tigerController = TextEditingController(text: widget.initialTiger);
    _goatController = TextEditingController(text: widget.initialGoat);
  }

  @override
  void dispose() {
    _tigerController.dispose();
    _goatController.dispose();
    super.dispose();
  }

  void _save() {
    final tigerErr =
        _tigerController.text.length > 20 ? 'Max 20 characters' : null;
    final goatErr =
        _goatController.text.length > 20 ? 'Max 20 characters' : null;
    if (tigerErr != null || goatErr != null) {
      setState(() {
        _tigerError = tigerErr;
        _goatError = goatErr;
      });
      return;
    }

    final tiger = _tigerController.text.trim();
    final goat = _goatController.text.trim();
    Navigator.pop(
      context,
      (
        tiger: tiger.isEmpty ? OfflinePlayerPrefs.defaultTigerName : tiger,
        goat: goat.isEmpty ? OfflinePlayerPrefs.defaultGoatName : goat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      icon: Icons.people_outline,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _tigerController,
            decoration: AppTheme.inputDecoration(
              label: 'Tiger player',
              hint: 'Optional',
              errorText: _tigerError,
            ),
            maxLength: 20,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                null,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _goatController,
            decoration: AppTheme.inputDecoration(
              label: 'Goat player',
              hint: 'Optional',
              errorText: _goatError,
            ),
            maxLength: 20,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                null,
          ),
        ],
      ),
      actions: [
        AppDialogButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogButton(
          label: 'Save',
          primary: true,
          onPressed: _save,
        ),
      ],
    );
  }
}

class _SinglePlayerNameDialog extends StatefulWidget {
  const _SinglePlayerNameDialog({
    required this.title,
    required this.initialName,
  });

  final String title;
  final String initialName;

  @override
  State<_SinglePlayerNameDialog> createState() => _SinglePlayerNameDialogState();
}

class _SinglePlayerNameDialogState extends State<_SinglePlayerNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_controller.text.length > 20) {
      setState(() => _error = 'Max 20 characters');
      return;
    }
    final name = _controller.text.trim();
    Navigator.pop(context, name.isEmpty ? 'Player' : name);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      icon: Icons.badge_outlined,
      content: TextField(
        controller: _controller,
        decoration: AppTheme.inputDecoration(
          label: 'Display name',
          hint: 'Shown to your opponent',
          errorText: _error,
        ),
        maxLength: 20,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
            null,
      ),
      actions: [
        AppDialogButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogButton(
          label: 'Save',
          primary: true,
          onPressed: _save,
        ),
      ],
    );
  }
}
