/// The honest coverage state shown on the home screen.
///
/// Honest-coverage UI is a LAUNCH BLOCKER, not polish (PRD §6/§7): over-trust is
/// the #1 product risk. There is deliberately no single "protected" boolean and
/// no green shield — the home screen renders whatever is true, including degraded
/// and paused states, with a plain reason.
enum CoverageStatus {
  /// Actively reading signs of life and the circle is reachable.
  watching,

  /// Still on, but something is wrong the owner must see — e.g. "1 checker, none
  /// nearby" or "battery may have died". Never silently hidden.
  degraded,

  /// Intentionally suspended via "Going dark" — the circle was told it's planned
  /// (PRD §3C, the biggest alarm-fatigue killer).
  pausedGoingDark,

  /// Not yet armed (setup incomplete).
  notArmed,
}

class CoverageState {
  const CoverageState({
    required this.status,
    this.lastSignOfLife,
    this.batteryPercent,
    this.checkerCount = 0,
    this.checkersNearby = 0,
    this.note,
    this.goingDarkUntil,
  });

  final CoverageStatus status;
  final DateTime? lastSignOfLife;
  final int? batteryPercent;
  final int checkerCount;
  final int checkersNearby;

  /// Plain-language truth for degraded/paused states (e.g. "Battery may have
  /// died — we’ll say so rather than pretend"). Shown verbatim; never spun green.
  final String? note;

  final DateTime? goingDarkUntil;

  CoverageState copyWith({
    CoverageStatus? status,
    DateTime? lastSignOfLife,
    int? batteryPercent,
    int? checkerCount,
    int? checkersNearby,
    String? note,
    DateTime? goingDarkUntil,
  }) {
    return CoverageState(
      status: status ?? this.status,
      lastSignOfLife: lastSignOfLife ?? this.lastSignOfLife,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      checkerCount: checkerCount ?? this.checkerCount,
      checkersNearby: checkersNearby ?? this.checkersNearby,
      note: note ?? this.note,
      goingDarkUntil: goingDarkUntil ?? this.goingDarkUntil,
    );
  }
}
