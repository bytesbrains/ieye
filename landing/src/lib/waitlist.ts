// Waitlist sign-up via Google — the public landing's "Continue with Google" CTA.
//
// This module is imported ONLY via a dynamic import() inside the CTA's click
// handler (see components/WaitlistCta.tsx), so Firebase never enters the main
// landing bundle. A first-time visitor who never clicks downloads no Firebase.
//
// We capture name + email straight from the Google profile and record interest
// on the user's OWN users/{uid} doc — the same owner-writable doc the rules
// already allow (no new collection, no rules change). Money/contributions stay
// backend-only; this only sets a benign "notify me" flag.

import { signInWithPopup } from "firebase/auth";
import { doc, serverTimestamp, setDoc } from "firebase/firestore";
import { auth, db, googleProvider } from "./firebase";
import { CONSENT_VERSION } from "./useUserDoc";

export interface WaitlistResult {
  displayName: string;
  email: string;
}

/**
 * Sign in with Google and flag the user onto the launch waitlist. Idempotent:
 * the write is a merge, so signing up twice is harmless. Returns the captured
 * name/email so the CTA can confirm it back to the user.
 */
export async function joinWaitlistWithGoogle(): Promise<WaitlistResult> {
  const { user } = await signInWithPopup(auth, googleProvider);

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
