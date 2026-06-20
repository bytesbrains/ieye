// Live subscription to the signed-in user's OWN contributions only.
// Rules permit a user to read contributions where ownerUid == their uid; they
// can NEVER write this collection (money is backend-only, THREAT-MODEL §7.1).
// Until the backend writes ledger entries (#42/Phase 2), this is empty.

import { useEffect, useState } from "react";
import { collection, onSnapshot, orderBy, query, where } from "firebase/firestore";
import { db } from "./firebase";
import type { ContributionDoc, WithId } from "./types";
import { useAuth } from "../auth/AuthProvider";

export function useMyContributions() {
  const { user } = useAuth();
  const [rows, setRows] = useState<WithId<ContributionDoc>[]>([]);
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
      collection(db, "contributions"),
      where("ownerUid", "==", user.uid),
      orderBy("timestamp", "desc")
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        setRows(snap.docs.map((d) => ({ id: d.id, ...(d.data() as ContributionDoc) })));
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
