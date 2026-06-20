// The signed-in user's own contributorRequests (read own), plus a creator that
// satisfies the rules: ownerUid == auth.uid and status == 'requested'. Only
// admins advance status (THREAT-MODEL §7.4) — the UI here can never set a later
// status.

import { useEffect, useState } from "react";
import {
  addDoc,
  collection,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  where,
} from "firebase/firestore";
import { db } from "./firebase";
import type { ContributorRequestDoc, WithId } from "./types";
import { useAuth } from "../auth/AuthProvider";

export function useMyContributorRequests() {
  const { user } = useAuth();
  const [rows, setRows] = useState<WithId<ContributorRequestDoc>[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) {
      setRows([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    const q = query(
      collection(db, "contributorRequests"),
      where("ownerUid", "==", user.uid),
      orderBy("createdAt", "desc")
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        setRows(snap.docs.map((d) => ({ id: d.id, ...(d.data() as ContributorRequestDoc) })));
        setLoading(false);
      },
      (err) => {
        setError(err.message);
        setLoading(false);
      }
    );
    return unsub;
  }, [user]);

  return { rows, loading, error };
}

/** Create a 'requested' contributor request owned by the current user. */
export async function createContributorRequest(
  uid: string,
  fields: { skills?: string; links?: string; note?: string }
): Promise<void> {
  await addDoc(collection(db, "contributorRequests"), {
    ownerUid: uid, // must equal auth.uid (rules enforce)
    status: "requested", // must start here (rules enforce)
    skills: fields.skills ?? "",
    links: fields.links ?? "",
    note: fields.note ?? "",
    createdAt: serverTimestamp(),
  });
}
