import 'package:flutter/foundation.dart';

import 'phone_signals.dart';
import 'rhythm.dart';
import 'tier0_detector.dart';

/// One honest liveness signal, and the rule that fuses many of them (#62, #60).
///
/// Tier-0 reads a single phone; everything past it (home mesh, wrist, custom HW)
/// needs the brain to fuse N independent sources into ONE honest coverage state.
/// The boundary that makes that possible: every source emits a [LivenessAssessment]
/// — a status + an honest caveat — and NEVER a raw trace. Liveness stays one bit
/// at the edge (CLAUDE.md): a source decides "alive / degraded / silent / lost"
/// on-device and hands over only that verdict.

enum LivenessStatus {
  /// A fresh, positive sign of life from this source.
  alive,

  /// On, with a sign of life, but a caveat the owner must see (e.g. battery low).
  /// Still corroborates life — just not a clean all-clear.
  degraded,

  /// No sign of life beyond this source's expected window — the "go check" signal.
  silent,

  /// This source can't report (off / dead / out of range). NOT an all-clear — a
  /// dead sensor must never read as "everything's fine".
  lostContact,
}

/// What a source hands across the boundary: a verdict, never raw telemetry.
class LivenessAssessment {
  const LivenessAssessment({
    required this.status,
    this.lastSignOfLife,
    this.batteryPercent,
    this.limitNote,
    this.label = 'a sensor',
  });

  final LivenessStatus status;
  final DateTime? lastSignOfLife;

  /// Optional, source-specific (e.g. the phone's battery). Null for sources that
  /// don't have one.
  final int? batteryPercent;

  /// The honest caveat for this source's state (null when [alive]). Surfaced so a
  /// limit is always visible, never hidden.
  final String? limitNote;

  /// Short human label for honest fused notes ("your phone", "your home").
  final String label;

  bool get isAlive => status == LivenessStatus.alive;

  /// A fresh positive sign of life — [alive], or alive-with-a-caveat ([degraded],
  /// e.g. battery low but still interacting). This is what lets ONE living source
  /// corroborate the person even while another source has gone dark.
  bool get corroboratesLife =>
      status == LivenessStatus.alive || status == LivenessStatus.degraded;
}

/// An honest, listenable liveness source. The brain plugs in a set of these and
/// fuses their assessments. A source notifies when its reading changes; it only
/// ever exposes [assess], never the raw signals behind it.
abstract class LivenessSource extends ChangeNotifier {
  /// Short human label used in fused notes.
  String get label;

  /// This source's honest current verdict at [now].
  LivenessAssessment assess(DateTime now);
}

/// The Tier-0 phone, adapted to the fusion boundary. It delegates to the existing
/// [Tier0Detector] (the #14 rhythm rule stays the single source of truth for the
/// phone, so there is no behaviour change for phone-only), and maps its verdict
/// onto the shared [LivenessStatus]. It listens to the underlying signals but does
/// NOT own them — disposal of the signal source stays with whoever created it.
class PhoneLivenessSource extends LivenessSource {
  PhoneLivenessSource(
    this._signals, [
    this._detector = const Tier0Detector(),
    this._rhythm,
  ]) {
    _signals.addListener(notifyListeners);
  }

  final PhoneSignalsSource _signals;
  final Tier0Detector _detector;

  /// Optional per-person rhythm (#64). When present, the source learns this
  /// person's normal quiet stretches and uses a learned silence window instead of
  /// the fixed default — falling back honestly until enough rhythm is observed.
  final RhythmModel? _rhythm;

  @override
  String get label => 'your phone';

  @override
  LivenessAssessment assess(DateTime now) {
    final s = _signals.current;
    // Learn from each fresh sign of life, then judge silence against THIS person's
    // rhythm. observeInteraction is idempotent on a repeated reading.
    _rhythm?.observeInteraction(s.lastInteraction);
    final a = _detector.assess(s, now, silenceWindow: _rhythm?.silenceWindow);
    final status = switch (a.status) {
      SensingStatus.watching => LivenessStatus.alive,
      SensingStatus.batteryLow => LivenessStatus.degraded,
      SensingStatus.silenceConcern => LivenessStatus.silent,
      SensingStatus.lostContact => LivenessStatus.lostContact,
    };
    return LivenessAssessment(
      status: status,
      lastSignOfLife: a.lastSignOfLife,
      batteryPercent: a.batteryPercent,
      limitNote: a.limitNote,
      label: label,
    );
  }

