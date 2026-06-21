import 'package:ieye/core/circle.dart';
import 'package:ieye/core/coverage.dart';
import 'package:ieye/core/detection_brain.dart';
import 'package:ieye/core/phone_signals.dart';
import 'package:ieye/core/trigger_sink.dart';
import 'package:ieye/core/welfare_signal.dart';

/// Deterministic replay/scoring harness for the detection brain (#63, #60).
///
/// We cannot ethically tune a life-safety detector against real emergencies — you
/// can't wait for someone to fall to test fall detection. So we replay synthetic,
/// time-ordered sensor traces through the REAL brain and score the emitted
/// coverage timeline: did it stay quiet when it should, escalate when it should,
/// and how long did detection take. This is the honesty engine — we publish a
/// *measured* mechanism, not a claim — and the merge gate: no detection/model
/// change ships without a passing run and a non-regressing false-alarm number.
///
/// Everything here is virtual-clock deterministic (no `DateTime.now`), so a trace
/// always scores identically.

/// One keyframe of a phone-only trace. From [at] onward (until the next frame) the
/// phone holds this reading; because the last interaction is pinned, silence grows
/// on its own as the virtual clock advances — that's the slow path under test.
class TraceFrame {
  const TraceFrame({
    required this.at,
    this.sinceInteraction = Duration.zero,
    this.battery = 80,
    this.charging = false,
    this.reachable = true,
  });

  /// Offset from the scenario start when this reading begins.
  final Duration at;

  /// How long ago the owner last touched the phone, measured at [at]. Zero = a
  /// fresh interaction right now (resets the silence clock).
  final Duration sinceInteraction;

  final int battery;
  final bool charging;

  /// False = phone off / dead / OS-killed — the dominant phone-only blind spot.
  final bool reachable;
}

/// What a scenario asserts about the brain's behaviour.
class Expect {
  const Expect.quiet()
    : shouldAlarm = false,
      triggerAt = null,
      within = null;

  /// Should escalate: from [triggerAt] (when the condition begins), coverage must
  /// degrade within [within] — the measured detection latency bound.
  const Expect.alarm({required this.triggerAt, required this.within})
    : shouldAlarm = true;

  final bool shouldAlarm;
  final Duration? triggerAt;
  final Duration? within;
}

/// A synthetic scenario: a phone-only trace + the expectation it must meet. Kept
/// phone-only for Tier-0 (the brain's only shipped source); multi-source replay is
/// a later extension on the same runner.
class Scenario {
  const Scenario({
    required this.name,
    required this.frames,
    required this.expect,
    this.duration = const Duration(hours: 18),
    this.sampleEvery = const Duration(minutes: 30),
  });

  final String name;

  /// Sorted by [TraceFrame.at]; must include a frame at offset zero.
  final List<TraceFrame> frames;
  final Expect expect;
  final Duration duration;
  final Duration sampleEvery;
}

/// One sampled point of the scored timeline.
class SamplePoint {
  const SamplePoint(this.at, this.status);
  final DateTime at;
  final CoverageStatus status;
}

/// The scored result of replaying one scenario.
class ScenarioResult {
  ScenarioResult(this.scenario, this.t0, this.timeline);

  final Scenario scenario;
  final DateTime t0;
  final List<SamplePoint> timeline;

  /// First moment coverage degraded. Scenarios are constructed so the ONLY cause
  /// of a degrade is a sensing concern (silence / lost contact): the circle is
  /// safe and the sink reaches, and batteries stay healthy — so a degrade is a
  /// real escalation, never a circle/reach/battery artefact.
  DateTime? get firstAlarmAt {
    for (final p in timeline) {
      if (p.status == CoverageStatus.degraded) return p.at;
    }
    return null;
  }

  bool get alarmed => firstAlarmAt != null;

  /// Detection latency from the condition's onset, when both are known.
  Duration? get latency {
    final t = scenario.expect.triggerAt;
    final a = firstAlarmAt;
    if (t == null || a == null) return null;
    return a.difference(t0.add(t));
  }

  /// A "should stay quiet" scenario that nonetheless alarmed.
  bool get falseAlarm => !scenario.expect.shouldAlarm && alarmed;

