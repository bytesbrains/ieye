/// Per-person rhythm baseline (#64, #60) — "watch the pattern, not the clock."
///
/// A fixed silence window is a false-alarm generator: a night-shift nurse and a
/// retiree have opposite rhythms, and no single constant serves both. Too tight
/// and the loose-rhythm person cries wolf; too loose and the regular-rhythm
/// person isn't checked for far too long. This model learns how long *this* person
/// normally goes quiet and sets the concern threshold to "unusual **for you**".
///
/// PRIVACY / "rhythm, not profile" (CLAUDE.md, non-negotiable):
///   • It learns and lives ON-DEVICE only — there is deliberately NO serialize,
///     toJson, sync, or network surface anywhere on this class. Nothing to leak.
///   • It retains only a bounded ring of recent gap *durations* (minutes) plus the
///     single most-recent interaction time needed to measure the next gap. No
///     timeline, no locations, no per-event history — there is no dossier to build.
///   • The threshold it produces is explainable (a percentile of your normal gaps
///     × a margin, clamped to sane bounds) — auditable, not a black box, because a
///     life-safety threshold must be inspectable.
class RhythmModel {
  RhythmModel({
    this.fallback = const Duration(hours: 14),
    this.lowerBound = const Duration(hours: 4),
    this.upperBound = const Duration(hours: 18),
    this.warmupGaps = 6,
    this.margin = 1.5,
    this.percentile = 0.9,
    this.memory = 100,
  }) : assert(percentile > 0 && percentile <= 1),
       assert(margin >= 1),
       assert(lowerBound <= upperBound);

  /// The honest cold-start window, used until enough of the rhythm is learned.
  final Duration fallback;

  /// Never alarm faster than this (a movie, a meeting are not emergencies) nor
  /// wait longer than this (even a loose rhythm gets checked within a day).
  final Duration lowerBound;
  final Duration upperBound;

  /// How many observed gaps before we trust the learned window over [fallback].
  final int warmupGaps;

  /// Headroom above the person's normal quiet stretch before it's a concern.
  final double margin;

  /// Which point of the normal-gap distribution to anchor on (0.9 = the long-but-
  /// normal stretch, ignoring the rare longest outlier).
  final double percentile;

  /// Bounded memory of recent gaps — old rhythm ages out, no growing history.
  final int memory;

  // State: durations only (minutes) + the last interaction time. Nothing else.
  final List<int> _gapMinutes = <int>[];
  DateTime? _lastInteraction;

  /// Record a sign of life. Only a genuinely *newer* interaction adds a gap, so
  /// repeated reads of the same reading (each sampling tick) are idempotent.
  void observeInteraction(DateTime at) {
    final prev = _lastInteraction;
    if (prev != null && at.isAfter(prev)) {
      _gapMinutes.add(at.difference(prev).inMinutes);
      if (_gapMinutes.length > memory) _gapMinutes.removeAt(0);
    }
    if (prev == null || at.isAfter(prev)) _lastInteraction = at;
  }

  /// True once enough normal gaps are seen to trust the learned window.
  bool get hasLearned => _gapMinutes.length >= warmupGaps;

  int get sampleCount => _gapMinutes.length;

  /// The person's long-but-normal quiet stretch (the chosen [percentile] of
  /// observed gaps), or null before warm-up.
  Duration? get typicalQuietStretch {
    if (_gapMinutes.isEmpty) return null;
    final sorted = [..._gapMinutes]..sort();
    final idx = ((sorted.length - 1) * percentile).round();
    return Duration(minutes: sorted[idx]);
  }

  /// The concern threshold to feed the detector: "longer than you normally go
  /// quiet". Falls back honestly to [fallback] until the rhythm is learned, and is
  /// always clamped to [[lowerBound], [upperBound]].
  Duration get silenceWindow {
    if (!hasLearned) return fallback;
    final typical = typicalQuietStretch!;
    final scaled = Duration(minutes: (typical.inMinutes * margin).round());
    if (scaled < lowerBound) return lowerBound;
    if (scaled > upperBound) return upperBound;
    return scaled;
  }
}
