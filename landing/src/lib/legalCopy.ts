// Canonical legal copy — SINGLE SOURCE OF TRUTH for contribution wording.
//
// These strings are the counsel-approved wording. The contribution UI and the
// footer MUST render these and never paraphrase, so live copy can't drift from
// the approved text — exactly the drift flagged in PR #50. If wording changes,
// change it HERE and route the change past Legal (CODEOWNERS).
//
// Note: emphasis/bolding is intentionally NOT encoded here — the legally load-
// bearing thing is the exact WORDS, not the styling. Render as plain text so a
// careless markup tweak can never alter the wording.

export const LEGAL = {
  /**
   * Full "contribution, not donation" disclaimer. Must render at every
   * contribution point (fiat + crypto) before the contributor confirms, and in
   * the footer/ToS. (Phase 2 has no payment surface yet — this is ready for it.)
   */
  contributionDisclaimerFull:
    "iEye is operated by BytesBrains Pte Ltd, a private limited company registered " +
    "in Singapore. iEye is run as a public good, but BytesBrains is not a registered " +
    "charity and does not have tax-exempt or Institution-of-a-Public-Character status. " +
    "Your contribution is a voluntary payment to support the project — not a tax-deductible " +
    "charitable donation. You will not receive a tax-deductible receipt, and your " +
    "contribution is not deductible against income tax in Singapore, India, or elsewhere. " +
    "We use the word contribution deliberately and never donation, because we will only " +
    "tell you what is true.",

  /**
   * Short form. Acceptable directly under a money CTA / in the footer, provided
   * the full text is one tap away (footer/ToS).
   */
  contributionDisclaimerShort:
    "iEye is received by BytesBrains Pte Ltd (Singapore), a company, not a charity — " +
    "contributions support the project and are not tax-deductible. We say so because " +
    "honesty is the whole point.",

  /**
   * On-chain consent — must render verbatim at the crypto send point, BEFORE the
   * address/QR is shown, behind an affirmative action. (Phase 2 / crypto channel,
   * not live yet — pending legal sign-off before any crypto address is shown.)
   */
  onChainConsent:
    "On-chain contributions are public and permanent. If you send USDC to this address, " +
    "the transaction — including your wallet address and amount — is recorded on the Base " +
    "blockchain forever, publicly, and cannot be deleted, hidden, or made private by us or " +
    "anyone. This is the opposite of the fiat path. If you want your contribution to stay " +
    "private, use the card/bank option instead. By sending on-chain, you accept that your " +
    "contribution is permanently public.",

  /**
   * Funder/sponsor INTEREST reassurance (#61). Shown next to the
   * register-funder-interest control. Legal-weight ("not a pledge / not a
   * payment") — lives here, not hardcoded in a component, so Legal owns the
   * exact words via CODEOWNERS. Phase-1 interest capture only; money flows
   * remain blocked on #39.
   */
  funderInterestReassurance:
    "Registering your interest is not a payment or a pledge — nothing is charged and you are not " +
    "committing to give. It only lets us tell you the moment contributions open, so you can decide " +
    "then. You can withdraw your interest at any time.",
} as const;
