import 'dart:async';

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
  Tier0StubBrain() {
    _state = CoverageState(
      status: CoverageStatus.watching,
      lastSignOfLife: DateTime.now().subtract(const Duration(minutes: 12)),
      batteryPercent: 80,
      checkerCount: 3,
      checkersNearby: 1,
    );
    _controller = StreamController<CoverageState>.broadcast(
      onListen: () => _controller.add(_state),
    );
  }

  late CoverageState _state;
  late final StreamController<CoverageState> _controller;

  @override
  CoverageState get current => _state;

  @override
  Stream<CoverageState> get coverage => _controller.stream;

  void _emit(CoverageState next) {
    _state = next;
    _controller.add(next);
  }

  @override
  void goDark({required DateTime until}) {
    _emit(
      _state.copyWith(
        status: CoverageStatus.pausedGoingDark,
        goingDarkUntil: until,
        note:
            'Paused until ${_friendlyDate(until)} — your circle will be told it’s planned.',
      ),
    );
  }

  @override
  void resume() {
    _emit(
      CoverageState(
        status: CoverageStatus.watching,
        lastSignOfLife: DateTime.now(),
        batteryPercent: _state.batteryPercent,
        checkerCount: _state.checkerCount,
        checkersNearby: _state.checkersNearby,
      ),
    );
  }

  @override
  void dispose() => _controller.close();

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
