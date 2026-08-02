import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieye/app.dart';
import 'package:ieye/core/checker.dart';
import 'package:ieye/core/trigger_sink.dart';
import 'package:ieye/core/welfare_signal.dart';
import 'package:ieye/features/checker/checker_invite_screen.dart';

/// Shared E2E helpers. Keep finders + flows here so each new feature test reads
/// like prose and we don't duplicate brittle lookups as the app grows. Add a
/// finder/robot here whenever you add a screen, then write the flow in app_test.

/// A delivery boundary that CAN reach off-device. Sensing/circle tests inject it
/// so the watching happy-path is reachable — otherwise the real no-op sink would
/// honestly degrade coverage (#27) and mask the thing under test. Fires nothing.
class ReachSink implements TriggerSink {
  @override
  String get name => 'Reaching (test)';
  @override
  bool get sendsOffDevice => true;
  @override
  Future<void> fire(WelfareSignal signal) async {}
}

/// Boot the real app and let it settle.
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const IEyeApp());
  await tester.pumpAndSettle();
}

// ---- onboarding ----
// Front foot: iEye Secure (the home scan). The welfare roles sit below it now.
final scanMyHome = find.text('Scan my home');
final forMyself = find.text('Set up iEye for myself');
final forSomeone = find.text('Set up iEye for someone I care about');
final brandLogo = find.image(const AssetImage('assets/ieye-appicon.png'));

// ---- home (honest coverage) ----
final watchingHeadline = find.text('Watching over you.');
// The honest degraded headline. The real prototype signs nothing / sends nothing
// off-device, so its delivery boundary (LocalNoopSink) can't reach anyone — the
// home tells that truth instead of a fake watching all-clear (#27).
final degradedHeadline = find.textContaining('you should know something');
// The reach gap, surfaced through the TriggerSink boundary (#27): no alert can
// leave the phone yet, so no one would be told — said plainly, never hidden.
final reachGapNote = find.textContaining('no alert would go out');
final lastSignOfLife = find.textContaining('Last sign of life');
final peopleWatching = find.textContaining('watching');
final goingDarkButton = find.textContaining('going dark');
final resumeButton = find.textContaining('resume watching');
final pausedHeadline = find.textContaining('Paused');
// Over-trust guardrail (PRD §7): this word must NEVER appear on the home screen.
final fakeProtectedShield = find.textContaining('protected');

// ---- comprehension gate before arming (#25) ----
final gravityGate = find.textContaining('Slow down');
final foundNotRescued = find.textContaining('doesn’t save you');
final microCheck = find.textContaining('finds me, it doesn’t save me');
final armButton = find.text('Start watching over me');

/// From onboarding, pick a role and pass through the comprehension gate (ack the
/// "found, not rescued" micro-check, then arm) to reach the home.
Future<void> goToHomeAsMyself(WidgetTester tester) async {
  // The welfare roles now sit below the iEye Secure hero, so scroll into view.
  await tester.ensureVisible(forMyself);
  await tester.pumpAndSettle();
  await tester.tap(forMyself);
  await tester.pumpAndSettle();
  await passComprehensionGate(tester);
}

/// Acknowledge the "found, not rescued" micro-check and arm. The gate scrolls, so
/// bring controls on-screen before tapping.
Future<void> passComprehensionGate(WidgetTester tester) async {
  await tester.ensureVisible(microCheck);
  await tester.pumpAndSettle();
  await tester.tap(microCheck); // acknowledge "found, not rescued"
  await tester.pumpAndSettle();
  await tester.ensureVisible(armButton);
  await tester.pumpAndSettle();
  await tester.tap(armButton); // no arm without the ack
  await tester.pumpAndSettle();
}

// ---- checker consent handshake (#17) ----

/// Captures the consent produced by the handshake, for assertions.
CheckerConsent? lastCheckerConsent;

/// Pump the checker invite screen standalone (checkers arrive via a link).
Future<void> pumpCheckerInvite(
  WidgetTester tester, {
  String owner = 'Sandeep',
}) async {
  lastCheckerConsent = null;
  await tester.pumpWidget(
    MaterialApp(
      home: CheckerInviteScreen(
        invite: CheckerInvite(ownerName: owner),
        onAccepted: (c) => lastCheckerConsent = c,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final inviteExpectation = find.textContaining(
  'contacted if their phone goes silent',
);
// Scoped to the accept *button* — the expectation paragraph also contains
// "be one of …", so match the button's unique "Yes, I…" opener instead.
final acceptInvite = find.textContaining('Yes, I');
final declineInvite = find.textContaining('right now'); // "I can't right now"
final reachInPerson = find.text('I can go check in person');
final reachCallOnly = find.text('I can call or message');
final continueButton = find.text('Continue');
final practiceBadge = find.text('PRACTICE');
final seenDrill = find.textContaining('seen the drill');
final handshakeDone = find.textContaining(
  'people now',
); // "…one of X's people now."
final declinedHeadline = find.textContaining('No problem');
