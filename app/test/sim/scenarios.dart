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
