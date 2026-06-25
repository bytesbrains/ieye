# Architecture

How iEye is put together, and *why* it's shaped this way. If you're new, read the
[README](../README.md) for what iEye is and [`CLAUDE.md`](../CLAUDE.md) for the
non-negotiable guardrails first — this document assumes both. Where the design
follows from a guardrail, that guardrail is the reason; this page just shows where
it lives in the code.

> One line: **iEye is the Maktub Beat with the manual check-in replaced by a
> passive sensor.** You prove you're alive by living; when the signs of life stop,
> silence becomes the trigger, and the people you chose are reached.

## The shape

```
        signs of life (phone today; mesh / wrist later)
                 │
                 ▼
        ┌──────────────────┐   each source emits a VERDICT, never a raw trace
        │ LivenessSource×N │   (alive / degraded / silent / lostContact)
        └────────┬─────────┘
                 │  LivenessAssessment (one bit + honest caveat)
                 ▼
        ┌──────────────────┐   SHARED brain: fuse sources + circle health
        │  DetectionBrain  │   into one honest CoverageState. Never logs or
        └────────┬─────────┘   syncs telemetry — emits coverage, nothing else.
                 │
        ┌────────┴─────────┐
        ▼                  ▼
   CoverageState      WelfareSignal   ← the ONLY payload a sink accepts;
   (honest UI)             │            benign + recoverable, secrets unrepresentable
                          ▼
                  ┌──────────────┐    pluggable delivery seam (mode = backend,
                  │ TriggerSink  │    not two apps): LocalNoopSink today;
                  └──────────────┘    SovereignSink / EasySink later
```

Everything above the `TriggerSink` line is the **shared detection brain**. The
mode (Sovereign / Easy) only swaps what's *below* the line. That separation is the
spine of the whole design.

## The parts

All of this lives in [`app/lib/core/`](../app/lib/core).

### LivenessSource — one honest signal
[`liveness_source.dart`](../app/lib/core/liveness_source.dart). Each source reads
one thing (a phone today; a PIR sensor, a kettle plug, a wrist heart-rate monitor
later) and decides on-device: `alive`, `degraded`, `silent`, or `lostContact`. It
hands across a `LivenessAssessment` — a verdict plus an honest caveat (e.g.
"battery low") — and **never a raw trace.** This boundary is what keeps *liveness
is one bit, at the edge* true no matter how many sensors we add.

A dead or out-of-range sensor reports `lostContact`, which is **not** an
all-clear. A silent sensor must never read as "everything's fine."

### DetectionBrain — the shared fusion core
[`detection_brain.dart`](../app/lib/core/detection_brain.dart). Fuses N sources
plus the circle's reachability into one `CoverageState`, pushed as a stream as it
changes. It watches at **two speeds**:

- **Slow (silence):** prolonged absence of life → alert in *hours*. (Maktub Beat.)
- **Fast (acute):** a hard fall / crash / cardiac anomaly → short grace, then
  summon help in *minutes*. (Maktub Flash.) Designed-for, Tier-2 wrist; not wired
  in Tier-0 yet.

Tier-0 (phone-only: GPS + IMU + battery + per-location pattern) is just one
instance of this brain with a single source. The same brain takes home-mesh and
wrist sources past Tier-0 — the fusion rule doesn't change, only the source set.

**Privacy is architectural here:** the brain emits coverage state and nothing
else. It must never log or sync GPS traces, rhythm baselines, or unlock timelines.
If a change makes the brain persist or transmit telemetry, that change is wrong by
construction, not by policy.

### CoverageState — honest UI, by construction
[`coverage.dart`](../app/lib/core/coverage.dart). There is deliberately **no single
`protected` boolean and no green shield.** The home screen renders whatever is
true — `watching`, `degraded`, `pausedGoingDark`, `notArmed` — each with a plain
reason. Over-trust is the #1 product risk, so honest coverage is a launch blocker,
not polish. "Going dark" (planned absence) is a first-class state because telling
the circle "this is intentional" is the single biggest alarm-fatigue killer.

