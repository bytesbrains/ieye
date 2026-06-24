# Security Policy

iEye is a welfare / liveness app: a security flaw can mean help doesn't reach a
real person, or that someone's most private signal — *am I alive?* — leaks. We
take reports seriously and will work with you in good faith.

## Reporting a vulnerability

**Do not open a public issue for a security report.**

- **Email:** [security@ieye.in](mailto:security@ieye.in) (per our
  [`/.well-known/security.txt`](https://ieye.in/.well-known/security.txt),
  RFC 9116).
- Alternatively, use GitHub's **private vulnerability reporting**
  (Security → *Report a vulnerability*) on this repository.

Please include: what you found, the affected component (`app/` or `landing/`),
steps to reproduce, and the impact you believe it has. A proof of concept helps.

We will acknowledge your report, keep you updated on remediation, and credit you
when a fix ships (unless you prefer to stay anonymous). Please give us a
reasonable window to fix before any public disclosure.

## What we especially care about

These map to iEye's [non-negotiable guardrails](CLAUDE.md). Reports here are high
priority:

- **A path by which the welfare alert could carry or trigger an irreversible
  secret/will.** The welfare `WelfareSignal` must be benign and recoverable —
  structurally incapable of holding a secret.
- **Leakage of liveness telemetry** — GPS traces, rhythm baselines, or unlock
  timelines being logged, synced, or emitted off-device. Liveness is one bit;
  only the bit should ever leave the edge.
- **Authorization bypasses** in the web app — anything letting a client read or
  write data it shouldn't. The Firestore rules are the real security boundary,
  not the UI. See
  [`landing/firestore-tests/THREAT-MODEL.md`](landing/firestore-tests/THREAT-MODEL.md).
- **Escalation / alerting integrity** — a way to suppress, spoof, or misdirect an
  alert so help is not summoned (or is summoned falsely at scale, driving alarm
  fatigue).

## Scope

This policy covers the code in this repository (the Flutter app and the
landing / web app). The underlying [Maktub Protocol](https://maktub.it) has its
own disclosure process; report protocol-level issues there.
