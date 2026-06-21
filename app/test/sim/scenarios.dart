import 'replay.dart';

/// The initial Tier-0 scenario library (#63). Both classes are represented —
/// "should stay quiet" (normal life that must NOT trip an alarm) and "should
/// escalate" (a real silence / lost-contact that must) — so the harness measures
/// false-alarm rate AND detection latency, not just one side.
///
/// All scenarios keep the battery healthy, a safe circle, and a reaching sink, so
/// the ONLY thing that can degrade coverage is a sensing concern — making a degrade
/// an unambiguous escalation to score against.
///
/// The fixed-14h silence window is the thing under test here; #64 (per-person
/// rhythm) will add adversarial cases (e.g. a night-shift rhythm) where a learned
/// window must beat this constant, and must not regress these.
List<Scenario> tier0ScenarioLibrary() => [
  // ---- should stay quiet ----
  const Scenario(
    name: 'ordinary day — regular phone use',
    duration: Duration(hours: 16),
    frames: [
      TraceFrame(at: Duration.zero), // fresh interaction
      TraceFrame(at: Duration(hours: 3)),
      TraceFrame(at: Duration(hours: 6)),
      TraceFrame(at: Duration(hours: 9)),
      TraceFrame(at: Duration(hours: 12)),
      TraceFrame(at: Duration(hours: 15)),
    ],
    expect: Expect.quiet(),
  ),
  const Scenario(
    name: 'overnight sleep — normal 8h gap',
    duration: Duration(hours: 12),
    frames: [
      TraceFrame(at: Duration.zero), // last touch before bed
      TraceFrame(at: Duration(hours: 8)), // up in the morning, 8h < window
    ],
    expect: Expect.quiet(),
  ),
  const Scenario(
    name: 'weekend away — light phone use (6h gaps)',
    duration: Duration(hours: 18),
    frames: [
      TraceFrame(at: Duration.zero),
      TraceFrame(at: Duration(hours: 6)),
      TraceFrame(at: Duration(hours: 12)),
    ],
    expect: Expect.quiet(),
  ),
  const Scenario(
    // Silence climbs toward the window, but the person checks in at 13h and
    // resets it — the brain must NOT have fired early.
    name: 'long quiet stretch, then a check-in before the window',
    duration: Duration(hours: 18),
    frames: [
      TraceFrame(at: Duration.zero),
      TraceFrame(at: Duration(hours: 13)), // back under the wire
    ],
    expect: Expect.quiet(),
  ),

  // ---- should escalate ----
  const Scenario(
    // Last sign of life at 1h, then nothing. The fixed 14h window crosses at 15h.
    name: 'genuine collapse — silence past the window',
    duration: Duration(hours: 20),
    frames: [
      TraceFrame(at: Duration.zero),
      TraceFrame(at: Duration(hours: 1)), // final interaction
    ],
    expect: Expect.alarm(
      triggerAt: Duration(hours: 1), // onset = last sign of life
      within: Duration(hours: 14, minutes: 30), // ≈ the honest Tier-0 latency
    ),
  ),
  const Scenario(
    // Phone goes unreachable at 4h (battery dead / OS-killed). Phone-only can't
    // tell this from an emergency, so it must surface lost contact immediately.
    name: 'phone lost contact (dead battery / killed)',
    duration: Duration(hours: 8),
    frames: [
      TraceFrame(at: Duration.zero),
      TraceFrame(at: Duration(hours: 4), reachable: false),
    ],
    expect: Expect.alarm(
      triggerAt: Duration(hours: 4),
      within: Duration(minutes: 30), // next sample — effectively immediate
    ),
  ),
];

/// Frames of a person interacting on a regular cadence — the warm-up the rhythm
/// model learns from. Each frame is a fresh interaction (silence clock reset).
List<TraceFrame> regularInteractions({
  required Duration every,
  required Duration until,
}) {
  final frames = <TraceFrame>[];
  for (var t = Duration.zero; t <= until; t += every) {
    frames.add(TraceFrame(at: t));
  }
  return frames;
}

/// Two contrasting people that expose the fixed-window flaw (#64). A SINGLE global
/// window cannot serve both: tight enough to catch the regular-rhythm collapse
/// fast, it cries wolf on the loose-rhythm person's ordinary life. A per-person
/// learned window gives each their own — the measurable win.

/// A tight-rhythm person (interacts ~every 2.5h) who then collapses. A learned
/// window should catch this in hours; the fixed 14h would wait far too long.
Scenario regularRhythmThenCollapse() => Scenario(
  name: 'regular-rhythm user collapses (per-person should catch fast)',
  duration: const Duration(hours: 28),
  frames: regularInteractions(
    every: const Duration(hours: 2, minutes: 30),
    until: const Duration(hours: 20), // last sign of life at 20h, then silence
  ),
  expect: const Expect.alarm(
    triggerAt: Duration(hours: 20),
    within: Duration(hours: 6), // the sensitivity target both policies must meet
  ),
);

/// A loose-rhythm person whose ordinary life has 6h gaps — must NOT alarm. A tight
/// global window (set to catch the regular person fast) false-alarms here; the
/// learned per-person window does not.
Scenario looseRhythmNormalLife() => Scenario(
  name: 'loose-rhythm user, ordinary life (6h gaps)',
  duration: const Duration(hours: 40),
  frames: regularInteractions(
    every: const Duration(hours: 6),
    until: const Duration(hours: 40),
  ),
  expect: const Expect.quiet(),
);
