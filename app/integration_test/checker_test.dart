// On-device E2E for the checker consent handshake (#17). Drives the real wizard
// and asserts the product guardrails: active accept (no silent enrolment),
// availability the ladder respects, and a completed rehearsal before "active".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'finders.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('checker consent handshake', () {
    testWidgets('full accept (can go in person) → active + rung-4 eligible', (
      tester,
    ) async {
      await pumpCheckerInvite(tester);

      // Step 1 — the plain expectation is shown; nothing accepted yet.
      expect(inviteExpectation, findsOneWidget);
      expect(lastCheckerConsent, isNull);

      await tester.tap(acceptInvite);
      await tester.pumpAndSettle();

      // Step 2 — choose availability.
      await tester.tap(reachInPerson);
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Step 3 — a real-looking practice alert, then acknowledge.
      expect(practiceBadge, findsOneWidget);
      await tester.tap(seenDrill);
      await tester.pumpAndSettle();

      // Step 4 — done, with a clear exit (no dead-end), and active + eligible.
      expect(handshakeDone, findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(lastCheckerConsent, isNotNull);
      expect(lastCheckerConsent!.isActive, isTrue);
      expect(lastCheckerConsent!.eligibleForPhysicalCheck, isTrue);
    });

    testWidgets('can step back to re-read the invite before committing',
        (tester) async {
      await pumpCheckerInvite(tester);
      await tester.tap(acceptInvite);
      await tester.pumpAndSettle();
      expect(reachInPerson, findsOneWidget); // on availability

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(inviteExpectation, findsOneWidget); // back on the invite
      expect(lastCheckerConsent, isNull); // nothing committed
    });

    testWidgets('call-only checker is active but NOT sent to the door', (
      tester,
    ) async {
      await pumpCheckerInvite(tester);
      await tester.tap(acceptInvite);
      await tester.pumpAndSettle();

      await tester.tap(reachCallOnly);
      await tester.pumpAndSettle();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      await tester.tap(seenDrill);
      await tester.pumpAndSettle();

      expect(lastCheckerConsent!.isActive, isTrue);
      expect(lastCheckerConsent!.eligibleForPhysicalCheck, isFalse);
    });

    testWidgets(
      'no silent enrolment — Continue is disabled until availability is chosen',
      (tester) async {
        await pumpCheckerInvite(tester);
        await tester.tap(acceptInvite);
        await tester.pumpAndSettle();

        // On the availability step, Continue is disabled (onPressed == null)
        // until the checker makes a choice — they cannot be swept to "active".
        final disabled = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(disabled.onPressed, isNull);
        expect(reachInPerson, findsOneWidget); // still on availability
        expect(practiceBadge, findsNothing); // rehearsal not reached

        // Choosing a reach enables Continue.
        await tester.tap(reachCallOnly);
        await tester.pumpAndSettle();
        final enabled = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(enabled.onPressed, isNotNull);
      },
    );

    testWidgets('decline path leaves no active consent', (tester) async {
      await pumpCheckerInvite(tester);
      await tester.tap(declineInvite);
      await tester.pumpAndSettle();

      expect(declinedHeadline, findsOneWidget);
      expect(lastCheckerConsent, isNull);
    });
  });
}
