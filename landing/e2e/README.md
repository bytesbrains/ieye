# Landing e2e — Playwright against a dockerized Firebase emulator

End-to-end UI tests for the landing app, run with [Playwright](https://playwright.dev)
against the **Firebase Auth + Firestore emulators running in Docker** (the
"firebase local instance in docker"). Tests drive a real browser through the real
sign-in redirect, real Firestore writes, and the real security rules.

## Layout

| Path | What |
|---|---|
| `Dockerfile.emulator` | Node + JRE + firebase-tools; runs Auth (9099) + Firestore (8080), bound to `0.0.0.0`. |
| `firebase.emulator.json` | E2E emulator config — same `firestore.rules` as prod, emulators reachable from the host. |
| `docker-compose.yml` | Builds/starts the emulator; `--wait` blocks on a Firestore healthcheck. |
| `global-setup.ts` | Waits for the emulator, then wipes Auth + Firestore so each run is clean. |
| `tests/*.spec.ts` | The specs (see below). |
| `tests/helpers.ts` | `uniqueUser`, and helpers that drive the Auth emulator's Google sign-in widget. |

The Playwright config (`../playwright.config.ts`) starts two Vite dev servers
against the emulator — port **5173** (fiat flag OFF, the default) and **5174**
(flag ON) — and runs two projects: `landing` and `fiat`.

## Run it

```bash
cd landing
npm install
npm run e2e:install     # one-time: download the Chromium browser
npm run e2e:up          # build + start the dockerized emulator (waits for healthy)
npm run e2e             # run the suite (headless)
npm run e2e:headed      # watch it: headed + slow-motion
npm run e2e:report      # open the last HTML report
npm run e2e:down        # stop the emulator
```

## Coverage

- **`landing.spec.ts`** — every public section renders with its real copy: hero,
  the gap, how-it-works (both speeds + capability claim), trust, the roadmap
  (4 tiers, honest state pills, why-funds band, honesty line), contribute
  (waitlist / skills / funder-interest), supporter wall, footer, header nav, skip
  link.
- **`routing.spec.ts`** — `/privacy`, `/terms`, unknown-path fallback, and the
  auth guards (`/account` → `/signin`, `/admin` without a claim).
- **`waitlist.spec.ts`** — the public "Continue with Google" waitlist sign-in,
  end-to-end through `signInWithRedirect` and the Auth emulator widget.
- **`account.spec.ts`** — signed-in flows: profile seeded from Google, opt-in-to-
  be-named, funder-interest, contributor request (writes to Firestore under the
  real rules).
- **`fiat.spec.ts`** (project `fiat`, flag ON) — the money panel flips to
  "contribute by card", and `/account` shows the amount picker + the full
  point-of-payment disclaimer.

## Known notes

- **Redirect-auth retries.** `waitlist.spec.ts` is configured with `retries: 2`.
  Unlike `/account` (backed by a persistent `onIdTokenChanged` listener), the
  public waitlist completes via `getRedirectResult` alone, which has a
  load-dependent race with `signInWithRedirect`'s persistence flush on a cold dev
  server. Re-running the round-trip is the standard, honest de-flake for
  redirect/OAuth e2e. `vite.config.ts` also warms the Firebase modules to reduce
  it. No production impact — prod ships a pre-bundled build.
- **Out of scope: Cloud Functions / Stripe.** The emulator runs Auth + Firestore
  only. The fiat path's Stripe checkout is an external redirect and isn't
  end-to-end-able here; the `fiat` project verifies the UI gating up to the point
  of payment. The backend gate (`functions/src/stripe.ts`) is covered by review +
  type-check, and remains off by default.
