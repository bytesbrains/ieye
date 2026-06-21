# iEye legal gate — artifacts & tracker

> **DRAFT — FOR COUNSEL REVIEW. NOT LEGAL ADVICE.**
> In-house work product of the GC (iEye). It exists to make the legal gate in
> **#39** concrete: it turns the scoping memo **#38** + the external **SG Counsel
> opinion** (#38 comment, 2026-06-21) into the documents the gate requires, and
> tracks what is **answered (build to it)** vs. what still needs a **wet
> signature** from a licensed practitioner.
>
> **The gate, in one sentence:** *do not accept the first contribution (fiat or
> crypto) until the four 🚧 human sign-offs below are in hand.*

## ⚠️ Personal exposure — for the CEO, read first

Foreign money must **never** touch an Indian account or the CEO personally.
Contributions belong to **BytesBrains Pte Ltd (SG)**; the CEO only ever takes
**arm's-length, board-approved salary/fees** (expressly *not* "foreign
contribution" under FCRA). The sharper risk is **disclosure, not FCRA**: as an
India resident the CEO must declare **SG shares, any SG account, and the Safe
multisig signer role** in **Schedule FA** of the ITR — omission triggers the
**Black Money Act** (₹10 lakh penalty + 6 mo–7 yr). Action this with an Indian CA.

---

## The artifacts (build to these — counsel said ship them)

| Doc | What it is | Status |
|---|---|---|
| [`contribution-disclaimer.md`](./contribution-disclaimer.md) | "Contribution, not donation" canonical wording + word rules | ✅ drafted; ship verbatim |
| [`on-chain-consent.md`](./on-chain-consent.md) | On-chain-public consent wording + 4 structural rules | ✅ drafted; gated on MAS opinion |
| [`privacy-notice.md`](./privacy-notice.md) | Privacy notice — BytesBrains as controller (PDPA/GDPR/DPDP) | ✅ drafted; EU/UK rep pending |
| [`aml-sanctions-policy.md`](./aml-sanctions-policy.md) | AML/sanctions controls for the public crypto address | ✅ drafted; gated on MAS opinion |
| [`contribution-constraints.md`](./contribution-constraints.md) | Benefit-free-contribution rule (protects tax + GST) | ✅ drafted; product constraint |
| [`terms-of-service.md`](./terms-of-service.md) | Terms of Use companion to the published `/terms` page | ✅ drafted; binding clauses Legal-gated |

> **Published pages (live to users):** the Privacy Notice renders at **`/privacy`**
> (`src/pages/Privacy.tsx`) and the Terms at **`/terms`** (`src/pages/Terms.tsx`),
> linked from the footer and at every consent point (waitlist, sign-in, account).
> The `/privacy` version is pinned to `CONSENT_VERSION`, so recorded consent always
> maps to a readable notice (closes the consent-integrity gap). The `.md` files
> here are the counsel-review companions; keep them in sync with the pages.

> **Self-audit the open external sign-offs** at any time:
> `grep -rn '\[CONFIRM-' landing/legal/` — every hit is a spot a licensed
> practitioner must still sign off in writing.

---

## Gate tracker

### ✅ Answered by the SG Counsel opinion — build to these
- [x] Contributions = **taxable-risk corporate income** (17% less SUTE/PTE);
      **GST 9%**, out-of-scope while contributions stay **benefit-free** and under
      **SGD 1M** → keep contributions perk-free; reserve for tax.
      → [`contribution-constraints.md`](./contribution-constraints.md)
- [x] **FCRA exclusion confirmed** (SG receipt outside scope); no Indian/personal
      account ever receives a contribution.
- [x] **"Contribution, not donation"** disclaimer — ship verbatim.
      → [`contribution-disclaimer.md`](./contribution-disclaimer.md)
- [x] **On-chain-is-public consent** — at send point; two separate consents; never
      a name on-chain. → [`on-chain-consent.md`](./on-chain-consent.md)
- [x] **Opt-in consent + privacy notice** naming BytesBrains as controller.
      → [`privacy-notice.md`](./privacy-notice.md)
      *(Partly built: account opt-in is name-only, private by default, consent
      logged — #36/#48. Live-money consent UI is Phase 2.)*
- [x] **Safe = BytesBrains-owned** (documented), no personal wallet.
- [x] **AML/sanctions policy** — screen inflows, quarantine flagged funds, STR on
      suspicion (binding under TSOFA/CDSA regardless of licence).
      → [`aml-sanctions-policy.md`](./aml-sanctions-policy.md)

### 🚧 Still require a HUMAN licensed sign-off — the real engagement list (#39)
- [ ] **SG corporate/tax CA** — written gift-vs-income + GST view + SUTE/PTE
      eligibility (consider an **IRAS advance ruling**).
- [ ] **MAS / PSA *plus* FSMA Part 9 (DTSP) applicability opinion** — *hard gate
      before the crypto address goes public.* (Own-account = no licence is
      well-founded but enforcement-sensitive + cross-border; get it on letterhead.)
- [ ] **Indian CA** — FCRA-exclusion letter **+ FEMA ODI/LRS setup + Schedule FA /
      Black Money Act disclosure** of SG shares **and Safe-signer role**.
- [ ] **EU + UK GDPR Art. 27 representatives** — appoint, **or** document a
      decision **not** to target/accept EU/UK contributors.

### Four new items the in-house memo (#38) did not name — now tracked
1. **Black Money Act / Schedule FA** disclosure incl. Safe-signer authority.
2. **FEMA ODI/LRS round-tripping** check (same resident owns the entity *and*
   draws salary from it).
3. **GDPR EU + UK reps** likely mandatory (not "assess later").
4. **FSMA Part 9 DTSP** (cross-border token services) — clear alongside MAS/PSA.

### 🔴 Launch-blocking operational items (not a sign-off, but must be real before publish)
- [x] **Live, monitored privacy contact** — `privacy@ieye.in` provisioned on the
      ieye.in domain and set as the notice contact. *Keep it monitored* (a dead
      rights-request contact is itself a compliance defect).
      → [`privacy-notice.md`](./privacy-notice.md) §1
- [x] **Footer wording reconciled** — footer + money CTA now render the canonical
      short form from `landing/src/lib/legalCopy.ts` (the single source of truth).
      → [`contribution-disclaimer.md`](./contribution-disclaimer.md)

### Can follow (not blocking the first contribution)
- [ ] Contributor **services-agreement template** + residence/tax self-declaration
      (before first **payout**, not first contribution). No CPF for foreign devs;
      generally no SG WHT on remote-abroad work; pay India-residents in **fiat, not
      USDC** (USDC drags in India's 30% VDA + 1% TDS).
- [ ] **Charity-vehicle review trigger** — default **SG charity + IPC** when it
      fires (a **new entity + asset transfer**, not a conversion).

---

## How to use this

1. **CEO:** take this file + the memo (#38) + the SG Counsel opinion to the three
   practitioners (SG CA, SG MAS/PSA counsel, Indian CA) and obtain the four 🚧
   sign-offs. Resolve the EU/UK rep decision.
2. **Counsel/CA:** review the drafted artifacts; the `[CONFIRM-*]` tags inside each
   mark exactly where your written sign-off is required.
3. **Frontend:** the canonical strings are wired as a single source of truth in
   **`landing/src/lib/legalCopy.ts`** (`LEGAL.*`), consumed today by the footer +
   money CTA (short form). Phase-2 payment UI must consume `contributionDisclaimerFull`
   at the point of payment and `onChainConsent` at the crypto send point — both
   already exported there. Never paraphrase in a component; render `LEGAL.*`.

*Nothing in this folder is final legal advice. It is in-house work product to
brief — and be signed off by — licensed Singapore corporate/tax counsel, a
Singapore CA, and an Indian CA.*
