import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The signed-in person, reduced to what a support request needs. We never ask the
/// user to type an email — a verified identity from Google/Apple is both easier
/// (no password to remember) and more trustworthy (no typo'd address to chase).
class AuthUser {
  const AuthUser({required this.uid, this.displayName, this.email});
  final String uid;
  final String? displayName;
  final String? email;
}

/// Sign-in for iEye Secure's support flow. Behind an interface so the screen is
/// testable with a fake and the real Firebase-backed implementation drops in
/// unchanged (the same pattern as the scan's WifiSource/MdnsSource).
abstract interface class AuthService {
  /// The already-signed-in user, or null. (Firebase persists the session.)
  AuthUser? get currentUser;

  /// Both sign-ins resolve to null when the user backs out — a cancel is a
  /// choice, not a failure, so callers shouldn't show an error for it.
  Future<AuthUser?> signInWithGoogle();
  Future<AuthUser?> signInWithApple();
  Future<void> signOut();
}

/// The real implementation: Google / Apple → a Firebase credential → a Firebase
/// session. Constructed only when the support screen is reached, so it's never
/// touched in tests (which inject a fake) and needs Firebase initialised (main()).
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  AuthUser? _map(fb.User? u) => u == null
      ? null
      : AuthUser(uid: u.uid, displayName: u.displayName, email: u.email);

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AuthUser?> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    // Provider config (a serverClientId for a Firebase-audience idToken, the iOS
    // URL scheme, the Android SHA-1) is set up in the Firebase console — see the
    // PR's setup notes. initialize() is idempotent.
    await google.initialize();
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    return _map(result.user);
  }

  /// A one-shot random nonce for Sign in with Apple: its SHA-256 goes into the
  /// Apple request, the raw value into the Firebase credential. Firebase checks
  /// they match, so a stolen Apple idToken can't be replayed against our project.
  static String _rawNonce() {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(32, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  @override
  Future<AuthUser?> signInWithApple() async {
    final rawNonce = _rawNonce();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
    final oauth = fb.OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
      accessToken: apple.authorizationCode,
    );
    final result = await _auth.signInWithCredential(oauth);
    // Apple returns the name only on the first authorisation — capture it then.
    final name = [apple.givenName, apple.familyName]
        .whereType<String>()
        .join(' ')
        .trim();
    if (name.isNotEmpty && (result.user?.displayName ?? '').isEmpty) {
      await result.user?.updateDisplayName(name);
    }
    return _map(_auth.currentUser);
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
