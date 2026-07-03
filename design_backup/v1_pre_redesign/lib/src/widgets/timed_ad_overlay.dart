import 'dart:async';

import 'package:flutter/material.dart';

import '../models/hint_policy.dart';
import '../services/ad_config.dart';
import '../services/interstitial_ad_manager.dart';
import '../theme/app_theme.dart';

/// Timed full-screen slot: tries interstitial, else placeholder with countdown + Skip.
class TimedAdOverlay extends StatefulWidget {
  const TimedAdOverlay({
    required this.onComplete,
    super.key,
  });

  final VoidCallback onComplete;

  @override
  State<TimedAdOverlay> createState() => _TimedAdOverlayState();
}

class _TimedAdOverlayState extends State<TimedAdOverlay> {
  int _countdown = HintPolicy.timedAdSkipSeconds;
  bool _showSkip = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!AdConfig.shouldShowAds) {
      widget.onComplete();
      return;
    }

    if (AdConfig.shouldRequestLiveAds) {
      final shown = await InterstitialAdManager.instance.show();
      if (shown && mounted) {
        widget.onComplete();
        return;
      }
    }

    if (!mounted) {
      return;
    }

    for (var i = HintPolicy.timedAdSkipSeconds; i >= 1; i--) {
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
                      AdConfig.shouldRequestLiveAds
                          ? 'Sponsored message'
                          : 'Ad preview',
                      style: AppTheme.text(
                        size: 22,
                        weight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showSkip
                          ? 'Tap Skip to get your hint'
                          : 'Please wait…',
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
