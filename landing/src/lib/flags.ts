// Build-time feature flags.
//
// FIAT_CONTRIB_ENABLED gates whether the money-contribution UI is rendered. It
// is OFF unless VITE_FIAT_CONTRIB_ENABLED is exactly "true" at build time.
//
// This is a UI convenience only — NOT the security boundary. The real gate is
// server-side: the createContributionCheckout callable refuses unless the
// backend FIAT_CONTRIB_ENABLED param is "true" AND the Stripe secrets are set
// (functions/src/stripe.ts). So even a tampered build that flips this on cannot
// take money until the backend gate (and Legal #39) is deliberately opened.

export const FIAT_CONTRIB_ENABLED = import.meta.env.VITE_FIAT_CONTRIB_ENABLED === "true";
