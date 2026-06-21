import 'dart:async';

import 'circle.dart';
import 'coverage.dart';

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

/// Placeholder brain — NO real sensors yet. It emits a plausible, honest coverage
/// state so the product spine (home screen, going-dark, onboarding) can be built
/// and demoed with zero hardware (PRD §3D "build the human side first"). Tier-0
/// phone sensing (#14) replaces the guts behind this same interface.
class Tier0StubBrain implements DetectionBrain {
  /// If [circle] is injected, the caller owns its lifecycle (the brain only
  /// listens). If omitted, the brain creates and owns one, and disposes it.
  Tier0StubBrain({CircleStore? circle})
    : _circle = circle ?? CircleStore(demoCircleMembers()),
      _ownsCircle = circle == null {
    _circle.addListener(_onCircleChanged);
    _state = _compose();
    _controller = StreamController<CoverageState>.broadcast(
      onListen: () => _controller.add(_state),
    );
  }

  final CircleStore _circle;
  final bool _ownsCircle;
  bool _paused = false;
  DateTime? _goingDarkUntil;
  DateTime _lastSignOfLife = DateTime.now().subtract(
    const Duration(minutes: 12),
  );
  final int _battery = 80;

  late CoverageState _state;
  late final StreamController<CoverageState> _controller;

  /// The circle backing this brain — shared with the circle screen so a
  /// resignation there flows straight into owner-visible coverage here.
  CircleStore get circle => _circle;

  @override
  CoverageState get current => _state;

  @override
  Stream<CoverageState> get coverage => _controller.stream;

  /// Build honest coverage by merging sensing (last sign of life, battery) with
  /// the circle's health. Coverage is read through THIS engine boundary only
  /// (mode-agnostic) — no UI computes it ad hoc, so a coverage drop can't be
  /// hidden (PRD §3D).
  CoverageState _compose() {
    final c = _circle.circle;
    if (_paused) {
      return CoverageState(
        status: CoverageStatus.pausedGoingDark,
        lastSignOfLife: _lastSignOfLife,
        batteryPercent: _battery,
        checkerCount: c.total,
        checkersNearby: c.canReachFastCount,
        goingDarkUntil: _goingDarkUntil,
        note:
            'Paused until ${_friendlyDate(_goingDarkUntil!)} — your circle will '
            'be told it’s planned.',
      );
    }
    final note = c.coverageNote; // null when coverage is safe
    return CoverageState(
      status: note == null ? CoverageStatus.watching : CoverageStatus.degraded,
      lastSignOfLife: _lastSignOfLife,
      batteryPercent: _battery,
      checkerCount: c.total,
      checkersNearby: c.canReachFastCount,
      note: note,
    );
  }

  void _onCircleChanged() => _emit(_compose());

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
    _lastSignOfLife = DateTime.now();
    _emit(_compose());
  }

  @override
  void dispose() {
    _circle.removeListener(_onCircleChanged);
    if (_ownsCircle) _circle.dispose(); // only dispose a store we created
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
