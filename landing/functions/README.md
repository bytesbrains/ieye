# iEye web backend — Cloud Functions (non-money)

Trusted backend for the iEye contribution web app. The Admin SDK here runs with
full privileges and **bypasses Firestore security rules**, so everything a client
must not be trusted to do lives in this codebase — and each function enforces its
own authorization. Region: **asia-south1** (next to Firestore). **No money paths**
— the contributions ledger, payment webhooks, and AML/sanctions screening are a
later, Legal-gated phase (#39).

## Functions

| Function | Type | What it does |
|---|---|---|
| `grantAdmin` | callable | Mint the `admin` custom claim. **Admin-only** (caller's own token claim is checked). Audited. |
| `revokeAdmin` | callable | Remove the `admin` claim. Admin-only. Audited. **Refuses to remove the last admin** (no lockout). |
| `onUserWritten` | Firestore trigger | Records a consent change to the append-only `consentLog`, then rebuilds the user's `publicSupporters` entry from their consent (opt-in name / amount). Opting out or deleting the account removes the entry — **withdrawal is honored**. |
| `onContributionWritten` | Firestore trigger | Re-projects a supporter when their contributions change (amount may move). |
| `onContributorRequestInvited` | Firestore trigger | On a request advancing to `invited`, stamps `invitedAt` and enqueues an invitation email. |

### Authorization model
- `admin` is a **custom claim**, never a Firestore field. Only these functions
  mint it; a client can never write its own. Bootstrapping the *first* admin is a
  one-time out-of-band Admin SDK act; after that admins manage each other here.
- The `publicSupporters` projection contains **only consented fields** and is the
  only thing the public wall reads (no private doc is ever exposed by rules). It is
  keyed by a **random id, never the uid**, and carries no uid field, so listing the
  world-readable wall reveals nothing about *who* its supporters are (an amount-only
  opt-in stays anonymous). The private `supporterIndex` (uid → public id) lets the
  backend still find and rebuild/remove a user's entry.
- `adminAudit` (grant/revoke trail), `consentLog` (tamper-evident consent record),
  `supporterIndex`, and `mail` (outbox) are written only by the Admin SDK; no client
  allow-rule matches them, so default-deny blocks all clients.

## Develop

```bash
cd landing/functions
npm install
npm run build        # tsc -> lib/

# run locally against the emulator (from landing/)
cd .. && npm run emulators       # includes the functions emulator on :5001
```

The web app auto-connects to the functions emulator in dev (`VITE_USE_EMULATOR=true`,
`VITE_EMULATOR_FUNCTIONS_PORT`).

## Deploy

```bash
# from landing/
firebase deploy --only functions --project ieye-in
```

Requires the **Blaze** plan and these APIs (auto-enabled on first deploy): Cloud
Functions, Cloud Run, Eventarc, Pub/Sub, Cloud Build, Artifact Registry, Compute.

## Enable email sending (optional, when ready)

The invitation function writes a doc to the **`mail`** collection in the shape the
[Trigger Email from Firestore](https://extensions.dev/extensions/firebase/firestore-send-email)
extension consumes (`{ to, message: { subject, html } }`). Until that extension (or
an equivalent SMTP wire-up) is installed, invites simply **queue** — nothing is sent,
nothing breaks. Install the extension and point it at `mail` to start sending. SMTP
credentials live in the extension config (a secret manager), never in this code.
