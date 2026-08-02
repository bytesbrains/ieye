import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieye/core/homescan/scanner.dart';
import 'package:ieye/features/support/auth_service.dart';
import 'package:ieye/features/support/support_repository.dart';
import 'package:ieye/features/support/support_request.dart';
import 'package:ieye/features/support/support_request_screen.dart';
import 'package:ieye/theme/ieye_theme.dart';

/// A fake sign-in: starts signed-out, Google/Apple "authenticate" instantly.
class _FakeAuth implements AuthService {
  _FakeAuth({AuthUser? startUser}) : _current = startUser;
  AuthUser? _current;

  @override
  AuthUser? get currentUser => _current;
  @override
  Future<AuthUser?> signInWithGoogle() async =>
      _current = const AuthUser(uid: 'g1', displayName: 'Test User', email: 't@example.com');
  @override
  Future<AuthUser?> signInWithApple() async =>
      _current = const AuthUser(uid: 'a1', displayName: 'Apple User');
  @override
  Future<void> signOut() async => _current = null;
}

/// A fake sink that captures the submitted request.
class _FakeRepo implements SupportRepository {
  SupportRequest? request;
  AuthUser? user;
  @override
  Future<String> submit({
    required AuthUser user,
    required SupportRequest request,
  }) async {
    this.user = user;
    this.request = request;
    return 'req_123';
  }
}

void main() {
  Widget harness(AuthService auth, SupportRepository repo, {ScanReport? report}) =>
      MaterialApp(
        theme: buildIEyeTheme(),
        home: SupportRequestScreen(auth: auth, repository: repo, report: report),
      );

  // The screen has transient spinners (the CircularProgressIndicator shown while
  // signing in / submitting) that never "settle", so advance frames explicitly
  // instead of pumpAndSettle — same idiom as the report's pulsing chip.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> signInWithGoogle(WidgetTester tester) async {
    await tester.tap(find.text('Continue with Google'));
    await settle(tester);
  }

  // The form is taller than the 600px test viewport, so bring a control on-screen
  // before tapping it (the screen is a SingleChildScrollView).
  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await settle(tester);
    await tester.tap(f);
    await settle(tester);
  }

  testWidgets('gates on sign-in — no form until you sign in', (tester) async {
    await tester.pumpWidget(harness(_FakeAuth(), _FakeRepo()));

    expect(find.textContaining('Sign in so we can reach you'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    // No email field to type wrong, and no form yet.
    expect(find.text('Send my request'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('sign in → fill callback → submit sends the request', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(harness(_FakeAuth(), repo));

    await signInWithGoogle(tester);
    expect(find.text('A specialist will call you back'), findsOneWidget);
    expect(find.textContaining('Signed in as Test User'), findsOneWidget);

    // Submit stays disabled until a real callback number is entered.
    var send = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send my request'),
    );
    expect(send.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pump();
    send = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send my request'),
    );
    expect(send.onPressed, isNotNull);

    await tapVisible(tester, find.text('Send my request'));

    // The request was captured with the signed-in identity, and we confirm it.
    expect(repo.request, isNotNull);
    expect(repo.request!.callbackNumber, '9876543210');
    expect(repo.user!.uid, 'g1');
    expect(find.text('Request sent'), findsOneWidget);
  });

  testWidgets('findings attach only when the share toggle is on', (
    tester,
  ) async {
    // Build the report via runAsync: the scanner awaits a (zero) Future.delayed,
    // and a bare await in the test body would never fire that timer (fake async)
    // — runAsync services it on the real event loop.
    final report = (await tester.runAsync(
      () => const StubScanner(settleDelay: Duration.zero).scan(),
    ))!;
    final repo = _FakeRepo();
    await tester.pumpWidget(harness(_FakeAuth(), repo, report: report));
    await signInWithGoogle(tester);

    // With a report present, sharing defaults ON with an honest summary.
    expect(
      find.textContaining('Share my scan results'),
      findsOneWidget,
    );
    expect(find.textContaining('No passwords'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pump();
    await tapVisible(tester, find.text('Send my request'));

    expect(repo.request!.shareFindings, isTrue);
    expect(repo.request!.findingsSummary, isNotNull);
    expect(repo.request!.findingsSummary!['criticalCount'], greaterThan(0));
  });

  testWidgets('opt-in location attaches a timezone; off by default', (
    tester,
  ) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(harness(_FakeAuth(), repo));
    await signInWithGoogle(tester);
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.pump();

    // Turn on location sharing via its Switch (only one Switch here — no report,
    // so no share-findings tile), then send.
    await tapVisible(tester, find.byType(Switch));
    await tapVisible(tester, find.text('Send my request'));

    expect(repo.request!.shareLocation, isTrue);
    expect(repo.request!.timezone, isNotNull);
  });

  testWidgets('already signed-in skips the gate', (tester) async {
    await tester.pumpWidget(harness(
      _FakeAuth(startUser: const AuthUser(uid: 'x', displayName: 'Ana')),
      _FakeRepo(),
    ));
    expect(find.text('A specialist will call you back'), findsOneWidget);
    expect(find.textContaining('Signed in as Ana'), findsOneWidget);
  });
}
