# Contribution disclaimer — canonical wording

> **DRAFT — FOR COUNSEL REVIEW. NOT LEGAL ADVICE.**
> In-house work product (GC, iEye), built on the scoping memo **#38 §2** and the
> external **SG Counsel opinion** (#38 comment, 2026-06-21), which confirmed this
> wording "is correct and should ship verbatim." Residual human sign-off:
> US-state charitable-solicitation wording **[CONFIRM-COUNSEL]** *only if* we
> actively market into the US. Refs: #36, #37, #39.

This file is the **single source of truth** for how iEye describes inbound
contributions. Every CTA, confirmation screen, footer, ToS, and marketing line
must conform. If a screen needs this wording, it links here — it does not
paraphrase.

---

## Why this exists

BytesBrains Pte Ltd is a **for-profit Singapore private limited company** with
**no charity status and no Institution of a Public Character (IPC) status**. It
therefore **cannot** issue tax-deductible receipts, and a contributor gets **no
deduction in any jurisdiction**. Calling a contribution a "donation" — or
implying charity status or deductibility — would be a **misrepresentation** (and,
in some jurisdictions, a consumer-protection / charities-law offence). This also
flows directly from the iEye honesty guardrail (Maktub D-031): say only what is
true.

---

## The word rules (absolute)

**MAY say:**
- "Contribution to support the iEye project."
- "iEye is run by BytesBrains Pte Ltd, a Singapore company, as a public good."
- "Your contribution funds infrastructure, development, and contributor work."
- "Contribute," "support the project."

**MUST NOT say or imply:**
- "Donation," "donate," "tax-deductible," "charitable," "charity,"
  "nonprofit," "not-for-profit," "501(c)(3)," "80G," "Gift Aid,"
  "your gift is deductible."
- Any "donation receipt" or document that looks like a deductibility receipt.
- **No "Donate" button anywhere, ever.** The primary CTA verb is **"Contribute."**

---

## The disclaimer (use verbatim)

Display at **every contribution point** and in the **footer / ToS**:

> **About your contribution.** iEye is operated by **BytesBrains Pte Ltd**, a
> private limited company registered in Singapore. iEye is run as a public good,
> but BytesBrains is **not a registered charity** and does **not** have tax-exempt
> or Institution-of-a-Public-Character status. Your contribution is a **voluntary
> payment to support the project — not a tax-deductible charitable donation.** You
> will **not** receive a tax-deductible receipt, and your contribution is **not**
> deductible against income tax in Singapore, India, or elsewhere. We use the word
> *contribution* deliberately and never *donation*, because we will only tell you
> what is true.

A short form is acceptable directly under a money CTA, provided the full text is
one tap away (footer/ToS):

> *iEye is received by BytesBrains Pte Ltd (Singapore), a company, not a charity —
> contributions support the project and are **not** tax-deductible. We say so
> because honesty is the whole point.*

---

## Implementation notes (for Frontend)

- **Single source of truth:** the canonical strings live in
  **`landing/src/lib/legalCopy.ts`** (`LEGAL.contributionDisclaimerShort` /
  `LEGAL.contributionDisclaimerFull`). The "coming soon" money block
  (`Contribute.tsx`) and the **footer** (`Footer.tsx`) both render
  `contributionDisclaimerShort` from there — **footer drift reconciled** (PR #50
  follow-up). Change wording **here and in `legalCopy.ts` together**; CODEOWNERS
  routes both past Legal.
- When live money ships, the **full disclaimer** (`contributionDisclaimerFull`)
  must render at the point of payment (fiat and crypto) before the contributor
  confirms.
- Route every new CTA past Legal review so "donate" never slips into a button.
