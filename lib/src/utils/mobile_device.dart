import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Phones and tablets (Android / iOS) only.
bool get isMobileOrTablet {
  if (kIsWeb) {
    return false;
  }
  return Platform.isAndroid || Platform.isIOS;
}

Future<void> configureForMobileAndTablet() async {
  if (!isMobileOrTablet) {
    return;
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

/// Shown when the app is opened on desktop or web.
class MobileOnlyGate extends StatelessWidget {
  const MobileOnlyGate({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.phone_android, size: 64, color: Colors.brown.shade400),
                const SizedBox(height: 24),
                const Text(
                  'Puli Meka',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This app is available on Android and iOS phones and tablets only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
