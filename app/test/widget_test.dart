import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ieye/app.dart';
import 'package:ieye/core/checker.dart';
import 'package:ieye/core/detection_brain.dart';
import 'package:ieye/core/trigger_sink.dart';
import 'package:ieye/core/welfare_signal.dart';
import 'package:ieye/features/home/home_screen.dart';

void main() {
  testWidgets('onboarding offers both roles (buyer ≠ watched)', (tester) async {
    await tester.pumpWidget(const IEyeApp());

    expect(find.text('Set up iEye for myself'), findsOneWidget);
    expect(find.text('Set up iEye for someone I care about'), findsOneWidget);
  });

  testWidgets('home shows honest coverage, never a green "protected" shield', (
    tester,
  ) async {
    final brain = Tier0StubBrain();
    addTearDown(brain.dispose);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(brain: brain)));
    await tester.pumpAndSettle();

    expect(find.text('Watching over you.'), findsOneWidget);
    expect(find.textContaining('Last sign of life'), findsOneWidget);
    // Over-trust guardrail (PRD §7): we never claim "protected".
    expect(find.textContaining('protected'), findsNothing);
  });

  testWidgets('going dark pauses the watch and says it is planned', (
    tester,
  ) async {
    final brain = Tier0StubBrain();
    addTearDown(brain.dispose);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(brain: brain)));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('going dark'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Paused'), findsWidgets);
    expect(find.textContaining('resume watching'), findsOneWidget);
  });

  test('the local sink signs nothing / sends nothing off-device', () async {
    final sink = LocalNoopSink();
    expect(sink.sendsOffDevice, isFalse);

    await sink.fire(WelfareSignal.silence(rung: EscalationRung.circle));
    expect(sink.fired, hasLength(1));
  });

  test(
    'a welfare signal cannot carry an address below the physical-check rung',
    () {
      // Structural guard: the address note is dropped unless it is the physical-
      // check rung (and even then it is benign + opt-in, never a secret/will).
      final early = WelfareSignal.silence(
        rung: EscalationRung.circle,
        addressNote: 'should be ignored',
      );
      expect(early.addressNote, isNull);

      final atDoor = WelfareSignal.silence(
        rung: EscalationRung.physicalCheck,
        addressNote: 'side gate',
      );
      expect(atDoor.addressNote, 'side gate');
    },
  );

  group('checker consent (#17 — no silent enrolment)', () {
    test('is active only after accept + availability + rehearsal', () {
      const noAccept = CheckerConsent(
        accepted: false,
        reach: CheckerReach.canGoInPerson,
        rehearsalCompleted: true,
      );
      const noReach = CheckerConsent(
        accepted: true,
        reach: null,
        rehearsalCompleted: true,
      );
      const noRehearsal = CheckerConsent(
        accepted: true,
        reach: CheckerReach.callOnly,
        rehearsalCompleted: false,
      );
      expect(noAccept.isActive, isFalse);
      expect(noReach.isActive, isFalse);
      expect(noRehearsal.isActive, isFalse);

      const full = CheckerConsent(
        accepted: true,
        reach: CheckerReach.callOnly,
        rehearsalCompleted: true,
      );
      expect(full.isActive, isTrue);
    });

    test(
      'only an in-person checker is eligible for the physical-check rung',
      () {
        const inPerson = CheckerConsent(
          accepted: true,
          reach: CheckerReach.canGoInPerson,
          rehearsalCompleted: true,
        );
        const callOnly = CheckerConsent(
          accepted: true,
          reach: CheckerReach.callOnly,
          rehearsalCompleted: true,
        );
        expect(inPerson.eligibleForPhysicalCheck, isTrue);
        expect(callOnly.eligibleForPhysicalCheck, isFalse);
      },
    );
  });
}
