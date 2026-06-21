// Public supporter wall — backend projection built STRICTLY from consent.
//
// The world-readable `publicSupporters` collection is the only thing the public
// wall reads (rules never crack open a private users/contributions doc). It is
// writable ONLY here. The contract (THREAT-MODEL §4):
//
//   - A supporter appears ONLY if they opted in:  optInDisplayName -> displayName
//   - Opting out or deleting the account REMOVES the entry — withdrawal is
//     honored on the next write, automatically.
//
// NAME-ONLY, NO AMOUNT (#36, wall Version B "Flat Wall"): opt-in to be named is
// NOT opt-in to be priced. The projection is structurally incapable of carrying
// a per-person amount — there is no amount field and no contribution read here,
// so an exact figure cannot leak even by mistake. The wall reads only the user
// doc. (A future contribution-derived signal — e.g. a money/in-kind/labor tag —
// would reintroduce a contribution trigger; deliberately out of scope until the
// live wall is built.)
//
// NON-CORRELATABLE BY DESIGN (THREAT-MODEL §6): the public doc is keyed by a
// random id, NOT the user's uid, and carries NO uid field — so listing the
// world-readable wall never discloses the private uid behind an entry. The
// private `supporterIndex` (uid -> public id) lives in a default-denied
// collection so we can still find and rebuild/remove a user's entry. We REPLACE
// the public doc on every rebuild (set without merge) so it reflects exactly the
// current consent — never a stale leftover field.

import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { db } from "./firebaseAdmin";
import { consentChanged, readConsentState, recordConsent } from "./consent";

// Projection triggers get a higher cap than the shared global so a burst of
// contribution writes can't queue opt-OUT reprojections behind the default
// limit (withdrawal latency is a privacy concern, not just throughput).
const PROJECTION_MAX_INSTANCES = 20;

/**
 * The public projection a user currently consents to, or null if they should
 * not be on the wall (not opted in, or account gone). Name-only by design —
 * the wall never carries an amount (#36).
 */
async function computeEntry(uid: string): Promise<Record<string, unknown> | null> {
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists) return null; // account gone -> no wall entry

  const u = userSnap.data() ?? {};
  if (u.optInDisplayName !== true) return null; // no consent -> withdraw

  const name = typeof u.displayName === "string" ? u.displayName.trim() : "";
  return {
    displayName: name || "A supporter",
    consentVersion: u.consentVersion ?? null,
    publishedAt: FieldValue.serverTimestamp(),
    // NOTE: deliberately NO uid and NO amount — the wall stays non-correlatable
    // and structurally priceless ("named ≠ priced").
  };
}

/**
 * Allocate (or look up) the random public-doc id for a uid, transactionally so
 * two concurrent rebuilds can't mint two docs for the same person.
 */
async function ensurePublicId(uid: string): Promise<string> {
  const indexRef = db.collection("supporterIndex").doc(uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(indexRef);
    if (snap.exists) return snap.get("publicId") as string;
    const publicId = db.collection("publicSupporters").doc().id; // random, non-correlatable
    tx.set(indexRef, { publicId, ownerUid: uid, updatedAt: FieldValue.serverTimestamp() });
    return publicId;
  });
}

/** Rebuild (or remove) one supporter's public entry from current consent. */
async function rebuildSupporter(uid: string): Promise<void> {
  const entry = await computeEntry(uid);
  const indexRef = db.collection("supporterIndex").doc(uid);

  if (!entry) {
    // Withdraw: drop the public doc (if any) and forget the mapping.
    const indexSnap = await indexRef.get();
    if (indexSnap.exists) {
      const publicId = indexSnap.get("publicId") as string;
      await db.collection("publicSupporters").doc(publicId).delete().catch(() => undefined);
      await indexRef.delete().catch(() => undefined);
    }
    return;
  }

  const publicId = await ensurePublicId(uid);
  await db.collection("publicSupporters").doc(publicId).set(entry); // full replace, no uid
  logger.debug("rebuildSupporter published", { uid, publicId, fields: Object.keys(entry) });
}

// A user's profile/consent changed -> record consent (if it moved) and reproject.
export const onUserWritten = onDocumentWritten(
  { document: "users/{uid}", maxInstances: PROJECTION_MAX_INSTANCES },
  async (event) => {
    const uid = event.params.uid;
    const before = readConsentState(event.data?.before?.data());
    const after = readConsentState(event.data?.after?.data());

    // Tamper-evident consent trail: log only when the consent state actually
    // moved, and only while the account still exists (a delete is not consent).
    if (event.data?.after?.exists && consentChanged(before, after)) {
      await recordConsent(uid, after);
    }

    await rebuildSupporter(uid);
  }
);

// NOTE: there is deliberately NO contributions trigger. The wall is name-only,
// derived solely from the users doc, so a contribution write can't change a
// public entry — and the projection never reads the ledger. A contributions
// trigger would return only if/when the live wall adds a contribution-derived
// signal (e.g. a money/in-kind/labor tag), and even then never an amount (#36).
