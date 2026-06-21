// On-device UI E2E for the iEye app. Drives the real app on a simulator/device,
// in Dart — no AppleScript, no screenshot-poking. This is the running harness we
// extend as we build: add a flow here whenever a UI feature lands.
//
// Run:  flutter test integration_test -d <device-id>
//
// Each test asserts a *product guardrail*, not just "the screen rendered" —
// e.g. honest coverage (no fake green shield), going-dark tells the circle, etc.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'finders.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('onboarding', () {
    testWidgets('shows the brand mark and both setup roles (buyer ≠ watched)', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(brandLogo, findsOneWidget); // the real brand asset renders
      expect(forMyself, findsOneWidget);
      expect(forSomeone, findsOneWidget);
    });
  });

  group('watched flow — honest coverage', () {
    testWidgets('"for myself" lands on an honest home, never a green shield', (
      tester,
    ) async {
      await pumpApp(tester);
      await goToHomeAsMyself(tester);

      // The prototype can sense but can't yet reach anyone off-device, so the
      // honest home degrades and SAYS no alert would go out — never a watching
      // all-clear no one would hear (#27, read through the TriggerSink boundary).
      expect(degradedHeadline, findsWidgets);
      expect(reachGapNote, findsWidgets);
      expect(watchingHeadline, findsNothing); // no fake watching all-clear
      expect(lastSignOfLife, findsOneWidget);
      expect(peopleWatching, findsWidgets);
      expect(
        fakeProtectedShield,
        findsNothing,
      ); // over-trust guardrail (PRD §7)
    });

    testWidgets('a role cannot bypass the comprehension gate', (tester) async {
      await pumpApp(tester);
      await tester.tap(forMyself);
      await tester.pumpAndSettle();

      // Over-trust is risk #1: arming MUST go through the gate, never straight home.
      expect(gravityGate, findsOneWidget);
      expect(watchingHeadline, findsNothing);
    });
  });

  group('going dark (the biggest alarm-fatigue killer)', () {
    testWidgets('pauses the watch, then resumes', (tester) async {
      await pumpApp(tester);
      await goToHomeAsMyself(tester);

      await tester.tap(goingDarkButton);
      await tester.pumpAndSettle();
      expect(pausedHeadline, findsWidgets);
      expect(resumeButton, findsOneWidget);

      await tester.tap(resumeButton);
      await tester.pumpAndSettle();
      // Resuming returns to the honest pre-pause state — degraded, because the
      // prototype still can't reach off-device; never a fake watching all-clear.
      expect(degradedHeadline, findsWidgets);
      expect(pausedHeadline, findsNothing);
    });
  });

  group('caregiver flow', () {
    testWidgets('"for someone I care about" goes through the gate to home', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(forSomeone);
      await tester.pumpAndSettle();

      // Both roles must pass the comprehension gate before arming (#25).
      expect(gravityGate, findsOneWidget);
      await passComprehensionGate(tester);

      // Lands on the honest home (degraded — no off-device reach yet, #27).
      expect(degradedHeadline, findsWidgets);
    });
  });
}
