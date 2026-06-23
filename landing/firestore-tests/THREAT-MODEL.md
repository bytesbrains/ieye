# iEye Phase-1.5 web app — Firestore threat model & data model

**Author:** iEye Security
**Scope:** Firestore data model + security rules + admin RBAC for the auth'd web app (#43).
**Refs:** web-app architecture #43 · contribution model + opt-in-named #36 · data-controller / legal posture #38.

> The admin surface + personal + financial data + RBAC make the **Firestore rules + admin-role model the whole ballgame** (#43). These rules are written to protect data **even if the frontend is fully compromised** — the UI is not a security boundary; this file is.

---

## 1. Surfaces and who can do what

Three surfaces, mapped to three identity states:

| Surface | Identity | What it can touch |
|---|---|---|
| **Public** | no auth | read `publicSupporters` only |
| **User** | Google sign-in (Firebase Auth) | read/write own `users` doc; read own `contributions`; create + read own `contributorRequests`; read `publicSupporters` |
| **Admin** | Firebase Auth **custom claim** `admin == true` | read/manage `users`, read all `contributions`, write `publicSupporters`, read + advance `contributorRequests` |
| **Backend** | Admin SDK / Cloud Functions | bypasses rules entirely — the only writer of `contributions`, the builder of `publicSupporters`, the minter of admin claims |

**Two identities stay distinct (#43):** this web *contribution* account (Google/Firebase) is **separate** from the mobile *safety-app* identity (self-custody / passkey, Sovereign mode #3). These rules govern only the web account. Never conflate.

---

## 2. Data model

All documents live in a single Firestore database. Field names below are the contract the Frontend and Functions must honor.

### `users/{uid}` — one doc per authenticated user
- Doc id **is** the Firebase Auth `uid` (immutable owner — there is no mutable owner field to tamper with).
- `displayName`, `email`, `photoURL` — profile (mirrors Google profile; user-editable).
- `optInDisplayName: bool` — opt-IN to show name on the public wall. **Default false.** (#36, #38 §4)
- **No amount opt-in.** The wall is **name-only** — opt-in to be named is **not** opt-in to be priced (#36, wall Version B). There is deliberately no `optInDisplayAmount`: a per-person amount can never be published, enforced structurally rather than by policy.
- `consentVersion: string`, `consentAt: timestamp` — which privacy-notice version the user consented to, and when (evidence of lawful basis; #38 §4.5).
- **NO `role` / `admin` / `claims` field.** Authorization is a custom claim, never data. Rules actively reject any client write that introduces such a field (defense in depth).

### `contributions/{id}` — the ledger source of truth
- `ownerUid: string` — who contributed (links to `users/{uid}`).
- `kind: 'money' | 'inkind' | 'labor'` — the three separately-tracked buckets (#36). In-kind / labor are tracked separately from cash.
- `amountWei: string` / `asset: string` — money amounts in wei-native / asset units (no fiat literals in protocol-layer copy; valuation handled backend per #38 §5). In-kind valuation + labor recognition are non-financial lines.
- `method: 'card' | 'bank' | 'crypto' | 'inkind' | 'labor'` — rail used.
- `isPublic: bool` — whether the contributor consented to surface this on the wall. **Set by backend from consent state, never by the client.**
- `timestamp`, `status`, `reconciledAt` — ledger bookkeeping.
- **Clients NEVER write this collection.** Writes come only from trusted backend (payment webhook handler, admin reconciliation, on-chain indexer).

### `publicSupporters/{id}` — world-readable PROJECTION
- A backend-built projection containing **ONLY the consented display name** — `displayName` (only if `optInDisplayName`), `publishedAt`, `featured`. **No amount field exists**, so the wall is structurally incapable of publishing a per-person figure (#36, "named ≠ priced").
- Exists so rules **never have to crack open a private `users`/`contributions` doc** to render the public wall. The public wall reads this collection and nothing else.
- World-readable by design (holds nothing private). Writable only by backend/admin.
- **Legacy fields.** Docs written before the name-only switch (#36) may still carry an inert `displayAmount` (and `users` an inert `optInDisplayAmount`). Nothing reads them, rules refuse to add/change `optInDisplayAmount` going forward, and the projection is rebuilt with `set` (no merge) so it's dropped on the next rebuild. The one-time `functions/scripts/purge-legacy-amount.mjs` sweeps any that are never rebuilt.

### `contributorRequests/{id}` — request → vetted → invited (#36)
- `ownerUid: string` — the requester (must equal `request.auth.uid` on create).
- `status: 'requested' | 'vetted' | 'invited'` — must start at `'requested'`; only admins advance it.
- `skills`, `links`, `note`, `createdAt`, `vettedBy`, `vettedAt` — vetting metadata.

---

## 3. RBAC — least privilege, default deny

- **Default deny:** the trailing `match /{document=**} { allow read, write: if false; }` denies everything not explicitly whitelisted. Every collection is opt-in.
- **Owner isolation:** a user can only read/write their own `users` doc, read their own `contributions`, and create/read their own `contributorRequests`. Cross-user reads fail.
- **Money is backend-only:** no client (user *or* admin) can write `contributions`. Only the Admin SDK / Functions write the ledger, so a compromised client cannot fabricate, inflate, alter, or self-publish a contribution.
- **Admin via custom claim only:** `isAdmin()` reads `request.auth.token.admin`. There is no Firestore field a client could set to become admin, and rules reject any attempt to persist `admin`/`role`/`claims`-style fields.

---

## 4. How admin claims are granted (the privileged path)

The `admin` custom claim is minted **only** by a secured, privileged Cloud Function (or an operator running the Admin SDK), e.g. `admin.auth().setCustomUserClaims(uid, { admin: true })`. Requirements:

1. The grant function must itself be admin-gated (caller already has `admin == true`) and bootstrapped once by an operator out-of-band (first admin set via a one-off Admin SDK script, not exposed to clients).
2. Claim changes take effect on the user's next token refresh — Functions/rules see them after re-auth.
3. Granting/revoking admin must be **audit-logged** (who granted what, when) outside Firestore rules' reach.
4. Never expose claim-minting through any client-callable, unauthenticated path.

---

## 5. What rules CANNOT enforce — backend / Functions MUST

Firestore rules are necessary but not sufficient. The trusted backend is the only writer of money and the only builder of the public projection, so it carries these responsibilities:

1. **Ledger integrity** — `amountWei`/`asset`/`method` correctness, idempotent payment-webhook handling, reconciliation. Rules only guarantee *clients can't write* contributions; they can't validate that what the backend writes is *correct*.
2. **AML / sanctions screening** on crypto inflows before commingling (#38 §5). Rules cannot screen on-chain provenance.
3. **Consent-log integrity** — record `consentVersion` + `consentAt`, and build `publicSupporters` **strictly** from `optInDisplayName` (#38 §4). Rules let the user *flip* the flag; only the backend decides what actually gets published, and must honor withdrawal (remove from the wall going forward).
4. **The on-chain-is-permanent caveat** (#38 §4/§5) — on-chain contributions can't be un-published; the consent UI/flow (not rules) must warn before send.
5. **Minting/revoking admin claims** (see §4) — entirely outside rules.
6. **Honesty guardrail** — copy says "contribution," never "donation"; never implies tax-deductibility (#38 §2). Enforced in product copy review, not rules.
7. **Cascade cleanup on erasure** — when a user deletes their `users` doc, the backend must purge/anonymize related `contributions` and `publicSupporters` per the retention policy.

---

## 6. Residual risks accepted at this phase

- **Document-existence oracle:** failed-vs-succeeded reads can leak whether a doc id exists. We use non-guessable ids and never key on secret values, so this is low-impact.
- **Admin client trust:** an admin's browser session is powerful (read all profiles/contributions, write the wall). Mitigate operationally: minimal admin set, 2FA on admin Google accounts, session/audit logging in Functions.
- **No field-level redaction in rules:** rules grant/deny whole-document reads. The `publicSupporters` projection pattern is exactly how we avoid ever needing field-level read control on private docs.

---

## 7. Constraints the Frontend build MUST honor

1. **Never write `contributions` from the client.** All money/in-kind/labor records come from the backend. The UI shows what the backend wrote; it never creates ledger entries.
2. **Never expect a `role`/`admin` field on `users`.** Detect admin via the Firebase Auth ID-token custom claim (`getIdTokenResult()` → `claims.admin`), not a Firestore read. Treat the claim as the only source of admin truth.
3. **Read the public wall from `publicSupporters` only** — never try to read other users' `users`/`contributions` docs to build it (rules will deny it anyway).
4. **`contributorRequests` must be created with `ownerUid == auth.uid` and `status: 'requested'`.** The UI cannot set any later status; only admins advance it.
5. **Opt-in-named toggle lives on the user's own `users` doc** (`optInDisplayName`), default off. Flipping the flag is a *request to publish*; actual publication is backend-mediated. (Name-only — there is no amount toggle; #36.)
6. **Profiles are private.** A user can only read their own `users` doc; build profile UI for the signed-in user only.
7. **Admin claim minting is backend-only.** No client UI path may attempt to set custom claims.
