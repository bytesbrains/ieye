// Waitlist sign-up via Google — the public landing's "Continue with Google" CTA.
//
// This module is imported ONLY via a dynamic import() inside the CTA's click
// handler and (on return) its completion path, so Firebase never enters the main
// landing bundle. A first-time visitor who never clicks downloads no Firebase.
//
// We capture name + email straight from the Google profile and record interest
// on the user's OWN users/{uid} doc — the same owner-writable doc the rules
// already allow (no new collection, no rules change). Money/contributions stay
// backend-only; this only sets a benign "notify me" flag.
//
// SIGN-IN USES REDIRECT, NOT POPUP. On *.web.app (incl. the live ieye-in.web.app)
// COOP severs the popup's cross-window channel, so signInWithPopup opens, the
// user signs in, and the promise NEVER resolves — the CTA hangs forever. A
// redirect is a top-level navigation, immune to that. This is the same fix #48
// applied to the authed app; the public waitlist needs it too. Because a
// redirect unloads the page, the flow is split: begin() before we navigate away,
// complete() on return.

import { getRedirectResult, signInWithRedirect } from "firebase/auth";
import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { auth, db, googleProvider } from "./firebase";
import { CONSENT_VERSION } from "./useUserDoc";
import { clearWaitlistPending, markWaitlistPending } from "./waitlistPending";

export interface WaitlistResult {
  displayName: string;
  email: string;
}

/**
 * Start Google sign-in for the waitlist. The page unloads here (navigates to
 * Google and back) — code after this call does not run. Completion happens on
 * return via completePendingWaitlist().
 */
export async function beginWaitlistWithGoogle(): Promise<void> {
  markWaitlistPending();
  try {
    await signInWithRedirect(auth, googleProvider);
  } catch (e) {
    // Redirect failed to even start — clear the marker so we don't try to
    // "finish" a sign-in that never began.
    clearWaitlistPending();
    throw e;
  }
}

/**
 * Finish a pending waitlist sign-in after the redirect back from Google.
 * Returns the captured name/email on success, or null if there was no pending
 * redirect to complete. The Firestore write is an idempotent merge, so a repeat
 * is harmless. Surfaces auth errors (e.g. auth/unauthorized-domain) that the old
 * popup path would have swallowed.
 */
export async function completePendingWaitlist(): Promise<WaitlistResult | null> {
  let result;
  try {
    result = await getRedirectResult(auth);
  } finally {
    // The attempt is over either way — clear so a reload doesn't loop.
    clearWaitlistPending();
  }
  if (!result?.user) return null;

  const user = result.user;
  const ref = doc(db, "users", user.uid);
  await setDoc(
    ref,
    {
      // Seeded from the Google profile — the whole point of going through auth.
      displayName: user.displayName ?? "",
      email: user.email ?? "",
      photoURL: user.photoURL ?? "",
      // Benign welfare-adjacent flag: "tell me when it opens." Never a secret.
      waitlistOptIn: true,
      waitlistAt: serverTimestamp(),
      // Record consent against the current notice version (lawful basis, #38 §4.5).
      consentVersion: CONSENT_VERSION,
      consentAt: serverTimestamp(),
    },
    { merge: true }
  );

  return { displayName: user.displayName ?? "", email: user.email ?? "" };
}
