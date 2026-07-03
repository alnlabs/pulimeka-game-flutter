import 'package:flutter/material.dart';

import '../assets/game_assets.dart';
import '../services/online_session_prefs.dart';
import '../theme/app_theme.dart';

class AiGameSelectionScreen extends StatefulWidget {
  const AiGameSelectionScreen({
    required this.onBack,
    required this.onStartGame,
    super.key,
  });

  final VoidCallback onBack;
  final void Function(String role, String difficulty, String humanName) onStartGame;

  @override
  State<AiGameSelectionScreen> createState() => _AiGameSelectionScreenState();
}

class _AiGameSelectionScreenState extends State<AiGameSelectionScreen> {
  String? _role;
  String? _difficulty;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final name = await OnlineSessionPrefs.getPlayerName();
    if (!mounted) return;
    _nameController.text = name;
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _humanName {
    final name = _nameController.text.trim();
    return name.isEmpty ? 'You' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: widget.onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  children: [
                    Text('🤖', style: AppTheme.text(size: 64)),
                    Text(
                      'Play with AI',
                      style: AppTheme.text(size: 20, weight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your role and challenge level',
                      textAlign: TextAlign.center,
                      style: AppTheme.text(size: 16, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    _SectionCard(
                      title: 'Your name',
                      child: TextField(
                        controller: _nameController,
                        maxLength: 20,
                        decoration: AppTheme.inputDecoration(
                          label: 'Display name',
                          hint: 'Shown on your pieces',
                        ),
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) =>
                            null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Choose Your Role',
                      child: Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              asset: GameAssets.tigerIcon,
                              title: 'Play as Tigers',
                              selected: _role == 'tiger',
                              onTap: () => setState(() => _role = 'tiger'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RoleCard(
                              asset: GameAssets.goatIcon,
                              title: 'Play as Goats',
                              selected: _role == 'goat',
                              onTap: () => setState(() => _role = 'goat'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'AI Difficulty Level',
                      child: Column(
                        children: [
                          _DifficultyTile(
                            label: 'Easy',
                            selected: _difficulty == 'easy',
                            onTap: () => setState(() => _difficulty = 'easy'),
                          ),
                          _DifficultyTile(
                            label: 'Medium',
                            selected: _difficulty == 'medium',
                            onTap: () => setState(() => _difficulty = 'medium'),
                          ),
                          _DifficultyTile(
                            label: 'Hard',
                            selected: _difficulty == 'hard',
                            onTap: () => setState(() => _difficulty = 'hard'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: AppTheme.buttonHeight,
                      child: FilledButton(
                        onPressed: _role != null && _difficulty != null
                            ? () async {
                                await OnlineSessionPrefs.setPlayerName(_humanName);
                                if (!context.mounted) return;
                                widget.onStartGame(
                                  _role!,
                                  _difficulty!,
                                  _humanName,
                                );
                              }
                            : null,
                        child: const Text('Start AI Game'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primary,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppTheme.textOnDark),
          ),
          Text(
            'Play with AI',
            style: AppTheme.text(size: 20, weight: FontWeight.w600, color: AppTheme.textOnDark),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardWhite,
      elevation: 4,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.text(size: 20, weight: FontWeight.bold, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.asset,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
            width: selected ? 3 : 1,
          ),
          color: selected ? AppTheme.primaryLightBackground : Colors.white,
        ),
        child: Column(
          children: [
            Image.asset(asset, height: 48, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.text(size: 14, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: AppTheme.text(size: 16, weight: FontWeight.w600)),
      trailing: selected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
      onTap: onTap,
    );
  }
}
