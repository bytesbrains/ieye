# iEye

[![CI](https://github.com/bytesbrains/ieye/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/bytesbrains/ieye/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> *I eye you — I watch over you.*

**iEye** (`ieye.in`) is a home guardian: it **secures your home** *and* **watches over the people in it.** One promise — *watches over you, never watches you* — pointed at two threats:

- **iEye Secure** — scan your home network in two taps and find exposed cameras, devices, or weak Wi-Fi a stranger could reach, with plain fixes (or expert help). **Value on day one.**
- **iEye Watch** — if someone who lives alone goes silent, the people they chose are alerted, so they are **found in hours, not weeks.** **The reason we exist — you will not go unseen.**

Both are privacy-first: scan results and liveness are processed **on-device — never the content.** *iEye Watch* is built on the [Maktub Protocol](https://maktub.it) (the Maktub **Beat**, with the manual check-in replaced by a passive sensor — you prove you're alive by living, and silence becomes the trigger), with two delivery modes: *Sovereign* (on-chain, private, unstoppable) and *Easy* (backend + multi-channel alerts incl. auto-call). **India-first**, globally available.

> **Sponsored by BytesBrains** — the company behind iEye, offering professional help to secure your premises. Every audit funds the watch-over mission.

Spec & decisions: Maktub repo, issue #274.

> Brand guardrail: iEye watches **over** you, never watches **you**. Always "looking out for / you are seen / never alone" — never "monitor / track / surveil."

_Status: **iEye Secure** (the on-device home scan) runs today on iOS and macOS. **iEye Watch's** detection brain is prototyped; its Sovereign signing path (scoped session key) and Easy-mode backend are still in design._

## Repository

| Path | What it is |
|---|---|
| [`app/`](app/README.md) | Flutter app (iOS + Android) — the on-device detection brain |
| [`landing/`](landing/README.md) | Vite + React landing page + Phase-1.5 auth app (runs against the Firebase emulator) |
| [`docs/architecture.md`](docs/architecture.md) | How iEye is put together, and why — start here for the codebase |
| [`docs/adr/`](docs/adr/README.md) | Architecture Decision Records — the *why* behind the design |
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
