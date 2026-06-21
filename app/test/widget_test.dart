import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ieye/app.dart';
import 'package:ieye/core/checker.dart';
import 'package:ieye/core/circle.dart';
import 'package:ieye/core/coverage.dart';
import 'package:ieye/core/delivery_mode.dart';
import 'package:ieye/core/detection_brain.dart';
import 'package:ieye/core/liveness_source.dart';
import 'package:ieye/core/phone_signals.dart';
import 'package:ieye/core/tier0_detector.dart';
import 'package:ieye/core/trigger_sink.dart';
import 'package:ieye/core/welfare_signal.dart';
import 'package:ieye/features/home/home_screen.dart';

/// A delivery boundary that CAN reach off-device — stands in for a real Easy /
/// Sovereign sink so the watching happy-path is testable without the no-op sink
/// honestly degrading coverage. Fires nothing; only its [sendsOffDevice] matters.
class _ReachSink implements TriggerSink {
  @override
  String get name => 'Reaching (test)';
  @override
  bool get sendsOffDevice => true;
  @override
  Future<void> fire(WelfareSignal signal) async {}
}

/// A liveness source whose verdict the test sets directly — so the fusion brain
/// can be driven with N honest sources (phone + home + …) deterministically.
class _FixedSource extends LivenessSource {
  _FixedSource(this._a);
  LivenessAssessment _a;
  void set(LivenessAssessment a) {
    _a = a;
    notifyListeners();
  }

  @override
  String get label => _a.label;
  @override
  LivenessAssessment assess(DateTime now) => _a;
}

/// Build a [LivenessAssessment] tersely for fusion tests.
LivenessAssessment _verdict(
  LivenessStatus status, {
  DateTime? at,
  int? battery,
  String? note,
  String label = 'a sensor',
}) => LivenessAssessment(
  status: status,
  lastSignOfLife: at,
  batteryPercent: battery,
  limitNote: note,
  label: label,
);

