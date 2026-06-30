// Live subscription to the signed-in user's own `users/{uid}` doc, plus a
// helper to upsert profile + opt-in flags. The user may only ever read/write
// their own doc (rules enforce this — owner isolation, THREAT-MODEL §3).
//
// We never write `admin`/`role`/`claims` fields here; the rules'
// hasNoPrivilegeEscalation() guard would reject it anyway, and admin authority
// lives in the custom claim, not Firestore.

import { useEffect, useState } from "react";
import { doc, onSnapshot, serverTimestamp, setDoc } from "firebase/firestore";
import { db } from "./firebase";
import type { UserDoc } from "./types";
import { useAuth } from "../auth/AuthProvider";

// Single source of truth for the notice version lives in a Firebase-free module
// (so the public /privacy page can use it without pulling in Firebase). Import for
// local use and re-export so existing `import { CONSENT_VERSION } from
// "./useUserDoc"` keeps working.
import { CONSENT_VERSION } from "./consentVersion";
export { CONSENT_VERSION };

export function useUserDoc() {
  const { user } = useAuth();
  const [data, setData] = useState<UserDoc | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) {
      setData(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    const ref = doc(db, "users", user.uid);
    const unsub = onSnapshot(
      ref,
      (snap) => {
        setData(snap.exists() ? (snap.data() as UserDoc) : null);
        setLoading(false);
      },
      (err) => {
        setError(err.message);
        setLoading(false);
      }
    );
    return unsub;
  }, [user]);

  return { data, loading, error };
}

/**
 * Create-or-merge the user's profile. Used on first sign-in to seed the doc
 * from the Google profile, and to flip opt-in flags. Merge so we never clobber
 * existing consent/opt-in state.
 */
export async function upsertUserProfile(
  uid: string,
  patch: Partial<UserDoc>,
  opts: { recordConsent?: boolean; stampFunderInterest?: boolean } = {}
): Promise<void> {
  const ref = doc(db, "users", uid);
  const payload: Record<string, unknown> = { ...patch };
  if (opts.recordConsent) {
    payload.consentVersion = CONSENT_VERSION;
    payload.consentAt = serverTimestamp();
  }
  // Stamp the most recent time funder interest was registered (the caller sets
  // this flag only when turning interest ON; re-opting-in refreshes it) so we
  // know when to reach out once contributions open (#61). Interest only.
  if (opts.stampFunderInterest) {
    payload.funderInterestAt = serverTimestamp();
  }
  await setDoc(ref, payload, { merge: true });
}
