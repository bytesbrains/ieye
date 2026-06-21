import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sim/replay.dart';
import 'sim/scenarios.dart';

/// The detection merge gate (#63). `flutter test` runs this, so no change to the
/// brain, the fusion rule, or a sensor can merge without:
///   • every scenario meeting its expectation (quiet stays quiet, alarms fire in
///     time), and
///   • the false-alarm count not regressing past the baseline.
/// It also prints the measured score (false-alarm rate + per-scenario latency) so
/// CI surfaces the *mechanism we can prove*, not a claim.
void main() {
  // Fixed virtual start — determinism (no DateTime.now anywhere in replay).
  final t0 = DateTime(2026, 1, 5, 8, 0);

  // The non-regression baseline. The current brain false-alarms on ZERO quiet
  // scenarios; if a change pushes this above the baseline, the build fails.
  const maxFalseAlarms = 0;

  group('detection scenario gate (#63)', () {
    final score = scoreLibrary(tier0ScenarioLibrary(), t0: t0);

    test('replay is deterministic — same trace, same scored timeline', () {
      final again = scoreLibrary(tier0ScenarioLibrary(), t0: t0);
      for (var i = 0; i < score.results.length; i++) {
        expect(
          again.results[i].firstAlarmAt,
          score.results[i].firstAlarmAt,
          reason: 'scenario "${score.results[i].scenario.name}" not deterministic',
        );
      }
    });

    test('every scenario meets its expectation (quiet quiet, alarms in time)', () {
      // Surface the measured score in the CI log on every run.
      debugPrint(score.report());
      for (final r in score.results) {
        expect(
          r.passed,
          isTrue,
          reason: r.falseAlarm
              ? 'FALSE ALARM: "${r.scenario.name}" degraded when it should stay quiet'
              : 'MISSED/LATE: "${r.scenario.name}" did not escalate within bound '
                  '(latency ${r.latency})',
        );
      }
    });

    test('false-alarm count does not regress past the baseline', () {
      expect(
        score.falseAlarms,
        lessThanOrEqualTo(maxFalseAlarms),
        reason:
            'false alarms rose to ${score.falseAlarms} (baseline $maxFalseAlarms) '
            '— a detection/model change made the brain cry wolf:\n${score.report()}',
      );
      expect(score.missedDetections, 0, reason: score.report());
    });

    test('the library covers BOTH classes (escalate and stay-quiet)', () {
      final lib = tier0ScenarioLibrary();
      expect(lib.where((s) => s.expect.shouldAlarm), isNotEmpty);
      expect(lib.where((s) => !s.expect.shouldAlarm), isNotEmpty);
    });

    test('measured Tier-0 silence latency is in the honest hours range', () {
      // Not a guarantee — a *measured* property we can publish: phone-only silence
      // detection takes hours (the window), and that is what the harness records.
      final collapse = score.results.firstWhere(
        (r) => r.scenario.name.contains('collapse'),
      );
      expect(collapse.latency, isNotNull);
      expect(collapse.latency!.inHours, greaterThanOrEqualTo(13));
      expect(collapse.latency!.inHours, lessThanOrEqualTo(15));
    });
  });
}
