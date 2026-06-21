import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieye/core/rhythm.dart';

import 'sim/replay.dart';
import 'sim/scenarios.dart';

/// Per-person rhythm baseline (#64): the model learns this person's normal quiet
/// stretches on-device, and — measured on the simulation harness (#63) — a learned
/// window beats the fixed 14h: fewer false alarms at equal sensitivity.
///
/// PRIVACY: the model has NO serialize / sync / network surface and retains only a
/// bounded ring of gap *durations* (no timeline, no locations) — there is nothing
/// to leave the device. The bounded-memory test below guards the "no growing
/// history" half structurally; the no-egress half is an architectural invariant
/// (the class simply has no I/O).
void main() {
  final t0 = DateTime(2026, 1, 5, 8, 0);
  DateTime at(Duration d) => t0.add(d);

  group('RhythmModel learns a per-person window', () {
    test('cold start falls back honestly to the fixed window', () {
      final m = RhythmModel(fallback: const Duration(hours: 14));
      expect(m.hasLearned, isFalse);
      expect(m.silenceWindow, const Duration(hours: 14));
    });

    test('a tight rhythm yields a tight window (clamped to the lower bound)', () {
      final m = RhythmModel();
      // Interactions every 2.5h → 2.5h normal gaps.
      for (var i = 0; i <= 8; i++) {
        m.observeInteraction(at(Duration(minutes: 150 * i)));
      }
      expect(m.hasLearned, isTrue);
      expect(m.typicalQuietStretch, const Duration(hours: 2, minutes: 30));
      // 2.5h × 1.5 = 3.75h → clamped up to the 4h floor (never twitchier than that).
      expect(m.silenceWindow, const Duration(hours: 4));
    });

    test('a loose rhythm yields a looser window', () {
      final m = RhythmModel();
      for (var i = 0; i <= 8; i++) {
        m.observeInteraction(at(Duration(hours: 8 * i)));
      }
      // 8h × 1.5 = 12h.
      expect(m.silenceWindow, const Duration(hours: 12));
    });

    test('the learned window is clamped to the upper bound', () {
      final m = RhythmModel(upperBound: const Duration(hours: 18));
      for (var i = 0; i <= 8; i++) {
        m.observeInteraction(at(Duration(hours: 15 * i)));
      }
      // 15h × 1.5 = 22.5h → clamped down to 18h.
      expect(m.silenceWindow, const Duration(hours: 18));
    });

    test('re-reading the same sign of life adds no gap (idempotent)', () {
      final m = RhythmModel();
      m.observeInteraction(at(const Duration(hours: 1)));
      for (var i = 0; i < 20; i++) {
        m.observeInteraction(at(const Duration(hours: 1))); // same reading
      }
      expect(m.sampleCount, 0); // no NEW interaction → no gap learned
    });

    test('memory is bounded — no growing timeline (rhythm, not profile)', () {
      final m = RhythmModel(memory: 50);
      for (var i = 0; i <= 500; i++) {
        m.observeInteraction(at(Duration(hours: i)));
      }
      expect(m.sampleCount, 50); // old rhythm ages out; history never grows
    });
  });

  group('measured win on the simulation harness (#63)', () {
    test(
      'per-person rhythm beats the fixed window — fewer false alarms at equal sensitivity',
      () {
        final collapse = regularRhythmThenCollapse();
        final loose = looseRhythmNormalLife();
        const target = Duration(hours: 6); // detect the collapse within 6h

        // To catch the regular-rhythm collapse within target, a GLOBAL fixed window
        // must be tight (4h) — and that same window then applies to everyone.
        const tightGlobal = Duration(hours: 4);
        final fixedCollapse = runScenario(collapse, t0: t0, fixedWindow: tightGlobal);
        final fixedLoose = runScenario(loose, t0: t0, fixedWindow: tightGlobal);

        // Per-person: each learns their own rhythm (a fresh model per person).
        final learnedCollapse =
            runScenario(collapse, t0: t0, rhythm: RhythmModel());
        final learnedLoose = runScenario(loose, t0: t0, rhythm: RhythmModel());

        // The shipped fixed 14h is INSENSITIVE for the regular person — it would
        // wait far past the target (this is why you'd be tempted to globally tighten).
        final fixed14Collapse =
            runScenario(collapse, t0: t0, fixedWindow: const Duration(hours: 14));

        debugPrint(
          'rhythm vs fixed:\n'
          '  collapse latency — fixed4h: ${_h(fixedCollapse.latency)}  '
          'learned: ${_h(learnedCollapse.latency)}  '
          'fixed14h: ${_h(fixed14Collapse.latency)}\n'
          '  loose-life alarmed — fixed4h: ${fixedLoose.alarmed}  '
          'learned: ${learnedLoose.alarmed}',
        );

        // Equal sensitivity: BOTH the tight-global and the learned window detect the
        // collapse within target.
        expect(learnedCollapse.latency, isNotNull);
        expect(learnedCollapse.latency! <= target, isTrue,
            reason: 'learned missed the sensitivity target');
        expect(fixedCollapse.latency, isNotNull);
        expect(fixedCollapse.latency! <= target, isTrue);

        // The fixed 14h would NOT meet that target — the loose global window is
        // unsafe-slow for a regular-rhythm person.
        expect(
          fixed14Collapse.latency == null || fixed14Collapse.latency! > target,
          isTrue,
        );

        // Fewer false alarms: the tight global window cries wolf on the loose
        // person's ordinary life; the learned window stays correctly quiet.
        expect(fixedLoose.falseAlarm, isTrue);
        expect(learnedLoose.falseAlarm, isFalse);

        final fixedFalse =
            (fixedLoose.falseAlarm ? 1 : 0) + (fixedCollapse.falseAlarm ? 1 : 0);
        final learnedFalse = (learnedLoose.falseAlarm ? 1 : 0) +
            (learnedCollapse.falseAlarm ? 1 : 0);
        expect(learnedFalse, lessThan(fixedFalse),
            reason: 'learned should produce strictly fewer false alarms');
      },
    );
  });
}

String _h(Duration? d) =>
    d == null ? 'none' : '${(d.inMinutes / 60).toStringAsFixed(1)}h';
