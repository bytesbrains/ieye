// Admin-only data access (Phase 1.5, #43). These queries succeed ONLY for a
// user whose ID-token carries the `admin` custom claim — the rules grant admins
// read across users/contributions/requests and update on contributorRequests.
//
// What admins can do from the client (allowed by rules):
//   - read all contributorRequests; ADVANCE status (requested->vetted->invited)
//   - read all contributions (read-only — NO client write, ever)
//   - read all users (support)
// What requires the BACKEND / Functions (NOT possible from here):
//   - writing contributions (money is backend-only)
//   - building publicSupporters from consent
//   - minting/revoking the admin claim itself

import {
  collection,
  doc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
} from "firebase/firestore";
import { db, auth } from "./firebase";
import type {
  ContributionDoc,
  ContributorRequestDoc,
  RequestStatus,
  UserDoc,
  WithId,
} from "./types";

export async function fetchContributorRequests(): Promise<WithId<ContributorRequestDoc>[]> {
  const q = query(collection(db, "contributorRequests"), orderBy("createdAt", "desc"));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as ContributorRequestDoc) }));
}

const NEXT_STATUS: Partial<Record<RequestStatus, RequestStatus>> = {
  requested: "vetted",
  vetted: "invited",
};

export function nextStatus(s: RequestStatus): RequestStatus | null {
  return NEXT_STATUS[s] ?? null;
}

/** Advance a request one step. Only admins may do this (rules enforce). */
export async function advanceRequest(
  id: string,
  current: RequestStatus
): Promise<void> {
  const next = nextStatus(current);
  if (!next) return;
  await updateDoc(doc(db, "contributorRequests", id), {
    status: next,
    vettedBy: auth.currentUser?.uid ?? null,
    vettedAt: serverTimestamp(),
  });
}

export async function fetchContributions(max = 50): Promise<WithId<ContributionDoc>[]> {
  const q = query(collection(db, "contributions"), orderBy("timestamp", "desc"), limit(max));
  const snap = await getDocs(q);
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as ContributionDoc) }));
}

export async function fetchUsers(max = 50): Promise<WithId<UserDoc>[]> {
  const snap = await getDocs(query(collection(db, "users"), limit(max)));
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as UserDoc) }));
}
