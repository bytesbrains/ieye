import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ieye/app.dart';
import 'package:ieye/core/checker.dart';
import 'package:ieye/core/circle.dart';
import 'package:ieye/core/coverage.dart';
import 'package:ieye/core/delivery_mode.dart';
import 'package:ieye/core/detection_brain.dart';
import 'package:ieye/core/phone_signals.dart';
import 'package:ieye/core/tier0_detector.dart';
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
    final brain = Tier0Brain();
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
    final brain = Tier0Brain();
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

  group('circle coverage (#18 — no silent gaps)', () {
    test(
      'the demo circle is safe (≥2 checkers, ≥1 within driving distance)',
      () {
        final c = Circle(demoCircleMembers());
        expect(c.total, 3);
        expect(c.canReachFastCount, 1);
        expect(c.isSafe, isTrue);
        expect(c.coverageNote, isNull);
        // Ordered nearest-first.
        expect(c.byProximity.map((m) => m.name).toList(), [
          'Maria',
          'Tom',
          'Priya',
        ]);
      },
    );

    test('losing the only in-person checker surfaces an honest gap', () {
      final store = CircleStore(demoCircleMembers());
      store.resign('maria'); // the only canGoInPerson member
      final c = store.circle;
      expect(c.total, 2);
      expect(c.canReachFastCount, 0);
      expect(c.isSafe, isFalse);
      expect(c.coverageNote, contains('no one close enough to come over'));
    });

    test('a lone checker is unsafe even if they can reach fast', () {
      final c = Circle(const [
        CircleMember(
          id: 'solo',
          name: 'Solo',
          reach: CheckerReach.canGoInPerson,
          proximity: Proximity.nearby,
        ),
      ]);
      expect(c.isSafe, isFalse);
      expect(c.coverageNote, contains('just one checker'));
    });

    test('an empty circle is never silent', () {
      const c = Circle([]);
      expect(c.isSafe, isFalse);
      expect(c.coverageNote, contains('No one is watching'));
    });

    test('resignation can be undone (graceful exit)', () {
      final store = CircleStore(demoCircleMembers());
      store.resign('tom');
      expect(store.circle.total, 2);
      expect(store.canUndo, isTrue);
      store.undoLastResign();
      expect(store.circle.total, 3);
      expect(store.canUndo, isFalse);
    });

    test('undo restores a member at its original position (no reordering)', () {
      final store = CircleStore(demoCircleMembers()); // maria, tom, priya
      store.resign('tom'); // the middle one
      expect(store.circle.members.map((m) => m.id), ['maria', 'priya']);
      store.undoLastResign();
      expect(store.circle.members.map((m) => m.id), ['maria', 'tom', 'priya']);
    });
  });

  group('tier-0 rhythm rule (#14 — honest phone-only limits)', () {
    const detector = Tier0Detector();
    final now = DateTime(2026, 6, 22, 12, 0);
    PhoneSignals sig({
      Duration since = const Duration(minutes: 5),
      int battery = 80,
      bool charging = false,
      bool reachable = true,
    }) => PhoneSignals(
      lastInteraction: now.subtract(since),
      batteryPercent: battery,
      charging: charging,
      reachable: reachable,
    );

    test('recent interaction + healthy battery → watching, no caveat', () {
      final a = detector.assess(sig(), now);
      expect(a.status, SensingStatus.watching);
      expect(a.isHealthy, isTrue);
      expect(a.limitNote, isNull);
    });

    test(
      'an unreachable phone is NOT an all-clear (dead-phone blind spot)',
      () {
        final a = detector.assess(sig(reachable: false), now);
        expect(a.status, SensingStatus.lostContact);
        expect(a.limitNote, contains('promise you'));
      },
    );

    test('silence beyond the window is a concern', () {
      final a = detector.assess(sig(since: const Duration(hours: 15)), now);
      expect(a.status, SensingStatus.silenceConcern);
    });

    test('silence boundary: exactly at the window counts as concern', () {
      expect(
        detector.assess(sig(since: const Duration(hours: 14)), now).status,
        SensingStatus.silenceConcern,
      );
      expect(
        detector
            .assess(sig(since: const Duration(hours: 13, minutes: 59)), now)
            .status,
        SensingStatus.watching,
      );
    });

    test('low battery is surfaced pre-emptively, unless charging', () {
      expect(
        detector.assess(sig(battery: 10), now).status,
        SensingStatus.batteryLow,
      );
      expect(
        detector.assess(sig(battery: 10, charging: true), now).status,
        SensingStatus.watching,
      );
    });

    test('battery boundary: == threshold is low, one above is fine', () {
      expect(
        detector.assess(sig(battery: 20), now).status,
        SensingStatus.batteryLow,
      );
      expect(
        detector.assess(sig(battery: 21), now).status,
        SensingStatus.watching,
      );
    });

    test('lost contact dominates low battery', () {
      final a = detector.assess(sig(battery: 5, reachable: false), now);
      expect(a.status, SensingStatus.lostContact);
    });
  });

  group('delivery-mode honest promise (#25)', () {
    test('Easy promises reach + server-dependency, never "inevitable"', () {
      final easy = DeliveryMode.easy.honestPromise;
      expect(easy.toLowerCase(), contains('servers'));
      expect(easy.toLowerCase(), isNot(contains('inevitable')));
    });

    test('Sovereign states the on-chain reality', () {
      expect(
        DeliveryMode.sovereign.honestPromise,
        contains('public and permanent'),
      );
    });
  });

  group('Tier0Brain composition (#14)', () {
    PhoneSignals sig({
      Duration since = const Duration(minutes: 5),
      int battery = 80,
      bool reachable = true,
    }) => PhoneSignals(
      lastInteraction: DateTime(2026, 6, 22, 12, 0).subtract(since),
      batteryPercent: battery,
      charging: false,
      reachable: reachable,
    );
    DateTime fixedNow() => DateTime(2026, 6, 22, 12, 0);

    test('an injected clock drives the silence path deterministically', () {
      final signals = StubPhoneSignalsSource(
        sig(since: const Duration(hours: 20)),
      );
      final circle = CircleStore(demoCircleMembers());
      addTearDown(signals.dispose);
      addTearDown(circle.dispose);
      final brain = Tier0Brain(signals: signals, circle: circle, now: fixedNow);
      addTearDown(brain.dispose);

      expect(brain.current.status, CoverageStatus.degraded);
      expect(
        brain.current.note,
        contains('reaching the people watching over you'),
      );
    });

    test('re-emits coverage on a signals change AND a circle change', () async {
      final signals = StubPhoneSignalsSource(sig());
      final circle = CircleStore(demoCircleMembers());
      addTearDown(signals.dispose);
      addTearDown(circle.dispose);
      final brain = Tier0Brain(signals: signals, circle: circle, now: fixedNow);
      addTearDown(brain.dispose);

      final seen = <CoverageStatus>[];
      final sub = brain.coverage.listen((s) => seen.add(s.status));
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero); // initial replay

      signals.update(sig(battery: 5)); // sensing degrades
      circle.resign('maria'); // circle degrades
      await Future<void>.delayed(Duration.zero);

      expect(seen.first, CoverageStatus.watching);
      expect(seen.where((s) => s == CoverageStatus.degraded), isNotEmpty);
      expect(seen.length, greaterThanOrEqualTo(3)); // initial + 2 changes
    });
  });
}
