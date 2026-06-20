# iEye Firestore security-rules tests

Emulator-backed unit tests for `../firestore.rules` (#43). They run entirely
against the **Firestore emulator** — no real Firebase project, no network, no
secrets.

## Run

```bash
cd landing/firestore-tests
npm install
npm test
```

`npm test` runs `firebase emulators:exec --only firestore 'vitest run'`, which
boots the emulator, executes the suite, and tears the emulator down. Requires a
JRE on PATH (the Firestore emulator is a Java process) and the Firebase CLI
(provided here as the `firebase-tools` dev dependency).

## What they prove

- a user cannot read another user's profile;
- a user cannot elevate their own role / inject an `admin`/`role`/`claims` field;
- a client cannot write `contributions` (money is backend-only) — not even an admin client;
- `publicSupporters` is world-readable but not client-writable;
- `contributorRequests` are owner-scoped and cannot be self-promoted past `requested`;
- everything outside the whitelisted collections is denied (default deny).

Admin is exercised via a **mock custom claim** (`{ admin: true }`), proving the
rules trust the Firebase Auth claim and never a Firestore field.

See `THREAT-MODEL.md` for the full data model, RBAC, and the responsibilities
that the backend / Cloud Functions must carry that rules cannot.
