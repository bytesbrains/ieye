# iEye web backend — Cloud Functions

Trusted backend for the iEye contribution web app. The Admin SDK here runs with
full privileges and **bypasses Firestore security rules**, so everything a client
must not be trusted to do lives in this codebase — and each function enforces its
own authorization. Region: **asia-south1** (next to Firestore).

The **fiat money path (`createContributionCheckout` / `stripeWebhook`) is present
but DARK by default** — gated by the `FIAT_CONTRIB_ENABLED` param (default
`false`) and unset Stripe secrets. Deploying it does **not** turn money on;
flipping it live is a deliberate act that must wait on Legal (#39). See
[Fiat contributions (Stripe) — go-live](#fiat-contributions-stripe--go-live).

## Functions

| Function | Type | What it does |
|---|---|---|
| `grantAdmin` | callable | Mint the `admin` custom claim. **Admin-only** (caller's own token claim is checked). Audited. |
| `revokeAdmin` | callable | Remove the `admin` claim. Admin-only. Audited. **Refuses to remove the last admin** (no lockout). |
| `onUserWritten` | Firestore trigger | Records a consent change to the append-only `consentLog`, then rebuilds the user's `publicSupporters` entry from their consent (opt-in **name only** — the wall never carries an amount, #36). Opting out or deleting the account removes the entry — **withdrawal is honored**. |
| `onContributorRequestInvited` | Firestore trigger | On a request advancing to `invited`, stamps `invitedAt` and enqueues an invitation email. |
| `createContributionCheckout` | callable | **Gated/money.** Signed-in user picks an amount; creates a Stripe Checkout Session server-side (amount validated, secret never on the client) and returns its URL. Refuses unless `FIAT_CONTRIB_ENABLED=true`. |
| `stripeWebhook` | HTTP | **Gated/money.** Verifies the Stripe signature, then writes ONE idempotent `contributions` ledger doc per event (keyed by event id — redeliveries can't double-count). |

### Authorization model
- `admin` is a **custom claim**, never a Firestore field. Only these functions
  mint it; a client can never write its own. Bootstrapping the *first* admin is a
  one-time out-of-band Admin SDK act; after that admins manage each other here.
- The `publicSupporters` projection contains **only consented fields** and is the
  only thing the public wall reads (no private doc is ever exposed by rules). It is
  keyed by a **random id, never the uid**, and carries no uid field, so listing the
  world-readable wall reveals nothing about *who* its supporters are. It is
  **name-only — no amount field exists** ("named ≠ priced", #36), so the wall is
  structurally incapable of publishing a per-person figure. The private
  `supporterIndex` (uid → public id) lets the backend still find and
  rebuild/remove a user's entry.
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

## One-time maintenance — purge legacy amount fields (#36)

Docs written *before* the name-only switch may still carry inert `optInDisplayAmount`
(on `users`) or `displayAmount` (on `publicSupporters`) copies. Nothing reads them and
rules now refuse to add or change `optInDisplayAmount`, so they're harmless — but
`scripts/purge-legacy-amount.mjs` sweeps them so the "an amount can never be published"
guarantee holds for pre-existing docs too. Idempotent and dry-run by default:

```bash
# from landing/functions, with Admin credentials for the live project
GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GOOGLE_CLOUD_PROJECT=ieye-in \
  node scripts/purge-legacy-amount.mjs           # dry run — reports counts
GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GOOGLE_CLOUD_PROJECT=ieye-in \
  node scripts/purge-legacy-amount.mjs --apply   # delete the dead fields
```

## Enable email sending (optional, when ready)

The invitation function writes a doc to the **`mail`** collection in the shape the
[Trigger Email from Firestore](https://extensions.dev/extensions/firebase/firestore-send-email)
extension consumes (`{ to, message: { subject, html } }`). Until that extension (or
an equivalent SMTP wire-up) is installed, invites simply **queue** — nothing is sent,
nothing breaks. Install the extension and point it at `mail` to start sending. SMTP
credentials live in the extension config (a secret manager), never in this code.

### Sender identity & deliverability (do this when enabling sending)

The `mail` documents carry only `to` + `message`; the **From / Reply-To is set in
the extension config**, not in code. Use:

- **From:** `noreply@ieye.in` (transactional sender — waitlist "it's open"
  notifications and contributor invitations).
- **Reply-To:** `support@ieye.in` (a monitored human mailbox — never bounce a
  reply into a black hole).

**Authenticate the domain or it lands in spam.** Before the first real send, add
these DNS records for `ieye.in` (values from your email provider / Google
Workspace / the extension's SMTP provider):

- **SPF** — TXT record authorizing the sending provider.
- **DKIM** — the provider's signing key (CNAME/TXT).
- **DMARC** — a `_dmarc.ieye.in` policy (start `p=none` with `rua=mailto:dmarc@ieye.in`
  to monitor, then tighten to `quarantine`/`reject`).

> The welfare app's escalation emails (Easy mode, #20 — gated) are a **separate,
> higher-stakes sender** and must not reuse the `noreply@` transactional identity:
> a missed escalation is the failure mode that matters, so it needs its own
> monitored, maximally-deliverable path.

## Fiat contributions (Stripe) — go-live

The fiat path ships **off**. Turning it on is deliberate and **must not happen
until the #39 legal gate clears** (CA written view on income/GST, the written
FCRA-exclusion, the "contribution not donation" wording — already live — and the
consent/privacy mechanics). Order of operations:

**1. Clear Legal (#39).** Do not proceed otherwise. Foreign contributions must
land only in **BytesBrains Pte Ltd (SG)** rails — never an Indian account or any
individual personally (FCRA bright line).

**2. Create the Stripe account** under BytesBrains Pte Ltd (Singapore). Get the
**secret key** and, after step 3, the **webhook signing secret**.

**3. Deploy + register the webhook.** Deploy functions, then in the Stripe
Dashboard add a webhook endpoint pointing at the deployed `stripeWebhook` URL
and subscribe to **`checkout.session.completed`**. Copy its signing secret.

**4. Set the secrets and params** (never commit these — Secret Manager only):

```bash
# from landing/
firebase functions:secrets:set STRIPE_SECRET_KEY      --project ieye-in
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET  --project ieye-in
# Params (non-secret) — set via env/.env for functions, or the deploy config:
#   FIAT_CONTRIB_ENABLED=true     # the master gate — last switch you flip
#   SITE_ORIGIN=https://ieye.in   # Checkout success/cancel redirects
firebase deploy --only functions --project ieye-in
```

**5. Turn on the UI.** Build the landing with `VITE_FIAT_CONTRIB_ENABLED=true`.
This is UI-only; the backend gate above is the real boundary.

**Notes**
- **Idempotency:** the ledger doc id is `stripe_<eventId>`; a redelivered webhook
  no-ops instead of double-counting.
- **Currency:** SGD. Amount bounds are enforced server-side (S$1–S$10,000).
- **Publicity** is set from the contributor's consent (`onUserWritten`,
  name-only), **never** from the webhook write.
- **TODO before treating inflows as spendable — AML/sanctions screening** of the
  public inflow (#38 §5 / #54): screen → quarantine flagged funds → don't
  commingle into the operating treasury unscreened. Tracked separately.
- **Crypto** (USDC-on-Base, #37) is a *separate* channel with its own hard gate
  (MAS/PSA opinion) and is **not** part of this path.
