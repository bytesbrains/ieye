# On-chain contribution consent — canonical wording & rules

> **DRAFT — FOR COUNSEL REVIEW. NOT LEGAL ADVICE.**
> In-house work product (GC, iEye), built on scoping memo **#38 §4–§5** and the
> external **SG Counsel opinion** (#38 comment, 2026-06-21), which **hardened**
> this from "say it's public" to the rules below, citing **EDPB Guidelines
> 02/2025 (blockchain)**. Refs: #37, #39.
> **Hard gate before any crypto address is shown publicly:** the
> **MAS/PSA + FSMA Part 9 (DTSP)** applicability opinion **[CONFIRM-COUNSEL]** —
> see [`README.md`](./README.md).

The fiat path and the on-chain path have **opposite** privacy properties. The
fiat wall is private-by-default and withdrawable. An on-chain inflow is
**permanently public and cannot be un-published by anyone** — consent cannot
manufacture a delete capability the chain lacks. The wording and rules below
exist so we never promise privacy we can't deliver.

---

## Four structural rules (non-negotiable)

1. **Two separate consents, never bundled.** The off-chain supporter-wall opt-in
   (withdrawable) and the on-chain "I understand this is permanent" consent are
   **distinct**. A contributor on the crypto path must give the on-chain consent
   on its own; it is never folded into the wall opt-in or a general ToS tick.
2. **Never put a name (or any added personal data) on-chain.** We only ever touch
   what the chain *already* exposes — the contributor's wallet address and amount.
   We never write a name, email, or message to the chain. (EDPB 02/2025: putting
   personal data directly on a public chain may be GDPR-incompatible **even with
   consent**.)
3. **Do not present on-chain contributing as "private."** It isn't and can't be.
   The crypto path is explicitly the **public** path; the fiat path is the private
   option.
4. **Treat the crypto path as high-risk data processing.** A short **DPIA** is
   required before launch (GDPR Art. 35), and a wallet address tied to a person is
   **personal data** (pseudonymous ≠ anonymous).

---

## The consent wording (use verbatim, at the crypto send point)

> **On-chain contributions are public and permanent.** If you send USDC to this
> address, the transaction — including your wallet address and amount — is recorded
> on the Base blockchain **forever**, publicly, and **cannot be deleted, hidden, or
> made private by us or anyone.** This is the opposite of the fiat path. **If you
> want your contribution to stay private, use the card/bank option instead.** By
> sending on-chain, you accept that your contribution is permanently public.

This text must appear **at the point the address/QR is shown**, with an explicit
affirmative action (e.g. "I understand — show the address") before the address is
revealed or copyable.

---

## Supporting points

- **Fresh/rotating receive address (#37):** reduces address-clustering for
  contributors and is worth doing — but it does **not** make any single inflow
  private. Keep **outflow** on a stable, publicly-known Safe for accountability.
- **The wall is never chain-scraped.** Wall membership is always explicit,
  account-based opt-in (name-only — see [`privacy-notice.md`](./privacy-notice.md)),
  **never** derived from on-chain donor addresses — even though the chain exposes
  them. This is the privacy project keeping faith.

---

## Implementation notes (for Frontend)

- Gate the address/QR behind the affirmative on-chain consent. No address visible
  before consent.
- Log the on-chain consent (what, when, notice version) the same way the wall
  opt-in is logged.
- The crypto path is **Phase 2** and **blocked** until the MAS/PSA + FSMA Part 9
  opinion is in hand (#39).
