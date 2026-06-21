// Public supporter wall — backend projection built STRICTLY from consent.
//
// The world-readable `publicSupporters` collection is the only thing the public
// wall reads (rules never crack open a private users/contributions doc). It is
// writable ONLY here. The contract (THREAT-MODEL §4):
//
//   - A supporter appears ONLY with the fields they opted into:
//       optInDisplayName  -> displayName
//       optInDisplayAmount -> displayAmount (summed from their money contributions)
//   - Opting out (either flag) or deleting the account REMOVES the entry —
//     withdrawal is honored on the next write, automatically.
//   - Amounts are derived from the contributions ledger (backend source of
//     truth); the client never supplies them.
//
// NON-CORRELATABLE BY DESIGN (THREAT-MODEL §6): the public doc is keyed by a
// random id, NOT the user's uid, and carries NO uid field — so listing the
// world-readable wall never discloses who its supporters are, and an
// amount-only opt-in stays genuinely anonymous. The private `supporterIndex`
// (uid -> public id) lives in a default-denied collection so we can still find
// and rebuild/remove a user's entry. We REPLACE the public doc on every rebuild
// (set without merge) so it reflects exactly the current consent — never a
// stale leftover field.

import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { db } from "./firebaseAdmin";
import { consentChanged, readConsentState, recordConsent } from "./consent";

// Projection triggers get a higher cap than the shared global so a burst of
// contribution writes can't queue opt-OUT reprojections behind the default
// limit (withdrawal latency is a privacy concern, not just throughput).
const PROJECTION_MAX_INSTANCES = 20;

/** Sum a supporter's money contributions, wei-native. Returns null if none. */
async function computePublicAmountWei(uid: string): Promise<string | null> {
  const snap = await db
    .collection("contributions")
    .where("ownerUid", "==", uid)
    .where("kind", "==", "money")
    .get();

  let total = 0n;
  for (const doc of snap.docs) {
    const wei = doc.get("amountWei");
    if (typeof wei === "string") {
      try {
        total += BigInt(wei);
      } catch {
        // Skip a malformed amount rather than poison the whole sum.
      }
    }
  }
  return total > 0n ? total.toString() : null;
}

/**
 * The public projection a user currently consents to, or null if they should
 * not be on the wall (no consent, nothing to show, or account gone).
 */
async function computeEntry(uid: string): Promise<Record<string, unknown> | null> {
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists) return null; // account gone -> no wall entry

  const u = userSnap.data() ?? {};
  const optName = u.optInDisplayName === true;
  const optAmount = u.optInDisplayAmount === true;
  if (!optName && !optAmount) return null; // no consent -> withdraw

  const entry: Record<string, unknown> = {};
  if (optName) {
    const name = typeof u.displayName === "string" ? u.displayName.trim() : "";
    entry.displayName = name || "A supporter";
  }
  if (optAmount) {
    const amount = await computePublicAmountWei(uid);
    if (amount) entry.displayAmount = amount;
  }

  // Consented but nothing yet to show (e.g. amount-only opt-in, no contribution).
  if (entry.displayName === undefined && entry.displayAmount === undefined) return null;

  entry.consentVersion = u.consentVersion ?? null;
  entry.publishedAt = FieldValue.serverTimestamp();
  return entry; // NOTE: deliberately carries NO uid — the wall must stay non-correlatable.
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

// A contribution changed -> reproject its owner (amount may have moved).
export const onContributionWritten = onDocumentWritten(
  { document: "contributions/{id}", maxInstances: PROJECTION_MAX_INSTANCES },
  async (event) => {
    const after = event.data?.after;
    const before = event.data?.before;
    const ownerUid =
      (after?.exists ? after.get("ownerUid") : before?.get("ownerUid")) as string | undefined;
    if (ownerUid) await rebuildSupporter(ownerUid);
  }
);