  /// A "should escalate" scenario that never alarmed, or alarmed too late.
  bool get missedDetection {
    if (!scenario.expect.shouldAlarm) return false;
    final l = latency;
    if (l == null) return true; // never alarmed
    final within = scenario.expect.within;
    return l < Duration.zero || (within != null && l > within);
  }

  bool get passed => !falseAlarm && !missedDetection;
}

/// Reaches off-device — so in replay the ONLY thing that can degrade coverage is a
/// sensing concern, never the #27 reach gap. Fires nothing.
class _ReachingSink implements TriggerSink {
  @override
  String get name => 'Replay (reaching)';
  @override
  bool get sendsOffDevice => true;
  @override
  Future<void> fire(WelfareSignal signal) async {}
}

/// Replay one scenario through a real [Tier0Brain] and score the result.
/// Deterministic: the clock is virtual and advances only as we sample.
ScenarioResult runScenario(Scenario s, {required DateTime t0}) {
  assert(
    s.frames.isNotEmpty && s.frames.first.at == Duration.zero,
    'a scenario needs a frame at offset zero',
  );

  var now = t0;
  final signals = StubPhoneSignalsSource(_signalsAt(s, t0, t0));
  final circle = CircleStore(demoCircleMembers()); // safe by construction
  final brain = Tier0Brain(
    signals: signals,
    circle: circle,
    sink: _ReachingSink(),
    now: () => now,
  );

  final timeline = <SamplePoint>[];
  final end = t0.add(s.duration);
  for (var t = t0; !t.isAfter(end); t = t.add(s.sampleEvery)) {
    now = t;
    signals.update(_signalsAt(s, t, t0)); // notifies → brain recomposes at `now`
    timeline.add(SamplePoint(t, brain.current.status));
  }

  // Ownership: injected signals + circle are caller-owned, so we dispose them
  // (the brain disposes only the phone-source wrapper it created around them).
  brain.dispose();
  signals.dispose();
  circle.dispose();
  return ScenarioResult(s, t0, timeline);
}

PhoneSignals _signalsAt(Scenario s, DateTime t, DateTime t0) {
  final off = t.difference(t0);
  var frame = s.frames.first;
  for (final f in s.frames) {
    if (f.at <= off) frame = f;
  }
  return PhoneSignals(
    lastInteraction: t0.add(frame.at).subtract(frame.sinceInteraction),
    batteryPercent: frame.battery,
    charging: frame.charging,
    reachable: frame.reachable,
  );
}

/// Aggregate score across a library — the numbers CI surfaces and gates on.
class LibraryScore {
  LibraryScore(this.results);

  final List<ScenarioResult> results;

  Iterable<ScenarioResult> get _quiet =>
      results.where((r) => !r.scenario.expect.shouldAlarm);
  Iterable<ScenarioResult> get _alarms =>
      results.where((r) => r.scenario.expect.shouldAlarm);

  int get falseAlarms => _quiet.where((r) => r.falseAlarm).length;
  int get missedDetections => _alarms.where((r) => r.missedDetection).length;
  int get quietCount => _quiet.length;

  double get falseAlarmRate =>
      quietCount == 0 ? 0 : falseAlarms / quietCount;

  bool get allPassed => results.every((r) => r.passed);

  /// A human report (CI log line) — the *measured* mechanism, per scenario.
  String report() {
    final b = StringBuffer()
      ..writeln('iEye detection scenario score:')
      ..writeln(
        '  false-alarm rate: ${(falseAlarmRate * 100).toStringAsFixed(0)}% '
        '($falseAlarms/$quietCount quiet)   missed: $missedDetections',
      );
    for (final r in results) {
      final l = r.latency;
      final lat = l == null ? '' : ' · latency ${_h(l)}';
      final verdict = r.passed ? 'PASS' : 'FAIL';
      final got = r.alarmed ? 'alarm' : 'quiet';
      b.writeln('  [$verdict] ${r.scenario.name} → $got$lat');
    }
    return b.toString();
  }

  static String _h(Duration d) {
    final h = d.inMinutes / 60.0;
    return '${h.toStringAsFixed(1)}h';
  }
}

LibraryScore scoreLibrary(List<Scenario> library, {required DateTime t0}) =>
    LibraryScore([for (final s in library) runScenario(s, t0: t0)]);
