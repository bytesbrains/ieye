# CLAUDE.md — iEye

Guidance for Claude Code working in the **iEye** repository. These instructions OVERRIDE default behavior — follow them exactly.

## What This Is

**iEye** (domain `ieye.in`, pronounced "I-eye") is a **welfare / liveness app** — a vertical product built on the **Maktub Protocol**. Its job:

> **iEye gets help to you in time.** If you fall, crash, collapse, or go silent and can't call for help yourself, iEye notices and brings help — fast enough to **save a life when a life can be saved**, and fast enough that **no one is ever left undiscovered** when it can't.

It exists because people who live alone — or who have an accident with no one around — can go far too long before anyone knows. Sometimes fast help **saves a life** (a fall, a crash, a cardiac event); always it spares them being left undiscovered. iEye shrinks *time-to-help* from days/weeks to **minutes/hours**. It is the Maktub **Safety Trigger** use case made real. Full spec: **Maktub repo issue #274**. *(Framing: lead with hope — help arrives in time; dignified discovery is the floor, not the headline.)*

**The name is the promise.** *"I eye you" = I watch over you* ("eye" as a verb — to keep watch over). It reads three ways, all aligned: *I + eye* (self + guardian); *"I'm here" + the eye that watches for the silence* (the mechanism — echoes the Beat "I'M HERE" check-in); *"I eye you"* (the promise as a sentence). All collapse into: **you will not go unseen.**

## How It Works (no protocol change)

iEye is the existing Maktub **Beat / Flash** with the manual check-in **replaced by sensors**. It watches at **two speeds**:
- **Fast (acute event):** an accident detected *right now* — a hard fall, a crash, a cardiac anomaly — triggers a short "are you okay?" grace (≈10–30s), then summons help in **minutes**. (Instant paradigm → maps onto Maktub **Flash**.)
- **Slow (silence):** prolonged absence of life (you can't or don't check in) triggers an alert in **hours**. (Timer paradigm → maps onto Maktub **Beat**.)

Either way, the people you chose are reached.

- **Detection brain (shared):** sensor fusion + a rhythm/anomaly model ("watch the pattern, not the clock") that detects **both** the slow *absence* of life (away / asleep / anomalous-silence, over hours) **and** the fast *break* of an acute event (fall / crash / cardiac — escalates immediately). Tiered sensors: Tier 0 phone-only (GPS + IMU + battery + per-location pattern), Tier 1 cheap home mesh (PIR, kettle plug, WiFi sensing), Tier 2 wrist (heart rate / fall — cleaves deep sleep from collapse and powers acute detection).
- **Two delivery modes** (pluggable trigger sink): **Sovereign** (on-chain Maktub Beat, edge one-bit, nothing touches a server) and **Easy** (backend + Google auth + push; multi-channel: push/email/Telegram/WhatsApp/SMS/**auto-call**). For welfare, *reach = lives.*
- **Escalation ladder:** ping the owner (auto-call: "press 1 if you're okay") → one contact → the circle → "please physically check at [address]."

## Non-negotiable rules

- **The easier a trigger fires by accident, the more harmless its payload must be.** iEye's welfare alert is benign and recoverable ("go check on me") — it must **NEVER** carry or trigger an irreversible secret/will (that is a separate Maktub Beat, with a separate key). Enforce this *structurally*, not by convention.
- **False alarm > no alarm — but keep false alarms cheap.** Alarm fatigue is the only failure mode that kills. Stage escalation so battery-died cases die at rung 1–2.
- **Liveness is one bit: process at the edge, emit the bit, never the content.** Privacy by architecture, not policy. The app must not log or sync liveness telemetry (GPS traces, rhythm baseline, unlock timelines). *Interaction = life; passive playback ≠ life.*
- **Brand guardrail: iEye watches *over* you, never watches *you*.** Guardian eye / lighthouse, never a camera lens. Copy is always "looking out for / you are seen / never alone" — never "monitor / track / surveil." The brand and the privacy architecture must tell the *same* story.
- **Honest promise (Maktub D-031 spirit) — promise the MECHANISM, never the OUTCOME.** iEye *detects fast and summons help fast*. It **can save lives** (a capability — lead with this hope) but never *guarantees* it ("you'll always be saved"), and it is **not a substitute for emergency services**. Dignified, fast discovery is the **floor** when help can't save someone — the quiet truth underneath, never the headline. Never *inevitable* in Easy mode (depends on our servers); never invisibility/anonymity. Over-trust is still the headline risk — guard it by promising *effort*, not *outcomes*.

## Market

**India-first go-to-market** (NRI families / aging parents living alone), launched **globally on all app stores**. Focus the wedge, not the availability.
