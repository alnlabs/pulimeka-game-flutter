import 'dart:async';

import 'package:flutter/material.dart';

import '../models/hint_policy.dart';
import '../services/ad_config.dart';
import '../services/interstitial_ad_manager.dart';
import '../theme/app_theme.dart';

/// Full-screen ad slot: interstitial or countdown + Skip.
class TimedAdOverlay extends StatefulWidget {
  const TimedAdOverlay({
    required this.onComplete,
    this.skipSeconds,
    this.title,
    this.subtitle,
    super.key,
  });

  final VoidCallback onComplete;

  /// Defaults to [HintPolicy.timedAdSkipSeconds] (hint unlock).
  final int? skipSeconds;
  final String? title;
  final String? subtitle;

  @override
  State<TimedAdOverlay> createState() => _TimedAdOverlayState();
}

class _TimedAdOverlayState extends State<TimedAdOverlay> {
  late int _countdown;
  bool _showSkip = false;
  bool _dismissed = false;

  int get _skipDelay =>
      widget.skipSeconds ?? HintPolicy.timedAdSkipSeconds;

  @override
  void initState() {
    super.initState();
    _countdown = _skipDelay;
    _start();
  }

  Future<void> _start() async {
    if (!AdConfig.shouldShowAds) {
      widget.onComplete();
      return;
    }

    if (AdConfig.shouldLoadAds) {
      final shown = await InterstitialAdManager.instance.show();
      if (shown && mounted) {
        widget.onComplete();
        return;
      }
    }

    if (!mounted) {
      return;
    }

    for (var i = _skipDelay; i >= 1; i--) {
      if (!mounted || _dismissed) {
        return;
      }
      setState(() => _countdown = i);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (mounted) {
      setState(() => _showSkip = true);
    }
  }

  void _finish() {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        (AdConfig.shouldRequestLiveAds ? 'Thanks for playing!' : 'Ad preview');
    final subtitle = widget.subtitle ??
        (_showSkip ? 'Tap Skip to continue' : 'Please wait…');

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📺', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTheme.text(
                        size: 22,
                        weight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.text(size: 16, color: Colors.white70),
                    ),
                    if (!_showSkip) ...[
                      const SizedBox(height: 24),
                      Text(
                        '$_countdown',
                        style: AppTheme.text(
                          size: 36,
                          weight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_showSkip)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Skip'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
