import 'package:flutter/material.dart';

import '../services/sound_prefs.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import 'about_screen.dart';
import 'profile_screen.dart';
import 'how_to_play_screen.dart';
import 'tutorial_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await SoundPrefs.isEnabled();
    final vol = await SoundPrefs.volume();
    if (mounted) {
      setState(() {
        _soundEnabled = enabled;
        _volume = vol;
      });
    }
  }

  Future<void> _setSound(bool value) async {
    await SoundPrefs.setEnabled(value);
    SoundService.instance.enabled = value;
    setState(() => _soundEnabled = value);
  }

  Future<void> _setVolume(double value) async {
    await SoundPrefs.setVolume(value);
    await SoundService.instance.updateVolume(value);
    setState(() => _volume = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnDark,
      ),
      bottomNavigationBar: const ScreenAdBar(),
      body: SafeArea(
        child: ListView(
          children: [
            SwitchListTile(
              title: Text('Game sounds', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
              subtitle: Text(
                'Tap, move, and capture effects',
                style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
              ),
              value: _soundEnabled,
              activeColor: AppTheme.primary,
              onChanged: _setSound,
            ),
            ListTile(
              title: Text('Volume', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
              subtitle: Slider(
                value: _volume,
                onChanged: _soundEnabled ? _setVolume : null,
                activeColor: AppTheme.primary,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppTheme.primary),
              title: Text('Profile & hints', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
              subtitle: Text(
                'Started date, hint packs, and usage',
                style: AppTheme.text(size: 13, color: AppTheme.textSecondary),
              ),
              onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined, color: AppTheme.primary),
              title: Text('Visual Tutorial', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
              onTap: () => Navigator.pushNamed(context, TutorialScreen.routeName),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.school_outlined, color: AppTheme.primary),
              title: Text('How to Play', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
              onTap: () => Navigator.pushNamed(context, HowToPlayScreen.routeName),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primary),
              title: Text('About', style: AppTheme.text(size: 16, weight: FontWeight.w600)),
              onTap: () => Navigator.pushNamed(context, AboutScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}