void main() {
  testWidgets('onboarding offers both roles (buyer ≠ watched)', (tester) async {
    await tester.pumpWidget(const IEyeApp());

    expect(find.text('Set up iEye for myself'), findsOneWidget);
    expect(find.text('Set up iEye for someone I care about'), findsOneWidget);
  });

  testWidgets('home shows honest coverage, never a green "protected" shield', (
    tester,
  ) async {
    // A reaching sink + safe demo circle + healthy signals → the full watching
    // state, so we can assert that even at its most reassuring the home never
    // claims "protected".
    final brain = Tier0Brain(sink: _ReachSink());
    addTearDown(brain.dispose);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(brain: brain)));
    await tester.pumpAndSettle();

    expect(find.text('Watching over you.'), findsOneWidget);
    expect(find.textContaining('Last sign of life'), findsOneWidget);
    // Over-trust guardrail (PRD §7): we never claim "protected".
    expect(find.textContaining('protected'), findsNothing);
  });

  testWidgets(
    'home degrades honestly when no alert can leave the phone (#27)',
    (tester) async {
      // The signs-nothing prototype's real boundary: a no-op sink that can't
      // reach off-device. Sensing is fine, but no one would be told — so the home
      // must NOT show the watching all-clear; it degrades and says so.
      final brain = Tier0Brain(sink: LocalNoopSink());
      addTearDown(brain.dispose);

      await tester.pumpWidget(MaterialApp(home: HomeScreen(brain: brain)));
      await tester.pumpAndSettle();

      expect(find.text('Watching over you.'), findsNothing);
      expect(find.textContaining('you should know something'), findsOneWidget);
      // The reach truth is surfaced, not hidden — in the amber note AND the
      // limits section, so a sensing caveat can never bury it.
      expect(find.textContaining('no alert would go out'), findsOneWidget);
      expect(find.textContaining('can’t send an alert off this phone'),
          findsOneWidget);
      expect(find.textContaining('protected'), findsNothing);
    },
  );

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
      // Reaching sink so the degrade is unambiguously the sensing silence, not the
      // reach gap.
      final brain = Tier0Brain(
        signals: signals,
        circle: circle,
        sink: _ReachSink(),
        now: fixedNow,
      );
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
      final brain = Tier0Brain(
        signals: signals,
        circle: circle,
        sink: _ReachSink(),
        now: fixedNow,
      );
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

  group('honest reach — coverage through the delivery boundary (#27)', () {
    PhoneSignals healthy() => PhoneSignals(
      lastInteraction: DateTime(2026, 6, 22, 12, 0).subtract(
        const Duration(minutes: 5),
      ),
      batteryPercent: 80,
      charging: false,
      reachable: true,
    );
    DateTime fixedNow() => DateTime(2026, 6, 22, 12, 0);

    Tier0Brain brainWith(TriggerSink sink) {
      final signals = StubPhoneSignalsSource(healthy());
      final circle = CircleStore(demoCircleMembers()); // safe by default
      addTearDown(signals.dispose);
      addTearDown(circle.dispose);
      final brain = Tier0Brain(
        signals: signals,
        circle: circle,
        sink: sink,
        now: fixedNow,
      );
      addTearDown(brain.dispose);
      return brain;
    }

    test(
      'a no-off-device sink degrades even when sensing + circle are fine',
      () {
        final c = brainWith(LocalNoopSink()).current;
        // Sensing healthy, circle safe — yet no one could be told, so NOT a
        // watching all-clear. This is the structural anti-fake-green-shield rule.
        expect(c.canSummonHelp, isFalse);
        expect(c.status, CoverageStatus.degraded);
        expect(c.note, contains('no alert would go out'));
      },
    );

    test('a reaching sink with a safe circle is the full watching state', () {
      final c = brainWith(_ReachSink()).current;
      expect(c.canSummonHelp, isTrue);
      expect(c.status, CoverageStatus.watching);
      expect(c.note, isNull);
    });

    test('a sensing problem outranks the reach gap for the single note slot', () {
      // Lost contact (most urgent, act-now) wins the note even though reach is
      // also down — but the reach truth still rides along in canSummonHelp so the
      // UI can surface it separately and never hide it.
      final signals = StubPhoneSignalsSource(
        PhoneSignals(
          lastInteraction: fixedNow().subtract(const Duration(minutes: 5)),
          batteryPercent: 80,
          charging: false,
          reachable: false, // lost contact
        ),
      );
      final circle = CircleStore(demoCircleMembers());
      addTearDown(signals.dispose);
      addTearDown(circle.dispose);
      final brain = Tier0Brain(
        signals: signals,
        circle: circle,
        sink: LocalNoopSink(),
        now: fixedNow,
      );
      addTearDown(brain.dispose);

      final c = brain.current;
      expect(c.status, CoverageStatus.degraded);
      expect(c.note, contains('lost contact')); // sensing caveat wins the slot
      expect(c.canSummonHelp, isFalse); // reach truth not lost
    });
  });

  group('multi-source fusion rule (#62)', () {
    final t = DateTime(2026, 6, 22, 12, 0);

    test('corroboration suppresses the battery-death false alarm', () {
      // Phone battery is dead (lost contact) BUT the home still sees life. The
      // person is alive — so this must NOT escalate to a silence alarm; it
      // degrades to an honest heads-up with the home's fresh sign of life.
      final fused = fuseLiveness([
        _verdict(LivenessStatus.lostContact, battery: 0, label: 'your phone'),
        _verdict(LivenessStatus.alive, at: t, label: 'your home'),
      ]);
      expect(fused.status, LivenessStatus.degraded); // not silent / lostContact
      expect(fused.isAlive, isFalse); // still a heads-up, never a clean all-clear
      expect(fused.lastSignOfLife, t); // the living source's fresh sign
      expect(fused.limitNote, contains('isn’t an emergency'));
    });

    test('genuine multi-source silence escalates', () {
      // No source sees life — the real "go check" path. The most urgent signal
      // (lost contact) stands.
      final fused = fuseLiveness([
        _verdict(LivenessStatus.silent, at: t, label: 'your phone'),
        _verdict(LivenessStatus.lostContact, label: 'your home'),
      ]);
      expect(fused.corroboratesLife, isFalse);
      expect(fused.status, LivenessStatus.lostContact); // worst signal wins
    });

    test('any unhealthy source degrades — never a false alive', () {
      // One source alive, one battery-low: corroborated alive, but the caveat is
      // surfaced and the verdict is degraded, not a clean watching.
      final fused = fuseLiveness([
        _verdict(LivenessStatus.alive, at: t, label: 'your home'),
        _verdict(
          LivenessStatus.degraded,
          at: t,
          battery: 8,
          note: 'Battery low.',
          label: 'your phone',
        ),
      ]);
      expect(fused.status, LivenessStatus.degraded);
      expect(fused.limitNote, contains('Battery low')); // the caveat is surfaced
      expect(fused.batteryPercent, 8); // lowest reported battery surfaces
    });

    test('all sources alive → a clean, caveat-free sign of life', () {
      final fused = fuseLiveness([
        _verdict(LivenessStatus.alive, at: t.subtract(const Duration(minutes: 9))),
        _verdict(LivenessStatus.alive, at: t),
      ]);
      expect(fused.status, LivenessStatus.alive);
      expect(fused.limitNote, isNull);
      expect(fused.lastSignOfLife, t); // freshest living sign
    });

    test('FusionBrain composes N sources into honest coverage', () {
      // Two sources through the real brain: phone dark, home alive → corroborated
      // alive, so coverage degrades to a heads-up (not a silence escalation), and
      // the displayed sign of life is the home's fresh one — read only through the
      // engine boundary.
      final phone = _FixedSource(
        _verdict(LivenessStatus.lostContact, label: 'your phone'),
      );
      final home = _FixedSource(
        _verdict(LivenessStatus.alive, at: t, label: 'your home'),
      );
      final circle = CircleStore(demoCircleMembers()); // safe
      addTearDown(circle.dispose);
      // The brain owns the sources it's given — no separate source teardown.
      final brain = FusionBrain(
        sources: [phone, home],
        circle: circle,
        sink: _ReachSink(),
        now: () => t,
      );
      addTearDown(brain.dispose);

      final c = brain.current;
      expect(c.status, CoverageStatus.degraded);
      expect(c.lastSignOfLife, t); // home's fresh sign, not the dead phone's
      expect(c.note, contains('isn’t an emergency'));

      // The home goes quiet too → now genuine multi-source silence escalates.
      home.set(_verdict(LivenessStatus.silent, at: t, label: 'your home'));
      expect(brain.current.status, CoverageStatus.degraded);
      expect(brain.current.note, isNot(contains('isn’t an emergency')));
    });
  });
}
