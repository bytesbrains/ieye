// One-time cleanup: remove the dead amount fields left behind by #36.
//
// WHY: the supporter wall is now name-only ("named ≠ priced", #36). The
// `optInDisplayAmount` opt-in and the `displayAmount` projection field were
// dropped from the code, but docs written BEFORE that change may still carry an
// inert copy:
//   - users/{uid}.optInDisplayAmount        (no longer read; rules now refuse
//                                             to add or change it)
//   - publicSupporters/{id}.displayAmount    (no longer projected or typed)
// They are harmless (nothing reads them and the wall isn't live yet), but this
// script sweeps them so "structurally impossible to publish an amount" is true
// for pre-existing docs too — not just new writes.
//
// SAFE TO RE-RUN. Idempotent: it only touches docs that still carry the field,
// and only ever DELETES those two fields (FieldValue.delete()) — never anything
// else. Defaults to a DRY RUN; pass --apply to actually write.
//
// USAGE (from landing/functions):
//   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json \
//   GOOGLE_CLOUD_PROJECT=ieye-in \
//   node scripts/purge-legacy-amount.mjs            # dry run — reports counts
//   node scripts/purge-legacy-amount.mjs --apply    # actually delete the fields

import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const APPLY = process.argv.includes("--apply");
const BATCH_LIMIT = 400; // under Firestore's 500-write batch cap

if (getApps().length === 0) initializeApp();
const db = getFirestore();

/**
 * Delete `field` from every doc in `collection` that still carries it.
 * Returns the number of docs updated (or that WOULD be updated, in dry run).
 */
async function purgeField(collection, field) {
  const snap = await db.collection(collection).get();
  const stale = snap.docs.filter((d) => d.get(field) !== undefined);

  if (!APPLY) return stale.length;

  let batch = db.batch();
  let pending = 0;
  for (const d of stale) {
    batch.update(d.ref, { [field]: FieldValue.delete() });
    if (++pending >= BATCH_LIMIT) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending > 0) await batch.commit();
  return stale.length;
}

async function main() {
  const users = await purgeField("users", "optInDisplayAmount");
  const supporters = await purgeField("publicSupporters", "displayAmount");

  const verb = APPLY ? "purged" : "would purge (dry run)";
  console.log(`users.optInDisplayAmount:        ${verb} ${users}`);
  console.log(`publicSupporters.displayAmount:  ${verb} ${supporters}`);
  if (!APPLY) console.log("\nRe-run with --apply to write the changes.");
}

main().then(
  () => process.exit(0),
  (err) => {
    console.error(err);
    process.exit(1);
  }
);