  @override
  void dispose() {
    _signals.removeListener(notifyListeners);
    super.dispose(); // deliberately does NOT dispose _signals (caller owns it)
  }
}

/// Fuse N independent, honest source verdicts into one. The rule (PRD §11, #62):
///
///  • **Corroboration suppresses false alarms.** If ANY source still sees a sign
///    of life, the person is alive — even if another source has gone dark (phone
///    dead BUT home active = alive). We never raise a silence alarm on a battery
///    death that another sensor contradicts.
///  • **Genuine multi-source silence escalates.** When NO source sees life, the
///    most urgent signal (lost contact / silence) stands — that's the real "go
///    check" path.
///  • **Any unhealthy source degrades coverage.** A caveat — a dropped sensor, a
///    low battery — is always surfaced; corroborated-alive is shown as a heads-up,
///    NEVER a clean watching all-clear.
LivenessAssessment fuseLiveness(List<LivenessAssessment> parts) {
  if (parts.isEmpty) {
    return const LivenessAssessment(
      status: LivenessStatus.lostContact,
      limitNote:
          'No sensors are reporting yet, so iEye can’t see a sign of life.',
    );
  }

  // Battery is source-specific; surface the lowest one any source reports.
  final batteries = parts
      .map((p) => p.batteryPercent)
      .whereType<int>()
      .toList();
  final battery = batteries.isEmpty ? null : batteries.reduce((a, b) => a < b ? a : b);

  final living = parts.where((p) => p.corroboratesLife).toList();
  if (living.isEmpty) {
    // No source sees life — genuine silence. The most urgent signal wins the note.
    final worst = _mostUrgent(parts);
    return LivenessAssessment(
      status: worst.status,
      lastSignOfLife: _mostRecent(parts),
      batteryPercent: battery,
      limitNote: worst.limitNote,
    );
  }

  // Someone is clearly alive — show the freshest living sign of life…
  final lastLiving = _mostRecent(living);
  final dropped = parts.where((p) => !p.corroboratesLife).toList();
  final degradedLiving =
      living.where((p) => p.status == LivenessStatus.degraded).toList();

  // …but never a clean all-clear while a source carries a caveat.
  if (dropped.isEmpty && degradedLiving.isEmpty) {
    return LivenessAssessment(
      status: LivenessStatus.alive,
      lastSignOfLife: lastLiving,
      batteryPercent: battery,
    );
  }
  final note = dropped.isNotEmpty
      ? _corroboratedNote(dropped, living)
      : degradedLiving.first.limitNote;
  return LivenessAssessment(
    status: LivenessStatus.degraded,
    lastSignOfLife: lastLiving,
    batteryPercent: battery,
    limitNote: note,
  );
}

/// A dead/silent source, reassured by a living one: honest, but not an alarm.
String _corroboratedNote(
  List<LivenessAssessment> dropped,
  List<LivenessAssessment> living,
) {
  final d = _joinLabels(dropped.map((p) => p.label));
  final l = _joinLabels(living.map((p) => p.label));
  return 'iEye isn’t hearing from $d, but $l still sees a sign of life — so this '
      'isn’t an emergency. You may want to check $d when you can.';
}

int _rank(LivenessStatus s) => switch (s) {
  LivenessStatus.lostContact => 3,
  LivenessStatus.silent => 2,
  LivenessStatus.degraded => 1,
  LivenessStatus.alive => 0,
};

LivenessAssessment _mostUrgent(List<LivenessAssessment> parts) =>
    parts.reduce((a, b) => _rank(b.status) > _rank(a.status) ? b : a);

DateTime? _mostRecent(List<LivenessAssessment> parts) {
  DateTime? latest;
  for (final p in parts) {
    final t = p.lastSignOfLife;
    if (t == null) continue;
    if (latest == null || t.isAfter(latest)) latest = t;
  }
  return latest;
}

String _joinLabels(Iterable<String> labels) {
  final list = labels.toList();
  if (list.length <= 1) return list.isEmpty ? 'a sensor' : list.first;
  if (list.length == 2) return '${list[0]} and ${list[1]}';
  return '${list.sublist(0, list.length - 1).join(', ')}, and ${list.last}';
}
