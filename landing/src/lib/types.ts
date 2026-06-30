// Firestore data-model types (Phase 1.5, #43).
//
// These mirror the contract documented in firestore-tests/THREAT-MODEL.md §2.
// Field names MUST stay in sync with the rules + backend Functions.
//
// IMPORTANT: there is deliberately NO `role`/`admin`/`claims` field on UserDoc.
// Admin authority is a Firebase Auth custom claim, never Firestore data.

import type { Timestamp } from "firebase/firestore";

/** users/{uid} — one doc per authenticated user. Doc id IS the uid. */
export interface UserDoc {
  displayName?: string;
  email?: string;
  photoURL?: string;
  /** Opt-IN to show name on the public wall. Default false. (#36/#38 §4) */
  optInDisplayName?: boolean;
  /** Which privacy-notice version the user consented to (#38 §4.5). */
  consentVersion?: string;
  consentAt?: Timestamp;
  /** Opted in to the launch waitlist from the public landing (#42). */
  waitlistOptIn?: boolean;
  waitlistAt?: Timestamp;
  /**
   * Registered INTEREST in helping fund/sponsor iEye, from the landing
   * "why this needs support" path (#61). Interest only — never a payment, a
   * pledge, or an amount. Live money flows stay blocked on Legal (#39); this
   * bit only lets us reach out the moment contributions open.
   */
  funderInterestOptIn?: boolean;
  funderInterestAt?: Timestamp;
}

export type ContributionKind = "money" | "inkind" | "labor";
export type ContributionMethod = "card" | "bank" | "crypto" | "inkind" | "labor";

/** contributions/{id} — ledger source of truth. CLIENTS NEVER WRITE THIS. */
export interface ContributionDoc {
  ownerUid: string;
  kind: ContributionKind;
  /** Wei-native amount string for crypto money lines (no fiat literals). */
  amountWei?: string;
  asset?: string;
  /** Fiat amount in MINOR units (cents) as a string — no floats in money. */
  amountMinor?: string;
  /** ISO currency code for fiat lines, e.g. "SGD". */
  currency?: string;
  /** Payment provider for money lines, e.g. "stripe". */
  provider?: string;
  /** Provider's session/charge id, for reconciliation. */
  providerSessionId?: string;
  method: ContributionMethod;
  /** Set by backend from consent state — never by the client. */
  isPublic?: boolean;
  timestamp?: Timestamp;
  status?: string;
  reconciledAt?: Timestamp;
}

/**
 * publicSupporters/{id} — world-readable projection of CONSENTED fields only.
 *
 * Carries NO amount, by design (#36, wall Version B "Flat Wall"): opt-in to be
 * named is NOT opt-in to be priced, so the projection is structurally incapable
 * of publishing a per-person figure. Recognition is name-only; the gradient is
 * recovered off the wall (org/partner strip + private receipts).
 */
export interface PublicSupporterDoc {
  displayName?: string;
  publishedAt?: Timestamp;
  featured?: boolean;
}

export type RequestStatus = "requested" | "vetted" | "invited";

/** contributorRequests/{id} — request -> vetted -> invited (#36). */
export interface ContributorRequestDoc {
  ownerUid: string;
  /** Must start at 'requested' on create; only admins advance it. */
  status: RequestStatus;
  skills?: string;
  links?: string;
  note?: string;
  createdAt?: Timestamp;
  vettedBy?: string;
  vettedAt?: Timestamp;
}

/** A doc plus its Firestore id, for list rendering. */
export type WithId<T> = T & { id: string };
