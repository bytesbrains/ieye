# iEye — web app (Phase 1 landing + Phase 1.5 auth)

The public, hope-first landing page for **iEye** — a welfare / liveness app built on the
Maktub Protocol: _iEye gets help to you in time_ — plus the **Phase-1.5 authenticated app**
(#43): Google sign-in, a user account, and an admin shell, built on top of the
Firestore security rules and runnable entirely against the **Firebase emulator** (no real
Firebase project required).

## Stack

- **Vite + React 18 + TypeScript**
- **Tailwind CSS** (warm-paper / charcoal base, beacon-amber accent, twilight-teal)
- **Firebase** (Auth + Firestore) — emulator in dev, real project later (#42)
- **react-router-dom** for client routing
- Static build → `dist/`, **Firebase Hosting-ready**

## Routes

| Path | Access | What it is |
|---|---|---|
| `/` | public, no auth, **no Firebase** | Phase-1 landing (unchanged) |
| `/signin` | public | Google sign-in |
| `/account` | signed-in user | profile, opt-in-to-be-named, contribution history, contributor request |
| `/admin` | **admin custom claim only** | request queue (advance status) + read-only contributions / users |

Firebase is **code-split** out of the public landing: a first-time visitor to `/` never
downloads it. The auth bundle (`AuthShell`) loads only when you hit an auth'd route.

## Run (public landing only)

```bash
cd landing
npm install
npm run dev      # http://localhost:5173
npm run build    # type-check + production build to dist/
```

## Run the full Phase-1.5 app against the Firebase emulator (no real project)

You need a **JRE on PATH** (the Firestore/Auth emulators are Java processes). The Firebase
CLI ships as a dev dependency here (`firebase-tools`), so `npm run emulators` works after
`npm install`.

```bash
cd landing
npm install
cp .env.example .env        # keeps VITE_USE_EMULATOR=true — no real project needed

# Terminal 1 — start the Auth (9099) + Firestore (8080) emulators + UI:
npm run emulators           # or: npm run emulators:seed to persist data between runs

# Terminal 2 — start the app (it auto-connects to the emulators in dev):
npm run dev                 # http://localhost:5173
```

Open `http://localhost:5173/signin` and **Continue with Google**. The Auth emulator shows a
fake account picker — pick or create a test user. You'll land on `/account` with a profile
seeded from that emulator user. The emulator UI (printed in Terminal 1, usually
`http://127.0.0.1:4000`) lets you inspect `users` / `contributorRequests` documents.

### Grant a local test user the admin claim (to view `/admin`)

Admin is a **Firebase Auth custom claim** (`admin == true`), never a Firestore field. In
production it's minted only by a secured backend (THREAT-MODEL §4). For local dev:

```bash
# After signing in once via the app (so the emulator user exists):
npm run grant-admin -- you@example.com
```

This calls the Auth emulator's admin REST API to set `{ admin: true }` on that user. Then
**sign out and back in** (or reload) so the refreshed ID token carries the claim — the
`/admin` link appears and the route unlocks.

### Seed a test contribution / wall entry (optional)

The app never writes `contributions` or `publicSupporters` (backend-only). To see populated
data locally, add docs via the **emulator UI** (`http://127.0.0.1:4000` → Firestore):

- `contributions/<id>`: `{ ownerUid: "<your-uid>", kind: "money", method: "card", amountWei: "1000000000000000", asset: "ETH", status: "recorded", timestamp: <now> }` — shows in your account history and the admin ledger.
- `publicSupporters/<id>`: `{ displayName: "A. Supporter", publishedAt: <now>, featured: false }` — world-readable wall projection.

## Structure

```
landing/
├─ firebase.json            # Hosting → dist/ + Auth/Firestore emulator config
├─ firestore.rules          # security boundary (the real authz)
├─ firestore.indexes.json   # composite indexes
├─ .env.example             # emulator switch + Firebase config seam (#42)
├─ scripts/
│  └─ grant-admin.mjs       # LOCAL ONLY: mint admin claim in the Auth emulator
├─ firestore-tests/         # emulator-backed rules tests
└─ src/
   ├─ App.tsx               # public landing assembly (Phase 1)
   ├─ main.tsx              # router + lazy auth shell
   ├─ auth/
   │  ├─ AuthProvider.tsx   # auth state + admin claim (custom-claim only)
   │  ├─ guards.tsx         # RequireAuth / RequireAdmin route guards
   │  └─ AuthShell.tsx      # lazy Firebase boundary
   ├─ pages/                # SignIn, Account, Admin
   ├─ components/app/       # AppHeader, GoogleSignInButton, OptInToggle, Spinner, …
   └─ lib/
      ├─ firebase.ts        # SDK init + emulator connection seam
      ├─ types.ts           # Firestore data-model types (THREAT-MODEL §2)
      ├─ useUserDoc.ts      # own users/{uid} read + opt-in upsert
      ├─ useContributions.ts# own contributions (read-only)
      ├─ useContributorRequest.ts # create + read own requests
      └─ admin.ts           # admin reads + advance-request (claim-gated by rules)
```

## Security constraints honored (THREAT-MODEL §7)

1. **Never writes `contributions` from the client** — money is backend-only; the app only reads.
2. **Admin via the ID-token custom claim** (`getIdTokenResult().claims.admin`), never a Firestore read or `role` field.
3. **Public wall reads `publicSupporters` only** — never private `users`/`contributions` docs.
4. **`contributorRequests`** created with `ownerUid == auth.uid` and `status: 'requested'`; only admins advance status.
5. **Opt-in-to-be-named toggles** live on the user's own `users` doc, default **off**, framed honestly as a *request to publish* the backend mediates (and can withdraw).

The UI is **not** the security boundary — `firestore.rules` is. The guards are convenience
redirects; the rules deny unauthorized access regardless of what renders.

## What's stubbed / pending (before go-live)

- **Real Firebase project (#42):** flip `VITE_USE_EMULATOR=false` and fill the `VITE_FIREBASE_*` vars.
- **Backend / Cloud Functions:** writing the `contributions` ledger (payment webhooks, reconciliation, AML/sanctions), building `publicSupporters` from consent (and honoring withdrawal), minting/revoking admin claims, sending contributor invitations, cascade cleanup on erasure. These are backend-only by design — the app calls out every such spot.
- **Money (Phase 2, Legal-gated #39):** no live payment UI yet.
- The Phase-1 landing forms (`src/lib/submit.ts`) remain stubbed.

## Brand + honesty guardrails honored

- Hope-first; "contribution" never "donation"; opt-in = request-to-publish; capability never guarantee.
- Lighthouse-not-camera; no alarm-red; no green "protected" shield.
- Accessibility: semantic HTML, 18px+ base, visible focus, keyboard + screen-reader friendly, `aria-checked` switches, respects `prefers-reduced-motion`.

## Deploy (do NOT run until the project exists)

```bash
# After the real BytesBrains Firebase project (#42) exists and .env is set:
npm run build && firebase deploy --only hosting
```
