# Contributing to iEye

Thank you for wanting to help. iEye is a welfare / liveness app — *if someone
who lives alone goes silent, the people they chose are alerted, so they are found
in hours, not weeks.* Code here can affect whether help reaches a real person in
time, so we hold a few lines firmly. Read this once before your first PR.

> **New here?** Skim the [README](README.md) for what iEye is, then
> [`CLAUDE.md`](CLAUDE.md) for the product principles. They are short and they
> are the source of truth for the guardrails below.

## The non-negotiable guardrails

These come from [`CLAUDE.md`](CLAUDE.md) and are **enforced structurally, not by
convention**. A PR that weakens any of them will be asked to change, however good
the rest of it is.

1. **The welfare alert is benign and recoverable.** It says "go check on me" — it
   must **never** carry or trigger an irreversible secret/will. `WelfareSignal`
   has no field that can hold a secret, and it's the only type a sink accepts.
   Don't add one.
2. **Liveness is one bit — process at the edge, emit the bit, never the content.**
   The app must not log or sync liveness telemetry (GPS traces, rhythm baselines,
   unlock timelines). Privacy by architecture, not policy.
3. **iEye watches *over* you, never watches *you*.** Copy is always "looking out
   for / you are seen / never alone" — never "monitor / track / surveil." The
   guardian-eye / lighthouse, never a camera lens.
4. **Promise the mechanism, never the outcome.** iEye *can* save a life
   (a capability) — it never *guarantees* one, and it is **not a substitute for
   emergency services**. Over-trust is the headline risk. See
   [`HonestyLine.tsx`](landing/src/components/HonestyLine.tsx) — don't fork the
   wording, reuse the component.
5. **False alarm > no alarm — but keep false alarms cheap.** Alarm fatigue is the
   failure mode that kills. Stage escalation so cheap causes (battery died) resolve
   at the low rungs. No fake green "protected" shield — render the honest coverage
   state, including degraded/paused.

If a change touches honesty copy, legal pages, or consent wording, the
[CODEOWNERS](.github/CODEOWNERS) legal gate auto-requests a review — that's
expected, not a rejection.

## Repository map

| Path | What it is | Setup |
|---|---|---|
| `app/` | Flutter app (iOS + Android), the on-device detection brain | [`app/README.md`](app/README.md) |
| `landing/` | Vite + React landing page + Phase-1.5 auth app | [`landing/README.md`](landing/README.md) |
| `docs/standards/` | Enforceable engineering standards (blocking design gates) | [`docs/standards/README.md`](docs/standards/README.md) |
| `brand/` | Logo, app icon, brand assets | — |

## Getting set up

Pick the area you're working in and follow its README — both run fully locally:

- **App:** `cd app && flutter pub get && flutter run` (see `app/README.md`).
- **Landing / web app:** `cd landing && npm install && npm run dev`. The
  authenticated app runs entirely against the **Firebase emulator** — no real
  Firebase project required (see `landing/README.md`).

## Workflow

1. **Open an issue first** for anything beyond a trivial fix, so we can agree on
   the approach before you build it. Check existing issues to avoid duplicates.
2. **Branch** from `main`. Use a descriptive name, e.g.
   `feat/tier1-pir-source`, `fix/auth-redirect`, `docs/contributing`.
3. **Make focused changes.** One logical change per PR. Match the style of the
   surrounding code — its naming, comment density, and idioms.
4. **Commit with [Conventional Commits](https://www.conventionalcommits.org).**
   Match the existing history: `feat(app): …`, `fix(web): …`, `docs(security): …`,
   `chore: …`. Reference the issue: `feat(app): per-person rhythm baseline (#64)`.
5. **Open a PR** against `main` using the template. Describe what changed, why,
   and how you verified it. Link the issue. CODEOWNERS will auto-request reviewers
   for guardrail-sensitive paths.

## Quality gates

Run these locally before opening a PR — CI and reviewers expect them green:

**App (`app/`):**
```bash
flutter analyze
flutter test
```

**Landing (`landing/`):**
```bash
npm run build        # type-check + production build
```
Firestore rules changes must keep the emulator-backed rules tests passing
(`landing/firestore-tests/`). The rules are the real security boundary, not the
UI — see [`THREAT-MODEL.md`](landing/firestore-tests/THREAT-MODEL.md).

## Reporting bugs & requesting features

Use the [issue templates](.github/ISSUE_TEMPLATE). For anything
**security-sensitive, do not open a public issue** — follow
[SECURITY.md](SECURITY.md) instead.

## Code of Conduct

Participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). Be kind;
assume good faith.

## Licensing

iEye is [MIT licensed](LICENSE). By contributing, you agree that your
contributions are licensed under the same terms.
