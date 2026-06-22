# IoT "One-Bit-at-the-Edge" Design-Review Standard

**Status:** ACTIVE · **Owner:** CISO · **Co-signer:** Legal · **Issue:** #68 (parent epic #60)
**Applies to:** every new liveness/sensor source integration — Tier‑1 home mesh (#65), Tier‑2 wearable (#66), Tier‑3 custom HW (#67), and any future source.

> **This is a blocking gate.** No source-integration PR merges without passing the checklist below and recording the CISO + Legal sign-off. The line cannot slip per‑vendor; if a vendor SDK cannot meet it, the vendor is rejected, not the rule.

---

## Why this exists

Cloud IoT vendors default to phoning **raw telemetry** home — motion histories, presence timelines, device traces — to *their* servers. iEye's non‑negotiable (CLAUDE.md) is the opposite:

> **Liveness is one bit: process at the edge, emit the bit, never the content.** Privacy by architecture, not policy.

A welfare app that leaked a person's movement/sleep/HR timeline — to us *or* to a vendor cloud — would betray the brand promise ("watches **over** you, never watches **you**") and create controller‑grade liability under GDPR / DPDP / PDPA for health‑adjacent and location data. Every new sensor is a new chance to breach that line by accident. This standard makes the line a **design-review gate**, checked before any integration is opened.

It is deliberately short and enforceable. It maps each rule to the **code boundary that already exists**, so "compliant" means a concrete, reviewable structural fact — not a promise.

---

## The five rules

### 1. Only at‑the‑edge assessments cross the brain boundary
A source may emit only a `LivenessAssessment` (`app/lib/core/liveness_source.dart`): a status (`alive / degraded / silent / lostContact`), an optional honest caveat, and a coarse last‑sign‑of‑life time. It must **never** hand the brain raw traces — no GPS tracks, no PIR event logs, no HR series, no per‑event timeline.
**Reviewable fact:** the integration's `LivenessSource.assess()` returns a `LivenessAssessment` computed on‑device; the raw signal type never leaves the source object.

### 2. No third‑party cloud round‑trip for liveness
Deciding "is this person alive" must happen **on the device**. A source must not POST sensor data to a vendor cloud and read an inference back. If a vendor SDK *requires* its cloud to interpret the sensor (i.e. the device cannot run the assessment locally), the integration is **rejected**.
**Reviewable fact:** the source's hot path makes no network call to interpret liveness. Local control APIs (e.g. a LAN/Matter/BLE read of a plug's on/off state) are fine; cloud inference is not.

### 3. Benign payload only — `WelfareSignal`, and no tier may widen it
The only thing a tier may ever cause to be delivered is a `WelfareSignal` (`app/lib/core/welfare_signal.dart`) — benign, recoverable, "go check on me". No integration may add a field, blob, or side‑channel to what the trigger carries, and **none may ever carry or trigger an irreversible secret/will** (that is a separate Maktub Beat, separate key, separate app).
**Reviewable fact:** the integration adds no new payload type to the `TriggerSink` seam; `WelfareSignal` remains a `final` class with no free‑form bytes.

### 4. No camera / lens sources
No source may be a camera or any lens‑based imager (still, video, or depth/IR camera). The guardian eye is a *lighthouse, not a lens* (CLAUDE.md brand guardrail). mmWave/radar presence (no image) and non‑imaging sensors are permitted; anything that captures a picture of the person is **rejected** at design review.
**Reviewable fact:** the integration's sensor list contains no camera/imager.

### 5. On‑device only, including learned state
Any per‑person model a source feeds (e.g. the rhythm baseline, #64) learns and lives **on‑device only** — no baseline, trace, or timeline is serialized off‑device or synced to a server. Easy mode is **not** an exception: the D‑041 push‑server gate still stands, and even there liveness is one bit.
**Reviewable fact:** the model/state object exposes no serialize / sync / network surface and retains only bounded, non‑identifying aggregates (cf. `RhythmModel`, which holds gap *durations* only — no timeline).

---

## Design-review checklist (paste into every source-integration PR)

```
IoT edge-liveness gate (docs/standards/iot-edge-liveness-standard.md)
- [ ] Source emits only LivenessAssessment across the brain boundary — no raw traces.
- [ ] Liveness is decided on-device; no cloud round-trip to interpret the sensor.
- [ ] No new trigger payload; WelfareSignal unchanged; no secret/will path.
- [ ] No camera / lens / imager source.
- [ ] Any learned/per-person state is on-device only (no serialize/sync/egress).
- [ ] CISO sign-off:  __________
- [ ] Legal sign-off: __________
```

A PR that cannot tick every box is **not** a design problem to negotiate — it is out of scope for iEye until it can.

---

## Sign-off

**CISO (security mandate).** The five rules above are each pinned to an existing, reviewable code boundary (`LivenessSource` / `LivenessAssessment`, `WelfareSignal`/`TriggerSink`, on‑device `RhythmModel`), so conformance is a structural fact a reviewer can verify, not a vendor promise. This is enforce‑structurally‑not‑by‑convention applied to the sensor frontier. **Approved as the blocking gate for all Tier‑1+ source integrations.** — CISO

**Legal (counsel mandate).** The standard keeps iEye off the controller path for health‑adjacent and location data by ensuring such data is neither transmitted nor stored off‑device (GDPR / UK‑GDPR, India DPDP, Singapore PDPA). Rule 2 (no cloud inference) and Rule 5 (on‑device learned state) are the load‑bearing clauses for that posture; Rule 3 preserves the welfare/secret separation that keeps the benign trigger benign. The D‑041 push‑server gate for Easy mode is unaffected and still required separately. **Approved; this gate must be linked from and block the Tier‑1 integrations issue (#65).** — Legal

> Sign-off is captured by merging this standard to `main`. Re-review is required if any of the five rules is amended.
