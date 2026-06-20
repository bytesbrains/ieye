// Google sign-in button. Honest, calm, accessible. Shows errors as plain text.

import { useState } from "react";
import { useAuth } from "../../auth/AuthProvider";

export function GoogleSignInButton({ onSignedIn }: { onSignedIn?: () => void }) {
  const { signInWithGoogle } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleClick() {
    setBusy(true);
    setError(null);
    try {
      await signInWithGoogle();
      onSignedIn?.();
    } catch (e) {
      const code = (e as { code?: string })?.code ?? "";
      if (code === "auth/popup-closed-by-user" || code === "auth/cancelled-popup-request") {
        setError("Sign-in was cancelled. You can try again whenever you're ready.");
      } else {
        setError("Sign-in didn't go through. Please try again in a moment.");
      }
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
      {error && (
        <p role="alert" className="field-error mt-3 text-center">
          {error}
        </p>
      )}
    </div>
  );
}
