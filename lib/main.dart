import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'src/app.dart';
import 'src/services/ad_service.dart';
import 'src/services/hint_service.dart';
import 'src/services/sound_service.dart';
import 'src/utils/mobile_device.dart';
export 'src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!isMobileOrTablet) {
    runApp(const MobileOnlyGate());
    return;
  }

  runZonedGuarded(
    () async {
      try {
        await configureForMobileAndTablet();
        await _initializeFirebase();
        await HintService.instance.ensureFirstPlayRecorded();
        await SoundService.instance.loadFromPrefs();
        try {
          await AdService.initialize();
        } catch (e, stack) {
          debugPrint('Ads unavailable at startup: $e\n$stack');
        }
        runApp(const PuliMekaApp());
      } catch (e, stack) {
        debugPrint('Startup failed: $e\n$stack');
        runApp(_StartupErrorApp(message: e.toString()));
      }
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
      runApp(_StartupErrorApp(message: error.toString()));
    },
  );
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// Shown when Firebase or other startup code fails (avoids blank white screen).
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Puli Meka could not start',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(message),
                const SizedBox(height: 24),
                const Text(
                  'Try: delete the app from your phone, then run flutter clean, flutter pub get, cd ios && pod install, flutter run',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
