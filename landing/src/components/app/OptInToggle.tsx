// Accessible toggle for an opt-in-to-be-named flag. Framed honestly as a
// REQUEST TO PUBLISH: flipping on asks the backend to publish; the backend
// mediates actual publication and honors withdrawal (THREAT-MODEL §7.5).
//
// On a *consent* control, reassurance matters most: every flip shows a clear
// save state ("Saving…" → "Saved.") and surfaces failures instead of swallowing
// them, so the user is never left unsure whether their choice took.

import { useState } from "react";

interface OptInToggleProps {
  id: string;
  label: string;
  description: string;
  checked: boolean;
  disabled?: boolean;
  onChange: (next: boolean) => Promise<void>;
}

type SaveState = "idle" | "saving" | "saved" | "error";

export function OptInToggle({
  id,
  label,
  description,
  checked,
  disabled,
  onChange,
}: OptInToggleProps) {
  const [state, setState] = useState<SaveState>("idle");
  const busy = state === "saving";

  async function handleToggle() {
    if (busy || disabled) return;
    setState("saving");
    try {
      await onChange(!checked);
      setState("saved");
    } catch {
      setState("error");
    }
  }

  return (
    <div className="py-4">
      <div className="flex items-start justify-between gap-4">
        <div className="max-w-prose">
          <label htmlFor={id} className="block text-base font-semibold text-charcoal">
            {label}
          </label>
          <p className="mt-1 text-sm text-charcoal-soft">{description}</p>
        </div>
        <button
          id={id}
          type="button"
          role="switch"
          aria-checked={checked}
          aria-label={label}
          disabled={busy || disabled}
          onClick={handleToggle}
          // teal-deep = our "confirmed / good" hue. (amber is reserved for
          // alarm/attention — never a calm publishing opt-in.)
          className={`relative inline-flex h-7 w-12 shrink-0 items-center rounded-full border-2 transition-colors disabled:opacity-60 ${
            checked ? "border-teal-deep bg-teal-deep" : "border-charcoal/30 bg-charcoal/10"
          }`}
        >
          <span
            className={`inline-block h-5 w-5 transform rounded-full bg-paper shadow transition-transform ${
              checked ? "translate-x-5" : "translate-x-0.5"
            }`}
          />
        </button>
      </div>
      {/* Save feedback — polite live region so the change is always confirmed. */}
      <div aria-live="polite" className="mt-2 min-h-[1.25rem] text-sm">
        {state === "saving" && <span className="text-charcoal-muted">Saving…</span>}
        {state === "saved" && <span className="text-teal-deep">Saved.</span>}
        {state === "error" && (
          <span role="alert" className="text-amber-deep">
            Couldn&rsquo;t save that just now. Please try again.
          </span>
        )}
      </div>
    </div>
  );
}
