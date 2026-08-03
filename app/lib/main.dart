import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/platform_support.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // iEye Secure's specialist requests (and later, Easy-mode delivery) ride on
  // Firebase. Liveness telemetry never does — that stays on-device (CLAUDE.md).
  // Only configured for mobile + macOS; on Linux/Windows the app runs scan-only,
  // so skip init there rather than crash on an unconfigured platform.
  if (firebaseConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const IEyeApp());
}
