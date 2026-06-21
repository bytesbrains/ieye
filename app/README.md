# iEye app (Flutter)

The iEye welfare/liveness app — iOS + Android. *If someone who lives alone goes
silent, the people they chose are alerted, so they are found in hours, not weeks.*
Spec: **PRD #2**; product principles: **#1**; constraints: repo `CLAUDE.md`.

> **Status: Tier-0 prototype.** The product spine + the real phone-only rhythm
> rule are wired end-to-end behind the seams. The only stub left is the platform
> signal *source* (battery/activity need a plugin), and **no trigger sink is
> fired** — the prototype signs nothing and sends nothing off-device, per the
> green-light.

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
    detection_brain.dart    shared on-device brain interface (#11); Tier0Brain composes coverage
    phone_signals.dart      Tier-0 phone signals (#14) + injectable source (stub today)
    tier0_detector.dart     the phone-only rhythm rule (#14) — honest limits, not the dream
    coverage.dart           honest coverage state (no fake "protected" boolean)
    checker.dart            checker consent state (#17) — active accept, no silent enrolment
    circle.dart             the circle + coverage maths (#18); CircleStore (resign/undo)
    delivery_mode.dart      Easy/Sovereign + the mode-aware honest promise (#25)
  features/
    onboarding/             two-role entry: "for myself" / "for someone I care about"
    arming/                 comprehension gate (#25) — three truths + "found, not rescued" before arming
    home/                   honest-coverage home + the "going dark" flow (PRD §3C)
    checker/                checker consent handshake — invite → accept → availability → rehearsal (#17)
    circle/                 circle visibility + graceful step-down (#18)
test/widget_test.dart       unit/guardrail tests
integration_test/           on-device E2E: app_test, arming_test, tier0_test, checker_test, circle_test (+ finders.dart)
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

- Honest home for the configurer / circle dashboard (#27).
- Real platform `PhoneSignalsSource` (battery + activity + background pings) behind
  the seam; Rung-0 silent pre-check + battery-death labelling (#13); background-
  execution reliability (#15).
- Escalation ladder as lived experience (#21); auto-call (#22, Easy mode, gated).
- Real trigger sinks: Easy (#20, D-041-gated) and Sovereign (#30–#32).
