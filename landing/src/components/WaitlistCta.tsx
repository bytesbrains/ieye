// Waitlist call-to-action for the public landing.
//
// Replaces the old manual email form: instead of typing an address, the visitor
// signs in with Google and we capture their name + email from the profile. The
// Firebase code is loaded with a dynamic import() INSIDE the click handler, so
// this component adds zero Firebase weight to the main landing bundle — a
// visitor who never clicks downloads none of it.

import { useState } from "react";

type Status = "idle" | "submitting" | "done" | "error";

export function WaitlistCta() {
  const [status, setStatus] = useState<Status>("idle");
  const [name, setName] = useState("");
  const [error, setError] = useState("");

  async function handleClick() {
    setStatus("submitting");
    setError("");
    try {
      // Lazy boundary — Firebase enters only here, only on a real click.
      const { joinWaitlistWithGoogle } = await import("../lib/waitlist");
      const res = await joinWaitlistWithGoogle();
      setName(res.displayName);
      setStatus("done");
    } catch (e) {
      const code = (e as { code?: string })?.code ?? "";
      if (code === "auth/popup-closed-by-user" || code === "auth/cancelled-popup-request") {
        setError("Sign-in was cancelled. You can try again whenever you're ready.");
      } else {
        setError("That didn't go through. Please try again in a moment.");
      }
      setStatus("error");
    }
  }

  if (status === "done") {
    return (
      <div
        role="status"
        className="rounded-2xl border-2 border-amber/40 bg-amber/5 p-6 text-center"
      >
        <p className="text-xl font-semibold text-charcoal">
          {name ? `You’re on the list, ${name}.` : "You’re on the list."}
        </p>
        <p className="mt-2 text-base text-charcoal-soft">
          We&rsquo;ll let you know the moment iEye opens. No spam, ever.
        </p>
      </div>
    );
  }

  return (
    <div>
      <button
        type="button"
        onClick={handleClick}
        disabled={status === "submitting"}
        className="btn btn-primary w-full disabled:cursor-not-allowed disabled:opacity-60"
      >
        {/* Google "G" glyph */}
        <svg className="h-5 w-5" viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill="#EA4335"
            d="M12 10.2v3.9h5.5c-.24 1.4-1.66 4.1-5.5 4.1a6.2 6.2 0 0 1 0-12.4c1.94 0 3.25.82 4 1.53l2.72-2.62C17.06 2.9 14.76 2 12 2a10 10 0 0 0 0 20c5.77 0 9.6-4.06 9.6-9.78 0-.66-.07-1.16-.16-1.66H12z"
          />
        </svg>
        {status === "submitting" ? "Signing in…" : "Continue with Google"}
      </button>
      {status === "error" && (
        <p role="alert" className="field-error mt-3 text-center">
          {error}
        </p>
      )}
      <p className="mt-4 text-sm text-charcoal-muted">
        We use your Google name and email only to tell you when iEye opens — nothing else, no spam.
        Your address stays private.
      </p>
    </div>
  );
}
