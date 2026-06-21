# iEye app (Flutter)

The iEye welfare/liveness app — iOS + Android. *If someone who lives alone goes
silent, the people they chose are alerted, so they are found in hours, not weeks.*
Spec: **PRD #2**; product principles: **#1**; constraints: repo `CLAUDE.md`.

> **Status: initial scaffold (product spine).** Runnable skeleton + the core
> architecture seams. The detection brain is a Tier-0 **stub** (no real sensors
> yet) and **no trigger sink is fired** — the prototype signs nothing and sends
> nothing off-device, per the green-light.

## What's here

```
lib/
  main.dart                 entry
  app.dart                  MaterialApp + routes; wires the shared brain
  theme/ieye_theme.dart     brand palette (lighthouse, never camera; no green shield)
  core/
    welfare_signal.dart     the ONLY payload a sink accepts — structurally cannot
                            carry a secret/will (PRD §4, non-negotiable); + the
                            escalation ladder (rungs 0–4)
    trigger_sink.dart       pluggable delivery seam (#12); LocalNoopSink signs nothing
    detection_brain.dart    shared on-device brain interface (#11); Tier0StubBrain
    coverage.dart           honest coverage state (no fake "protected" boolean)
    checker.dart            checker consent state (#17) — active accept, no silent enrolment
    circle.dart             the circle + coverage maths (#18); CircleStore (resign/undo)
  features/
    onboarding/             two-role entry: "for myself" / "for someone I care about"
    home/                   honest-coverage home + the "going dark" flow (PRD §3C)
    checker/                checker consent handshake — invite → accept → availability → rehearsal (#17)
    circle/                 circle visibility + graceful step-down (#18)
test/widget_test.dart       unit/guardrail tests
integration_test/           on-device E2E: app_test, checker_test, circle_test (+ finders.dart)
```

Coverage is read through one boundary — `DetectionBrain` composes it from sensing
(stub) + the `CircleStore`, so a checker stepping down flows straight into the
owner's honest-coverage home. No UI computes coverage ad hoc; a gap can't be hidden.

## Design constraints baked in (don't regress these)

- **Honest coverage, no fake green shield** — over-trust is the #1 product risk
  (PRD §7). The home screen renders the truth, including degraded/paused states.
- **Signs nothing (yet)** — the only wired sink is `LocalNoopSink`
  (`sendsOffDevice == false`). Sovereign (on-chain) and Easy (backend) sinks plug
  into `TriggerSink` later (#20/#30–32).
- **The welfare Beat can never carry the will** — enforced *structurally*:
  `WelfareSignal` has no field capable of holding a secret, and it's the only type
  a sink accepts. An address note exists only at the physical-check rung and is
  benign + opt-in.
- **Watches over you, never watches you** — the brain emits only coverage state;
  it must never log/sync GPS traces, rhythm baselines, or unlock timelines.

## Run

```bash
cd app
flutter pub get
flutter run            # on a simulator/device
flutter test           # unit + widget tests
flutter analyze
```

Run the on-device E2E: `flutter test integration_test -d <device-id>`.

## Next slices

- Comprehension gate before arming (#25); honest home for the configurer (#27).
- Tier-0 phone-only sensing behind `DetectionBrain` (#14): GPS + IMU + battery +
  per-location rhythm.
- Escalation ladder as lived experience (#21); auto-call (#22, Easy mode, gated).
- Real trigger sinks: Easy (#20, D-041-gated) and Sovereign (#30–#32).
