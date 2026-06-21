import 'dart:async';

import 'circle.dart';
import 'coverage.dart';
import 'phone_signals.dart';
import 'tier0_detector.dart';

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
class Tier0Brain implements DetectionBrain {
  /// Injected [circle]/[signals] are owned by the caller (the brain only listens).
  /// Omitted ones are created and owned (and disposed) by the brain.
  Tier0Brain({
    CircleStore? circle,
    PhoneSignalsSource? signals,
    Tier0Detector detector = const Tier0Detector(),
    DateTime Function() now = DateTime.now,
  }) : _circle = circle ?? CircleStore(demoCircleMembers()),
       _ownsCircle = circle == null,
       _signals = signals ?? StubPhoneSignalsSource(),
       _ownsSignals = signals == null,
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
        goingDarkUntil: _goingDarkUntil,
        note:
            'Paused until ${_friendlyDate(_goingDarkUntil!)} — your circle will '
            'be told it’s planned.',
      );
    }

    // A sensing problem (the person/phone) is more urgent than a circle gap, so
    // its honest caveat wins the single note slot; otherwise fall back to the
    // circle's coverage note. Either degrades the status — never a false watching.
    final sensingDegraded = !a.isHealthy;
    final note = sensingDegraded ? a.limitNote : c.coverageNote;
    final degraded = sensingDegraded || !c.isSafe;
    return CoverageState(
      status: degraded ? CoverageStatus.degraded : CoverageStatus.watching,
      lastSignOfLife: a.lastSignOfLife,
      batteryPercent: a.batteryPercent,
      checkerCount: c.total,
      checkersNearby: c.canReachFastCount,
      note: note,
    );
  }

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
