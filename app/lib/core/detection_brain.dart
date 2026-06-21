import 'dart:async';

import 'circle.dart';
import 'coverage.dart';
import 'liveness_source.dart';
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

/// The multi-source brain (#62, #60). It fuses a SET of honest [LivenessSource]s
/// with the circle's health and the delivery boundary into one honest
/// [CoverageState]. Tier-0 phone-only is just one instance of it ([Tier0Brain],
/// one phone source) — past Tier-0 the same brain takes home-mesh / wrist / HW
/// sources with no new composition path.
///
/// Coverage has TWO honest halves and the brain fuses both: can we DETECT a
/// problem (the [LivenessSource]s + circle) and can we DELIVER help when we do
/// (the [TriggerSink] boundary, #12). Coverage is read through THIS engine
/// boundary only (mode-agnostic) — no UI computes it ad hoc, so a sensor gap, a
/// coverage drop, or a no-reach gap can never be hidden (PRD §3D/§11/§6).
///
/// The fusion rule lives in [fuseLiveness]: corroboration suppresses false alarms
/// (phone dead BUT home active = alive), genuine multi-source silence escalates,
/// and any degraded source degrades coverage — never a false `watching`.
class FusionBrain implements DetectionBrain {
  /// The brain OWNS the [sources] plugged into it and disposes them with itself.
  /// (A source's own internals — e.g. a phone signal stream it merely listens to —
  /// stay owned by whoever created them; see [PhoneLivenessSource].) The injected
  /// [circle] follows the usual rule: caller-provided is caller-owned, an omitted
  /// one is created and disposed here.
  FusionBrain({
    required List<LivenessSource> sources,
    CircleStore? circle,
    TriggerSink? sink,
    DateTime Function() now = DateTime.now,
  }) : _sources = sources,
       _circle = circle ?? CircleStore(demoCircleMembers()),
       _ownsCircle = circle == null,
       _sink = sink ?? LocalNoopSink(),
       _now = now {
    for (final s in _sources) {
      s.addListener(_recompose);
    }
    _circle.addListener(_recompose);
    _state = _compose();
    _controller = StreamController<CoverageState>.broadcast(
      onListen: () => _controller.add(_state),
    );
  }

  final List<LivenessSource> _sources;
  final CircleStore _circle;
  final bool _ownsCircle;
  // The delivery boundary (#12). The brain only reads its reach capability
  // ([sendsOffDevice]); it never fires it here — the prototype signs nothing.
  final TriggerSink _sink;
  // Injectable clock for deterministic tests. NOTE: coverage is only re-evaluated
  // when a source or the circle notifies — there is no periodic tick yet, so the
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
    // Fuse every source into one honest verdict (corroboration suppresses false
    // alarms; multi-source silence escalates; any caveat degrades).
    final a = fuseLiveness([for (final s in _sources) s.assess(_now())]);

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
    // slot. A sensing problem (the person/sensors) is the most urgent thing the
    // owner must act on, so it wins. Next, "we can't reach anyone off this phone"
    // — sensing may be fine, but no alert would ever go out, so we must NOT show a
    // watching all-clear (the structural anti-fake-green-shield rule). Last, a
    // circle gap. ANY of the three degrades the status — never a false watching.
    final sensingDegraded = !a.isAlive;
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
    for (final s in _sources) {
      s.removeListener(_recompose);
      s.dispose(); // the brain owns the sources plugged into it
    }
    _circle.removeListener(_recompose);
    if (_ownsCircle) _circle.dispose(); // only dispose what we created
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

/// Tier-0 phone-only brain (#14) — a [FusionBrain] with exactly one source: the
/// phone ([PhoneLivenessSource] over the #14 rhythm rule). It keeps the same
/// public surface as before so phone-only behaviour is unchanged; everything past
/// Tier-0 just adds more sources to a [FusionBrain].
///
/// The ONLY stub now is the signal *source* (real battery + activity need a
/// platform plugin) — the rule and the honest limits are real.
class Tier0Brain extends FusionBrain {
  /// Injected [signals] are owned by the caller; an omitted one is created and
  /// owned (and disposed) here. (The circle follows the same rule via [super].)
  Tier0Brain({
    CircleStore? circle,
    PhoneSignalsSource? signals,
    TriggerSink? sink,
    Tier0Detector detector = const Tier0Detector(),
    DateTime Function() now = DateTime.now,
  }) : this._(
         signals ?? StubPhoneSignalsSource(),
         signals == null,
         circle,
         sink,
         detector,
         now,
       );

  Tier0Brain._(
    PhoneSignalsSource signals,
    this._ownsSignals,
    CircleStore? circle,
    TriggerSink? sink,
    Tier0Detector detector,
    DateTime Function() now,
  ) : _signals = signals,
      super(
        sources: [PhoneLivenessSource(signals, detector)],
        circle: circle,
        sink: sink,
        now: now,
      );

  final PhoneSignalsSource _signals;
  final bool _ownsSignals;

  @override
  void dispose() {
    super.dispose(); // disposes the PhoneLivenessSource (detaches from _signals)
    if (_ownsSignals) _signals.dispose(); // only dispose signals we created
  }
}
