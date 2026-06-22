// Google sign-in button. Honest, calm, accessible. Shows errors as plain text.

import { useState } from "react";
import { useAuth } from "../../auth/AuthProvider";

// Map a Firebase auth error code to calm, honest copy. Covers both redirect-side
// failures (surfaced via authError on return) and the rarer click-handler throws.
// Default stays vague on purpose — we never invent a cause we can't confirm.
function messageForCode(code: string): string {
  switch (code) {
    case "auth/popup-closed-by-user":
    case "auth/cancelled-popup-request":
    case "auth/user-cancelled":
      return "Sign-in was cancelled. You can try again whenever you're ready.";
    case "auth/unauthorized-domain":
      // Config issue: this site's domain isn't on the project's authorized list.
      // The user can't fix it, so say so plainly rather than imply "try again".
      return "Sign-in isn't enabled for this site yet. This is on our end — please let us know, or try again from ieye-in.web.app.";
    case "auth/operation-not-allowed":
    case "auth/configuration-not-found":
      return "Google sign-in isn't available right now. This is on our end — please try again later.";
    case "auth/network-request-failed":
      return "We couldn't reach Google. Check your connection and try again.";
    case "auth/too-many-requests":
      return "Too many attempts. Please wait a moment and try again.";
    default:
      return "Sign-in didn't go through. Please try again in a moment.";
  }
}

export function GoogleSignInButton({ onSignedIn }: { onSignedIn?: () => void }) {
  const { signInWithGoogle, authError, clearAuthError } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // A redirect-side failure (e.g. auth/unauthorized-domain) unloads the page
  // before handleClick's catch can run, so it arrives via authError instead.
  // Prefer a local throw if one just happened; otherwise show the redirect error.
  const shownError = error ?? (authError ? messageForCode(authError) : null);

  async function handleClick() {
    setBusy(true);
    setError(null);
    clearAuthError(); // a fresh attempt clears any stale redirect error
    try {
      await signInWithGoogle();
      onSignedIn?.();
    } catch (e) {
      const code = (e as { code?: string })?.code ?? "";
      setError(messageForCode(code));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <button
        type="button"
        onClick={handleClick}
        disabled={busy}
        className="btn btn-primary w-full disabled:cursor-not-allowed disabled:opacity-60"
      >
        {/* Google "G" glyph */}
        <svg className="h-5 w-5" viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill="#EA4335"
            d="M12 10.2v3.9h5.5c-.24 1.4-1.66 4.1-5.5 4.1a6.2 6.2 0 0 1 0-12.4c1.94 0 3.25.82 4 1.53l2.72-2.62C17.06 2.9 14.76 2 12 2a10 10 0 0 0 0 20c5.77 0 9.6-4.06 9.6-9.78 0-.66-.07-1.16-.16-1.66H12z"
          />
        </svg>
        {busy ? "Signing in…" : "Continue with Google"}
      </button>
      {shownError && (
        <p role="alert" className="field-error mt-3 text-center">
          {shownError}
        </p>
      )}
    </div>
  );
}
