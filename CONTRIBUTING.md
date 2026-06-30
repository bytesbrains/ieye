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
| `docs/` | Architecture overview, decision records (ADRs), standards | [`docs/architecture.md`](docs/architecture.md) |
| `docs/standards/` | Enforceable engineering standards (blocking design gates) | [`docs/standards/README.md`](docs/standards/README.md) |
| `brand/` | Logo, app icon, brand assets | — |

## Getting set up

Pick the area you're working in and follow its README — both run fully locally:

- **App:** `cd app && flutter pub get && flutter run` (see `app/README.md`).
- **Landing / web app:** `cd landing && npm install && npm run dev`. The
  authenticated app runs entirely against the **Firebase emulator** — no real
  Firebase project required (see `landing/README.md`).

**Enable the secret-scanning hook (one time, every clone):**

```bash
brew install gitleaks            # or see github.com/gitleaks/gitleaks#installing
git config core.hooksPath .githooks
```

This points git at the repo's versioned [`.githooks/`](.githooks/) so every
commit is scanned for secrets before it lands. The hook **fails loudly** if
gitleaks isn't installed (a silently-skipped scan is worse than none). CI runs
the same scan as a server-side backstop, so this gate can't be quietly skipped.

## Branches

- **`dev`** is the integration branch — **all contributions target `dev`.** It is
  the repository's default branch, so new PRs are based on it automatically.
- **`main`** is the released / stable branch. It only receives merges from `dev`
  at release time (and the occasional hotfix). Don't open PRs against `main`.

## Workflow

1. **Open an issue first** for anything beyond a trivial fix, so we can agree on
   the approach before you build it. Check existing issues to avoid duplicates.
2. **Branch from `dev`.** Use a descriptive name, e.g.
   `feat/tier1-pir-source`, `fix/auth-redirect`, `docs/contributing`.
3. **Make focused changes.** One logical change per PR. Match the style of the
   surrounding code — its naming, comment density, and idioms.
4. **Commit with [Conventional Commits](https://www.conventionalcommits.org).**
   Match the existing history: `feat(app): …`, `fix(web): …`, `docs(security): …`,
   `chore: …`. Reference the issue: `feat(app): per-person rhythm baseline (#64)`.
5. **Open a PR against `dev`** using the template. Describe what changed, why,
   and how you verified it. Link the issue. CODEOWNERS will auto-request reviewers
   for guardrail-sensitive paths.

## Decisions & discussion

- **Not scoped yet? Take it to [Discussions](../../discussions)** — "should we…?"
  and "what if…?" belong in *Ideas & proposals*, questions in *Q&A*. Open an issue
  once the approach is agreed (see [setup](docs/discussions-setup.md)).
- **Touching a guardrail or making a non-obvious design call? Write an
  [ADR](docs/adr/README.md)** in the same PR — a short record of *why*. The
  [architecture overview](docs/architecture.md) is the map of how the pieces fit.

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

**Secrets (all paths):** never commit credentials. The `core.hooksPath` hook
above scans every commit, and the CI `Secrets · gitleaks scan` job re-scans on
every PR. To scan on demand: `gitleaks git --no-banner` (history) or
`gitleaks git --staged --no-banner` (your staged diff).

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
