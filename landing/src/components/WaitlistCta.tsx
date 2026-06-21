// Waitlist call-to-action for the public landing.
//
// The visitor signs in with Google and we capture their name + email from the
// profile — no email field to type. The Firebase code is loaded with a dynamic
// import() so this component adds zero Firebase weight to the main landing
// bundle; a visitor who never signs in downloads none of it.
//
// Sign-in is a REDIRECT, not a popup (popups hang under COOP on *.web.app — see
// lib/waitlist.ts). A redirect unloads the page, so the flow has two halves:
//   • click  -> beginWaitlistWithGoogle() navigates away to Google
//   • return -> completePendingWaitlist() finishes the write and confirms
// We detect the return with a tiny Firebase-free marker (hasPendingWaitlist), so
// the heavy completion path only loads when we're actually coming back signed in.

import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { hasPendingWaitlist } from "../lib/waitlistPending";

type Status = "idle" | "redirecting" | "finishing" | "done" | "error";

export function WaitlistCta() {
  const [status, setStatus] = useState<Status>("idle");
  const [name, setName] = useState("");
  const [error, setError] = useState("");

  // On return from the Google redirect, finish the waitlist write. Guarded by a
  // cheap, Firebase-free marker so a normal visit loads no Firebase here.
  useEffect(() => {
    if (!hasPendingWaitlist()) return;
    let cancelled = false;
    setStatus("finishing");
    (async () => {
      try {
        const { completePendingWaitlist } = await import("../lib/waitlist");
        const res = await completePendingWaitlist();
        if (cancelled) return;
        if (res) {
          setName(res.displayName);
          setStatus("done");
        } else {
          // No pending redirect result (e.g. user cancelled at Google).
          setStatus("idle");
        }
      } catch {
        if (cancelled) return;
        setError("That didn't go through. Please try again in a moment.");
        setStatus("error");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  async function handleClick() {
    setStatus("redirecting");
    setError("");
    try {
      // Lazy boundary — Firebase enters only here, only on a real click.
      const { beginWaitlistWithGoogle } = await import("../lib/waitlist");
      await beginWaitlistWithGoogle(); // navigates away; code below won't run
    } catch {
      setError("Couldn't start sign-in. Please try again in a moment.");
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

  if (status === "finishing") {
    return (
      <div role="status" className="rounded-2xl border-2 border-charcoal/10 bg-paper p-6 text-center">
        <p className="text-base font-medium text-charcoal-soft">Finishing sign-in…</p>
      </div>
    );
  }

  const busy = status === "redirecting";
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
        {busy ? "Redirecting…" : "Continue with Google"}
      </button>
      {status === "error" && (
        <p role="alert" className="field-error mt-3 text-center">
          {error}
        </p>
      )}
      <p className="mt-4 text-sm text-charcoal-muted">
        We use your Google name and email only to tell you when iEye opens — nothing else, no spam.
        Your address stays private. See our{" "}
        <Link to="/privacy" className="underline hover:text-charcoal">
          Privacy Notice
        </Link>
        .
      </p>
    </div>
  );
}
