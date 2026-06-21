# iEye contribution platform — Privacy Notice

> **DRAFT — FOR COUNSEL REVIEW. NOT LEGAL ADVICE.**
> In-house work product (GC, iEye), built on scoping memo **#38 §4** and the
> external **SG Counsel opinion** (#38 comment, 2026-06-21, §4). This is the
> privacy notice for the **contribution platform / website only** — not the iEye
> mobile product (separate notice, PRD #2). Liveness/sensor data never reaches a
> server by design (CLAUDE.md), so it is out of scope here.
>
> **Residual human sign-offs before this goes live:**
> - **EU + UK GDPR Art. 27 representatives** — appoint, **or** record a documented
>   decision **not** to target/accept EU/UK contributors. Counsel upgraded this
>   from "maybe later" to **likely mandatory** (recurring global contributions are
>   "regular, not occasional"). **[CONFIRM-COUNSEL]**
> - Whether contribution volume triggers a **DPO** obligation. **[CONFIRM-COUNSEL]**
> - The **notice version string below must equal the app's `CONSENT_VERSION`**
>   (currently `2026-06-phase1.5`, in `landing/src/lib/useUserDoc.ts`) so logged consent
>   maps to the right notice. Bump both together when this notice materially
>   changes.

---

**Effective date:** _[set at launch]_  ·  **Notice version:** `2026-06-phase1.5`

## 1. Who we are (the data controller)

iEye is operated by **BytesBrains Pte Ltd**, a private limited company registered
in Singapore ("BytesBrains," "we," "us"). For the personal data described in this
notice, **BytesBrains Pte Ltd is the data controller**.

Contact: _[privacy@ieye.in — **LAUNCH-BLOCKING: confirm this mailbox is live and
monitored before publish.** A privacy notice that lists a dead contact for rights
requests is itself a compliance defect.]_.
EU representative (GDPR Art. 27): _[PENDING — appoint or document non-targeting]_.
UK representative (UK GDPR Art. 27): _[PENDING — appoint or document non-targeting]_.

## 2. What we collect, and why

| Data | When | Purpose | Lawful basis |
|---|---|---|---|
| Name, email, profile photo (from Google sign-in) | You sign in to join the waitlist or to contribute/build | Tell you when iEye opens; manage your account; attribute your contribution to you privately | Consent; performance of your request |
| Waitlist opt-in flag + timestamp | You ask to be notified | Notify you at launch | Consent |
| Display-name opt-in + consent version/time | You choose to be named on the public wall | Publish your **name only** on the supporter wall | **Explicit consent** |
| Contribution records (amount, method, date) | You contribute (Phase 2) | Ledger, accounting, tax, AML | Legal obligation; legitimate interests (accountability) |

We collect **only what we need**. We do **not** sell personal data.

## 3. The public supporter wall — name only, opt-in

- **Private by default.** Nothing about you is published unless you affirmatively
  opt in. The opt-in is **unticked by default** (a pre-ticked box is not valid
  consent — *Planet49*, EDPB 05/2020).
- **Name only.** The wall publishes **your display name and nothing else** — **no
  amount, ever** ("named ≠ priced," #36). The projection is structurally incapable
  of carrying a per-person figure.
- **Withdrawable anytime** from your account. Withdrawal removes your name from the
  wall going forward.
- We **log your consent** (what, when, which notice version) to evidence lawful
  basis, and never publish you from any other source — in particular we **never
  scrape on-chain addresses** into names.

## 4. On-chain (crypto) contributions are different — public and permanent

If you contribute on-chain (USDC on Base, Phase 2), the transaction — your
**wallet address and amount** — is recorded on a public blockchain **permanently**
and **cannot be deleted or made private by us or anyone**. This is the opposite of
the fiat path and of the wall opt-in. We will tell you this **before** you send and
ask for a **separate** consent; we **never** write your name to the chain. If you
want privacy, use the card/bank option. See
[`on-chain-consent.md`](./on-chain-consent.md).

## 5. Who we share data with

Service providers acting on our instructions: authentication and hosting
(Google/Firebase), and — in Phase 2 — payment processing (card/bank rails) and
email delivery. We disclose data if required by law (e.g. a valid order, or a
suspicious-transaction report under Singapore AML law — see
[`aml-sanctions-policy.md`](./aml-sanctions-policy.md)). We do not sell data.

## 6. International transfers

We are in Singapore and serve contributors globally; data may be processed outside
your country. Where required, transfers rely on appropriate safeguards (e.g. SCCs)
and your consent for the specific publication described above. **[CONFIRM-COUNSEL]**

## 7. Retention

Account/consent records are kept while your account is active and as long as needed
for the purposes above. Accounting and contribution records are retained for **5
years** to meet Singapore statutory requirements (IRAS/ACRA). Withdrawing wall
consent removes your name from the wall but does not erase records we must keep by
law.

## 8. Your rights

Depending on where you are, you have rights under **Singapore PDPA**, the
**EU/UK GDPR**, and **India's DPDP Act 2023**, including: access; correction;
withdrawal of consent; erasure (GDPR Art. 17); objection/restriction; and to
lodge a complaint with your supervisory authority (e.g. the PDPC in Singapore).
To exercise any right, contact us at the address in §1. Note the on-chain caveat
in §4: we cannot erase what the blockchain records.

## 9. Changes

If we change this notice we will update the version string and effective date, and
re-seek consent where the change is material. Consent is always logged against the
version in force when you gave it.
