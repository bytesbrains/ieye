// Live subscription to the signed-in user's OWN contributions only.
// Rules permit a user to read contributions where ownerUid == their uid; they
// can NEVER write this collection (money is backend-only, THREAT-MODEL §7.1).
// Until the backend writes ledger entries (#42/Phase 2), this is empty.

import { useEffect, useState } from "react";
import { collection, limit, onSnapshot, orderBy, query, where } from "firebase/firestore";
import { db } from "./firebase";
import type { ContributionDoc, WithId } from "./types";
import { useAuth } from "../auth/AuthProvider";

const DEFAULT_PAGE = 25;

// Paginated so a long-running supporter's history never triggers an unbounded
// read or a runaway DOM: the live query is capped at `limitN` (most recent
// first), and loadMore() grows the window a page at a time (re-subscribes).
export function useMyContributions(pageSize = DEFAULT_PAGE) {
  const { user } = useAuth();
  const [rows, setRows] = useState<WithId<ContributionDoc>[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [limitN, setLimitN] = useState(pageSize);

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
      orderBy("timestamp", "desc"),
      limit(limitN)
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
  }, [user, limitN]);

  // If the page came back full there may be more; growing the limit re-queries.
  const hasMore = rows.length === limitN;
  const loadMore = () => setLimitN((n) => n + pageSize);

  return { rows, loading, error, hasMore, loadMore };
}
