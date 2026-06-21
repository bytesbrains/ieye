# Terms of Use — iEye contribution website + account

> **DRAFT — FOR COUNSEL REVIEW. NOT LEGAL ADVICE.**
> In-house work product (GC, iEye). The **published** version is the `/terms` page
> (`landing/src/pages/Terms.tsx`); this is the counsel-review companion. The terms
> themselves are **Legal-gated (#38/#39)** — the binding clauses below must be
> reviewed before the site relies on them. Refs: #1, #36, #37, #38.

The published page is intentionally plain and conservative, scoped to what the
site does today (waitlist + account; contributions not yet open). Keep the page,
this file, and the canonical wording in `landing/src/lib/legalCopy.ts` in sync.

## Items that need a wet signature / counsel review
- **Governing law & jurisdiction** — page states **Singapore**. Confirm forum /
  dispute-resolution wording. **[CONFIRM-COUNSEL]**
- **Limitation of liability** — page uses a conservative "to the maximum extent
  permitted by law" clause that explicitly does **not** touch the §4 honest
  promise about the service. Confirm enforceability and scope across SG / EU / IN
  consumer law. **[CONFIRM-COUNSEL]**
- **Consumer-protection / charitable-solicitation wording** — if we market into the
  US, the word rules and any state solicitation language need review (mirrors
  [`contribution-disclaimer.md`](./contribution-disclaimer.md)). **[CONFIRM-COUNSEL]**
- **Contributor agreement** — §6 references a separate contributor/services
  agreement + MIT-on-1.0; that template is the *can-follow* item in the gate
  tracker, due before the first **payout**.

## Section map (page ↔ project)
1. Who we are; scope (site + account only; mobile app separate) — #43, THREAT-MODEL §1
2. Public good, **no token / not an investment** — #1, #37 (anti-grift)
3. **Contributions, not donations** — renders `LEGAL.contributionDisclaimerShort`
   (canonical), see [`contribution-disclaimer.md`](./contribution-disclaimer.md)
4. **No emergency service; no guarantee** — mechanism-not-outcome (#28, CLAUDE.md)
5. Account & acceptable use
6. Building with us (contributors) — request→vet→invite, MIT at 1.0 (#1)
7. IP & open source — MIT protocol/SDK; brand belongs to BytesBrains
8. Privacy — points to `/privacy` ([`privacy-notice.md`](./privacy-notice.md))
9. Liability — see [CONFIRM-COUNSEL] above
10. Changes
11. Governing law (Singapore) + contact `legal@ieye.in` — see [CONFIRM-COUNSEL]
