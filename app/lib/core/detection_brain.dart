import 'dart:async';

import 'circle.dart';
import 'coverage.dart';
import 'phone_signals.dart';
import 'tier0_detector.dart';
import 'trigger_sink.dart';

/// The on-device detection brain (PRD §4, #11). Sensor fusion + a rhythm/anomaly
/// model that watches at two speeds (slow silence / fast acute) and emits an
/// honest [CoverageState]. It is the SHARED brain; the trigger sink it feeds is
/// pluggable.
///
/// PRIVACY BY ARCHITECTURE (CLAUDE.md): liveness is one bit, processed at the
/// edge. The brain must never log or sync GPS traces, rhythm baselines, or unlock
/// timelines — only emit coverage state. The real implementation is Tier-0
/// phone-only first (GPS + IMU + battery + per-location pattern, #14).
abstract interface class DetectionBrain {
  /// Honest coverage, pushed as it changes.
  Stream<CoverageState> get coverage;

  /// Latest known coverage (for first paint).
  CoverageState get current;

  /// Owner says "I'm away / this is planned" — suspend the watch and tell the
  /// circle it's intentional (PRD §3C). The single biggest fatigue killer.
  void goDark({required DateTime until});

  /// Resume after going dark, or re-arm.
  void resume();

  void dispose();
}

/// Tier-0 phone-only brain (#14). Runs the real rhythm rule ([Tier0Detector])
/// over phone signals and merges the result with the circle's health into one
/// honest [CoverageState]. The ONLY stub now is the signal *source* (real battery
/// + activity need a platform plugin) — the rule and the honest limits are real.
///
/// Coverage is read through THIS engine boundary only (mode-agnostic) — no UI
/// computes it ad hoc, so a phone-only gap or a coverage drop can never be hidden
/// (PRD §3D/§11: "ship the limits visibly, not the dream").
///
/// Coverage has TWO honest halves and the brain fuses both: can we DETECT a
/// problem (the sensing engine + circle), and can we DELIVER help when we do (the
/// [TriggerSink] boundary, #12). The delivery half is read through the sink's
/// mode-agnostic [TriggerSink.sendsOffDevice] flag — never Easy-mode internals —
/// so when nothing can leave the phone the home degrades honestly instead of
/// showing a watching all-clear no one would ever hear (PRD §6/§7).
class Tier0Brain implements DetectionBrain {
  /// Injected [circle]/[signals] are owned by the caller (the brain only listens).
  /// Omitted ones are created and owned (and disposed) by the brain.
  ///
  /// [sink] is the active delivery boundary whose reach folds into coverage. It
  /// defaults to the signs-nothing [LocalNoopSink] — the honest truth of the
  /// green-lit prototype: it can watch, but it cannot yet summon anyone, and the
  /// home must say so.
  Tier0Brain({
    CircleStore? circle,
    PhoneSignalsSource? signals,
    TriggerSink? sink,
    Tier0Detector detector = const Tier0Detector(),
    DateTime Function() now = DateTime.now,
  }) : _circle = circle ?? CircleStore(demoCircleMembers()),
       _ownsCircle = circle == null,
       _signals = signals ?? StubPhoneSignalsSource(),
       _ownsSignals = signals == null,
       _sink = sink ?? LocalNoopSink(),
       _detector = detector,
       _now = now {
    _circle.addListener(_recompose);
    _signals.addListener(_recompose);
    _state = _compose();
    _controller = StreamController<CoverageState>.broadcast(
      onListen: () => _controller.add(_state),
    );
  }

  final CircleStore _circle;
  final bool _ownsCircle;
  final PhoneSignalsSource _signals;
  final bool _ownsSignals;
  // The delivery boundary (#12). The brain only reads its reach capability
  // ([sendsOffDevice]); it never fires it here — the prototype signs nothing.
  final TriggerSink _sink;
  final Tier0Detector _detector;
  // Injectable clock for deterministic tests. NOTE: coverage is only re-evaluated
  // when the circle or signals notify — there is no periodic tick yet, so the
  // slow-silence path needs a Timer/real source to fire on its own in the field
  // (follow-up: #13 rung-0 / #15 background).
  final DateTime Function() _now;
  bool _paused = false;
  DateTime? _goingDarkUntil;

  late CoverageState _state;
  late final StreamController<CoverageState> _controller;

  /// The circle backing this brain — shared with the circle screen so a
  /// resignation there flows straight into owner-visible coverage here.
  CircleStore get circle => _circle;

  @override
  CoverageState get current => _state;

  @override
  Stream<CoverageState> get coverage => _controller.stream;

  CoverageState _compose() {
    final c = _circle.circle;
    final a = _detector.assess(_signals.current, _now());

    // Can an alert actually leave this phone? Read once, through the boundary.
    final canDeliver = _sink.sendsOffDevice;

    if (_paused) {
      // Deliberate: while "going dark", being unreachable is EXPECTED (the owner
      // told us they're away), so we don't surface lostContact/silence here —
      // that's the whole fatigue-killer. The circle was told it's planned.
      return CoverageState(
        status: CoverageStatus.pausedGoingDark,
        lastSignOfLife: a.lastSignOfLife,
        batteryPercent: a.batteryPercent,
        checkerCount: c.total,
        checkersNearby: c.canReachFastCount,
        canSummonHelp: canDeliver,
        goingDarkUntil: _goingDarkUntil,
        note:
            'Paused until ${_friendlyDate(_goingDarkUntil!)} — your circle will '
            'be told it’s planned.',
      );
    }

    // Three honest ways coverage degrades, in priority order for the single note
    // slot. A sensing problem (the person/phone) is the most urgent thing the
    // owner must act on, so it wins. Next, "we can't reach anyone off this phone"
    // — sensing may be fine, but no alert would ever go out, so we must NOT show a
    // watching all-clear (the structural anti-fake-green-shield rule). Last, a
    // circle gap. ANY of the three degrades the status — never a false watching.
    final sensingDegraded = !a.isHealthy;
    final note =
        sensingDegraded
            ? a.limitNote
            : !canDeliver
            ? _noReachNote
            : c.coverageNote;
    final degraded = sensingDegraded || !canDeliver || !c.isSafe;
    return CoverageState(
      status: degraded ? CoverageStatus.degraded : CoverageStatus.watching,
      lastSignOfLife: a.lastSignOfLife,
      batteryPercent: a.batteryPercent,
      checkerCount: c.total,
      checkersNearby: c.canReachFastCount,
      canSummonHelp: canDeliver,
      note: note,
    );
  }

  /// The honest reach gap (PRD §6): iEye can watch, but with no off-device sink
  /// nothing it notices would ever reach a human. Promise the mechanism, never an
  /// outcome — say plainly that no alert would go out.
  static const String _noReachNote =
      'iEye can notice if you go quiet, but it can’t reach anyone off this phone '
      'yet — so no alert would go out. This turns on when delivery is set up.';

  void _recompose() => _emit(_compose());

  void _emit(CoverageState next) {
    _state = next;
    _controller.add(next);
  }

  @override
  void goDark({required DateTime until}) {
    _paused = true;
    _goingDarkUntil = until;
    _emit(_compose());
  }

  @override
  void resume() {
    _paused = false;
    _goingDarkUntil = null;
    _emit(_compose());
  }

  @override
  void dispose() {
    _circle.removeListener(_recompose);
    _signals.removeListener(_recompose);
    if (_ownsCircle) _circle.dispose(); // only dispose what we created
    if (_ownsSignals) _signals.dispose();
    _controller.close();
  }

  static String _friendlyDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
