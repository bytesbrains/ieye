import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// True only on the platforms flutterfire generated Firebase options for
/// (Android / iOS / macOS). On Linux and Windows the app runs **scan-only**: the
/// home/car scan is pure `dart:io` and needs no backend, but the specialist-
/// request flow (Firebase auth + Firestore) isn't available there.
///
/// Used to (a) skip `Firebase.initializeApp` on desktop so startup doesn't crash
/// on an unconfigured platform, and (b) route the specialist CTA to a friendly
/// "use the phone/Mac app" screen instead of constructing Firebase there.
bool get firebaseConfigured =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
