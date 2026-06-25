# iEye

[![CI](https://github.com/bytesbrains/ieye/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/bytesbrains/ieye/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> *I eye you — I watch over you.*

**iEye** (`ieye.in`) is a welfare / liveness app: if someone who lives alone goes silent, the people they chose are alerted — so they are **found in hours, not weeks.**

A vertical product built on the [Maktub Protocol](https://maktub.it) — the existing Maktub **Beat** with the manual check-in replaced by a passive sensor. You prove you're alive by living; when activity stops, silence becomes the trigger.

- **You will not go unseen.** iEye exists because people who live alone die undiscovered for days or weeks.
- **Watches *over* you, never watches *you*.** Liveness is one bit, processed on-device — never the content. Privacy by architecture.
- **Two modes:** *Sovereign* (on-chain, private, unstoppable) and *Easy* (frictionless backend + multi-channel alerts incl. auto-call).
- **India-first**, globally available.

Spec & decisions: Maktub repo, issue #274.

> Brand guardrail: iEye watches **over** you, never watches **you**. Always "looking out for / you are seen / never alone" — never "monitor / track / surveil."

_Status: pre-development. The on-device detection brain is the first prototype; the Sovereign signing path (scoped session key) and Easy mode (backend) are still in design._

## Repository

| Path | What it is |
|---|---|
| [`app/`](app/README.md) | Flutter app (iOS + Android) — the on-device detection brain |
| [`landing/`](landing/README.md) | Vite + React landing page + Phase-1.5 auth app (runs against the Firebase emulator) |
| [`docs/standards/`](docs/standards/README.md) | Enforceable engineering standards (blocking design gates) |
| [`brand/`](brand/) | Logo, app icon, brand assets |
| [`CLAUDE.md`](CLAUDE.md) | Product principles & the non-negotiable guardrails — start here |

## Contributing

Contributions are welcome. Please read **[CONTRIBUTING.md](CONTRIBUTING.md)** and
the [non-negotiable guardrails](CLAUDE.md) before opening a PR, and be aware of our
[Code of Conduct](CODE_OF_CONDUCT.md).

- 🌱 Base your work on **`dev`** (the default branch); `main` is released/stable.
- 🐛 Bugs & ✨ features: use the [issue templates](.github/ISSUE_TEMPLATE).
- 🔒 Security: **never** in a public issue — see [SECURITY.md](SECURITY.md).

iEye is [MIT licensed](LICENSE).
