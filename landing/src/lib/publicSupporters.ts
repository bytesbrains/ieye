// Reads the world-readable supporter projection (publicSupporters) for the
// landing wall. This is the ONLY thing the public wall reads — it carries the
// consented display name and NOTHING ELSE (no uid, no email, no amount; #36
// "named ≠ priced"), so rendering it can never leak who contributed or how much.
//
// Imported ONLY via a dynamic import() from SupporterWall, so Firebase stays out
// of the main landing bundle (same discipline as lib/waitlist.ts).
//
// PAGINATED: the query is always bounded by `limit` and walked with a cursor, so
// the wall never reads the whole collection — it stays cheap whether there are
// 3 supporters or 30,000. Order is by name only (flat wall, equal weight, NO
// size-sort, #36); name is not a private signal.

import {
  collection,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  type QueryDocumentSnapshot,
} from "firebase/firestore";
import { db } from "./firebase";
import type { PublicSupporterDoc, WithId } from "./types";

export interface SupporterPage {
  rows: WithId<PublicSupporterDoc>[];
  /** Opaque cursor for the next page (pass back as `after`); null when done. */
  cursor: unknown;
  hasMore: boolean;
}

export async function fetchPublicSupporters(
  pageSize: number,
  after?: unknown
): Promise<SupporterPage> {
  const col = collection(db, "publicSupporters");
  const q = after
    ? query(col, orderBy("displayName"), startAfter(after as QueryDocumentSnapshot), limit(pageSize))
    : query(col, orderBy("displayName"), limit(pageSize));

  const snap = await getDocs(q);
  const rows = snap.docs.map((d) => ({ id: d.id, ...(d.data() as PublicSupporterDoc) }));
  const last = snap.docs[snap.docs.length - 1] ?? null;
  return { rows, cursor: last, hasMore: snap.docs.length === pageSize };
}
