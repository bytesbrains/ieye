// Tiny, Firebase-FREE marker for a waitlist sign-in that round-trips through
// Google's redirect.
//
// It lives apart from lib/waitlist.ts (which pulls in Firebase) on purpose: the
// landing page must check "are we returning from a sign-in redirect?" on every
// load, and it must do that WITHOUT dragging Firebase into the main bundle. Only
// when this marker says a sign-in is actually pending do we lazy-import the
// Firebase-laden completion path.

const PENDING_KEY = "ieye:waitlist-pending";

/** Set just before we navigate away to Google, so we know to finish on return. */
export function markWaitlistPending(): void {
  try {
    sessionStorage.setItem(PENDING_KEY, "1");
  } catch {
    // Storage blocked (private mode) — sign-in still works, it just can't
    // auto-resume the confirmation after the redirect.
  }
}

/** Clear the marker once an attempt is finished (success, cancel, or error). */
export function clearWaitlistPending(): void {
  try {
    sessionStorage.removeItem(PENDING_KEY);
  } catch {
    // ignore
  }
}

/** True if we're returning from a waitlist sign-in redirect. */
export function hasPendingWaitlist(): boolean {
  try {
    return sessionStorage.getItem(PENDING_KEY) === "1";
  } catch {
    return false;
  }
}
