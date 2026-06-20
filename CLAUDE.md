# CLAUDE.md — iEye

Guidance for Claude Code working in the **iEye** repository. These instructions OVERRIDE default behavior — follow them exactly.

## What This Is

**iEye** (domain `ieye.in`, pronounced "I-eye") is a **welfare / liveness app** — a vertical product built on the **Maktub Protocol**. Its job:

> If someone who lives alone goes silent, the people they chose are alerted — so they are **found in hours, not weeks.**

It exists because people who live alone die unseen and undiscovered for days or weeks. iEye collapses *time-to-discovery* from weeks → hours. It is the Maktub **Safety Trigger** use case made real. Full spec: **Maktub repo issue #274**.

**The name is the promise.** *"I eye you" = I watch over you* ("eye" as a verb — to keep watch over). It reads three ways, all aligned: *I + eye* (self + guardian); *"I'm here" + the eye that watches for the silence* (the mechanism — echoes the Beat "I'M HERE" check-in); *"I eye you"* (the promise as a sentence). All collapse into: **you will not go unseen.**

## How It Works (no protocol change)

iEye is the existing Maktub **Beat** with the manual check-in **button replaced by a sensor**. You prove you're alive by *using your phone / moving through your home*; the app auto-sends the check-in. If activity stops for a configurable window, silence becomes the trigger and the alert is delivered.

- **Detection brain (shared):** sensor fusion + a rhythm/anomaly model ("watch the pattern, not the clock" — away / asleep / anomalous-silence). Tiered sensors: Tier 0 phone-only (GPS + IMU + battery + per-location pattern), Tier 1 cheap home mesh (PIR, kettle plug, WiFi sensing), Tier 2 wrist (heart rate — the only thing that cleaves deep sleep from death).
- **Two delivery modes** (pluggable trigger sink): **Sovereign** (on-chain Maktub Beat, edge one-bit, nothing touches a server) and **Easy** (backend + Google auth + push; multi-channel: push/email/Telegram/WhatsApp/SMS/**auto-call**). For welfare, *reach = lives.*
- **Escalation ladder:** ping the owner (auto-call: "press 1 if you're okay") → one contact → the circle → "please physically check at [address]."

## Non-negotiable rules

- **The easier a trigger fires by accident, the more harmless its payload must be.** iEye's welfare alert is benign and recoverable ("go check on me") — it must **NEVER** carry or trigger an irreversible secret/will (that is a separate Maktub Beat, with a separate key). Enforce this *structurally*, not by convention.
- **False alarm > no alarm — but keep false alarms cheap.** Alarm fatigue is the only failure mode that kills. Stage escalation so battery-died cases die at rung 1–2.
- **Liveness is one bit: process at the edge, emit the bit, never the content.** Privacy by architecture, not policy. The app must not log or sync liveness telemetry (GPS traces, rhythm baseline, unlock timelines). *Interaction = life; passive playback ≠ life.*
- **Brand guardrail: iEye watches *over* you, never watches *you*.** Guardian eye / lighthouse, never a camera lens. Copy is always "looking out for / you are seen / never alone" — never "monitor / track / surveil." The brand and the privacy architecture must tell the *same* story.
- **Honest promise (Maktub D-031 spirit):** iEye promises you'll be *found by the people you chose* — never that you'll be *saved/rescued*, never *inevitable* in Easy mode (it depends on our servers), never invisibility/anonymity. This is a death product; over-trust is the headline risk.

## Market

**India-first go-to-market** (NRI families / aging parents living alone), launched **globally on all app stores**. Focus the wedge, not the availability.

## The team

The `.claude/commands/` team (Product, Security/`security`, Architect, Designer, Legal, Mobile, etc.) are the **same Maktub Protocol roles**, now also stewarding the iEye vertical. Their identities and philosophy are unchanged; apply their mandates to iEye as a Maktub vertical.

## Status / open gates (from Product + Security review on #274)

- ✅ **Green-lit to prototype now:** the on-device brain (sensor fusion + rhythm model + local escalation rungs 1–2) — *provided it signs nothing.*
- 🚧 **Architect:** scoped session key that can ONLY call `checkIn(welfareBeatId)`, non-exportable in Secure Enclave/StrongBox (a bare hot EOA owning the welfare Beat is rejected). Unblocks Sovereign mode.
- 🚧 **Security + Legal:** Easy mode is the push server Maktub D-041 gated — backend becomes a data controller of liveness/location/social-graph (health-adjacent, GDPR, robocall consent). Must clear that gate before Easy mode ships.
