import { useId, useState } from "react";
import { isValidEmail, submitInterest } from "../lib/submit";

type Status = "idle" | "submitting" | "done" | "error";

export function WaitlistForm() {
  const emailId = useId();
  const errId = useId();
  const [email, setEmail] = useState("");
  const [touched, setTouched] = useState(false);
  const [status, setStatus] = useState<Status>("idle");
  const [serverError, setServerError] = useState("");

  const emailError = touched && !isValidEmail(email) ? "Please enter a valid email address." : "";

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setTouched(true);
    if (!isValidEmail(email)) return;
    setStatus("submitting");
    setServerError("");
    const res = await submitInterest({ email: email.trim(), source: "waitlist" });
    if (res.ok) {
      setStatus("done");
    } else {
      setStatus("error");
      setServerError(res.error);
    }
  }

  if (status === "done") {
    return (
      <div
        role="status"
        className="rounded-2xl border-2 border-amber/40 bg-amber/5 p-6 text-center"
      >
        <p className="text-xl font-semibold text-charcoal">Thank you — you&rsquo;re on the list.</p>
        <p className="mt-2 text-base text-charcoal-soft">
          We&rsquo;ll let you know the moment iEye opens. No spam, ever.
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} noValidate className="space-y-4">
      <div>
        <label htmlFor={emailId} className="field-label">
          Email address
        </label>
        <input
          id={emailId}
          type="email"
          name="email"
          autoComplete="email"
          inputMode="email"
          required
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onBlur={() => setTouched(true)}
          aria-invalid={emailError ? true : undefined}
          aria-describedby={emailError ? errId : undefined}
          className="field-input"
        />
        {emailError && (
          <p id={errId} className="field-error" role="alert">
            {emailError}
          </p>
        )}
      </div>

      {status === "error" && (
        <p className="field-error" role="alert">
          {serverError || "Something went wrong. Please try again."}
        </p>
      )}

      <button type="submit" className="btn btn-primary w-full" disabled={status === "submitting"}>
        {status === "submitting" ? "Adding you…" : "Notify me when this opens"}
      </button>
      <p className="text-sm text-charcoal-muted">
        We&rsquo;ll only email you about iEye becoming available. Your address stays private.
      </p>
    </form>
  );
}