### WelfareSignal — the benign payload
[`welfare_signal.dart`](../app/lib/core/welfare_signal.dart). The **only** payload
a sink ever accepts. It's a `final` class whose fields can hold nothing but benign,
recoverable welfare data: a `kind`, an escalation `rung`, and — only at the
physical-check rung — an opt-in, owner-pre-authorised `addressNote`. There is no
`bytes`, no `payload`, no `secret`. A secret/will isn't merely discouraged here —
it is **unrepresentable.** The type system is the guard.

> This is the structural enforcement of guardrail #1: *the welfare alert is benign
> and recoverable; it must never carry an irreversible secret/will.* A dead battery
> while hiking must never deliver a will to your heirs. If you ever feel the urge
> to add a free-form field to `WelfareSignal`, that's the guardrail talking — don't.

### TriggerSink — the pluggable delivery seam
[`trigger_sink.dart`](../app/lib/core/trigger_sink.dart) +
[`delivery_mode.dart`](../app/lib/core/delivery_mode.dart). The seam takes only a
`WelfareSignal`, never a raw blob, so a sink can never be handed a secret. Each
sink exposes `sendsOffDevice` so the UI never overclaims reach.

- **`LocalNoopSink`** (today) — signs nothing, sends nothing off-device; records
  intent locally so escalation logic can be built and tested without any key or
  backend. This is what keeps the prototype inside the green-light.
- **`SovereignSink`** (later) — on-chain Maktub Beat + scoped session key.
  Delivery can't be stopped, but check-in fact/timing is public and permanent.
- **`EasySink`** (later) — backend timer + multi-channel dispatch (push / email /
  Telegram / WhatsApp / SMS / auto-call). May promise *reach*, never inevitability
  — it depends on iEye's servers existing.

The two modes' honest promises differ at this leaf, and the difference is
load-bearing — see `DeliveryMode.honestPromise`.

### The escalation ladder
Staged so cheap causes resolve at low rungs: ping the owner (auto-call, "press 1
if you're okay") → one contact → the circle → "please physically check at
[address]." *False alarm > no alarm — but keep false alarms cheap*, because alarm
fatigue is the failure mode that kills.

## Two delivery modes (one brain)

| | Sovereign | Easy |
|---|---|---|
| Delivery | On-chain Maktub Beat; nothing touches a server | Backend + multi-channel (incl. auto-call) |
| Promise | Can't be stopped | Reach — never "inevitable" |
| Cost | Check-in fact/timing public & permanent on-chain | Depends on our servers existing |
| Status | Design | Design (Tier-0 prototype uses `LocalNoopSink`) |

"Mode" is a **delivery backend, not two apps.** The detection brain is identical.

## Repository layout

| Path | What it is |
|---|---|
| [`app/`](../app/README.md) | Flutter app (iOS + Android) — the on-device detection brain |
| [`landing/`](../landing/README.md) | Vite + React landing page + Phase-1.5 auth app (Firebase emulator) |
| [`docs/standards/`](standards/README.md) | Enforceable engineering standards (blocking design gates) |
| [`docs/adr/`](adr/README.md) | Architecture Decision Records — *why* the design is the way it is |
| [`brand/`](../brand) | Logo, app icon, brand assets |

## Where the guardrails are enforced

Each non-negotiable from `CLAUDE.md` has a structural home — not a code review
checkbox, a place in the type system or the rendered state:

| Guardrail | Enforced by |
|---|---|
| Benign payload, never a secret/will | `WelfareSignal` has no field that can hold one |
| Liveness is one bit, at the edge | `LivenessSource` emits a verdict, never a trace; brain emits only `CoverageState` |
| No over-trust / no fake "protected" | `CoverageState` has no `protected` boolean; renders degraded/paused honestly |
| Promise mechanism, never outcome | `DeliveryMode.honestPromise`; `HonestyLine` on the web |
| Cheap false alarms | Staged escalation rungs; `goDark()` first-class |

When you change any of these areas, you're touching a guardrail. Record the *why*
in an [ADR](adr/README.md), and expect the [CODEOWNERS](../.github/CODEOWNERS) gate
to ask for a review — that's the system working, not a rejection.

## Further reading

- [`CLAUDE.md`](../CLAUDE.md) — product principles & non-negotiable guardrails
- [`docs/standards/`](standards/README.md) — blocking engineering gates
- [`docs/adr/`](adr/README.md) — decision history
- Maktub repo, issue #274 — full spec & the Safety Trigger use case
