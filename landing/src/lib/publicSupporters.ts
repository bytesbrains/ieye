// Reads the world-readable supporter projection (publicSupporters) for the
// landing wall. This is the ONLY thing the public wall reads — it carries the
// consented display name and NOTHING ELSE (no uid, no amount; #36 "named ≠
// priced"), so rendering it can never leak who contributed or how much.
//
// Imported ONLY via a dynamic import() from SupporterWall, so Firebase stays out
// of the main landing bundle (same discipline as lib/waitlist.ts). A one-shot
// read (not a live subscription) — the wall doesn't need realtime.

import { collection, getDocs } from "firebase/firestore";
import { db } from "./firebase";
import type { PublicSupporterDoc, WithId } from "./types";

export async function fetchPublicSupporters(): Promise<WithId<PublicSupporterDoc>[]> {
  const snap = await getDocs(collection(db, "publicSupporters"));
  const rows = snap.docs.map((d) => ({ id: d.id, ...(d.data() as PublicSupporterDoc) }));
  // Flat wall, equal weight, NO size-sort (#36, Version B): order is not a
  // signal. Sort by name only, for stable rendering.
  return rows.sort((a, b) => (a.displayName ?? "").localeCompare(b.displayName ?? ""));
}
