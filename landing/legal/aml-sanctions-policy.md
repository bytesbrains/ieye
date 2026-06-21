# AML & sanctions policy — public crypto receive address

> **DRAFT — FOR COUNSEL REVIEW. NOT LEGAL ADVICE.**
> In-house work product (GC, iEye), built on scoping memo **#38 §5** and the
> external **SG Counsel opinion** (#38 comment, 2026-06-21, §5), which confirmed
> these duties bind **everyone in Singapore regardless of licence** under
> **TSOFA 2002** (targeted financial sanctions) and the **CDSA** (proceeds of
> crime; mandatory STR). Refs: #37, #39.
> This policy does **not** assert we are a licensed financial institution. The
> **MAS/PSA + FSMA Part 9 (DTSP)** applicability opinion remains a **hard gate
> before the address is published [CONFIRM-COUNSEL]**.

## Why we need this even without a licence

Operating a **public inbound crypto address** is an AML risk surface: we cannot
choose who sends to it, and tainted or sanctioned funds can arrive **unsolicited**.
The Singapore statutes below bind us regardless of whether we hold any MAS licence.
A written policy is the difference between *"we had a process"* and *"we had
nothing"* if a bad inflow ever arrives.

- **TSOFA (Terrorism (Suppression of Financing) Act 2002)** + MAS targeted
  financial sanctions: it is an offence to deal with the funds of designated
  persons. Breach exposure up to **SGD 1,000,000 and/or 10 years**.
- **CDSA (Corruption, Drug Trafficking and Other Serious Crimes Act)**: handling
  criminal proceeds is an offence; there is a **mandatory duty to file a
  Suspicious Transaction Report (STR)** on suspicion.

## Controls (apply before the public address spends into the operating treasury)

1. **Screen inflows.** Run sanctions / address screening on incoming
   contributions where feasible (designated-address lists, on-chain risk scoring).
2. **Quarantine, don't spend.** Funds from flagged, sanctioned, or high-risk
   addresses are **quarantined** — not moved into the operating treasury and not
   spent — pending review. Document the decision.
3. **No auto-commingle.** Unscreened inbound is **never** automatically blended
   into the treasury we spend from. Screening is a required step between "received"
   and "spendable."
4. **Source-of-funds sensitivity.** Apply threshold-based light KYC / source-of-
   funds enquiry on **large inflows** and on **contributor-payout recipients**.
5. **Screen outflows too.** Do **not** pay contributors who are in sanctioned
   jurisdictions or on sanctions lists; screen payout addresses.
6. **File STRs.** On suspicion of criminal proceeds, file an STR (CDSA duty). Do
   not "tip off."
7. **Records.** Keep screening results, quarantine decisions, source-of-funds
   notes, and STR copies. Reconcile to the Safe's on-chain history (the chain is
   the ledger). **5-year** retention.

## Roles

- **Safe is BytesBrains-owned** (documented); signer set + threshold decided. **No
  personal wallet ever receives a contribution** (this also protects the FCRA /
  Black Money positions — see [`README.md`](./README.md)).
- A named individual owns the screening/quarantine/STR process and the records.

## Thresholds & tooling — to finalise with counsel

- Exact large-inflow / large-payout KYC thresholds. **[CONFIRM-COUNSEL]**
- Chosen screening tool/provider and the designated-list sources. **[CONFIRM-COUNSEL]**
- STR filing channel and internal escalation path. **[CONFIRM-COUNSEL]**

## Status

Crypto channel is **Phase 2** and **blocked** until (a) the MAS/PSA + FSMA Part 9
opinion is in hand and (b) this policy's controls are operational.
