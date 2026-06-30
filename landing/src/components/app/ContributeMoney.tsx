// Fiat contribution UI (signed-in). Behind the FIAT_CONTRIB_ENABLED flag — its
// only caller (Account) renders it only when the flag is on; the backend gate
// (#39) is the real boundary.
//
// Flow: pick an amount -> createContributionCheckout callable -> redirect to
// Stripe's hosted Checkout. Card details never touch this page. The FULL,
// counsel-approved disclaimer (LEGAL.contributionDisclaimerFull) renders at the
// point of payment — "contribution, not donation", #38.

import { useState } from "react";
import { startContributionCheckout, contributeMoneyError } from "../../lib/contributeMoney";
import { LEGAL } from "../../lib/legalCopy";

// Presets in MINOR units (cents). SGD — BytesBrains is a Singapore entity (#38).
const PRESETS_MINOR = [1000, 2500, 5000, 10000];
const MIN_MINOR = 100; //   S$1
const MAX_MINOR = 1_000_000; // S$10,000 — matches the server-side bound.

function formatPreset(minor: number): string {
  return new Intl.NumberFormat("en-SG", {
    style: "currency",
    currency: "SGD",
    maximumFractionDigits: 0,
  }).format(minor / 100);
}

export function ContributeMoney() {
  const [selected, setSelected] = useState<number>(PRESETS_MINOR[1]);
  const [custom, setCustom] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Custom amount (in dollars) wins when present and valid.
  const customMinor = custom.trim() === "" ? null : Math.round(Number(custom) * 100);
  const amountMinor = customMinor ?? selected;
  const amountValid =
    Number.isInteger(amountMinor) && amountMinor >= MIN_MINOR && amountMinor <= MAX_MINOR;

  async function handleContribute() {
    if (!amountValid || busy) return;
    setBusy(true);
    setError(null);
    try {
      await startContributionCheckout(amountMinor); // navigates away to Stripe
    } catch (err) {
      setError(contributeMoneyError(err));
      setBusy(false);
    }
  }

  return (
    <div>
      <p className="max-w-prose text-base text-charcoal-soft">
        A one-time contribution by card, in Singapore dollars. You&rsquo;ll be taken to a secure
        Stripe page to pay — your card details never touch iEye.
      </p>

      {/* Preset amounts */}
      <fieldset className="mt-5">
        <legend className="text-sm font-semibold text-charcoal-muted">Choose an amount</legend>
        <div className="mt-3 flex flex-wrap gap-3">
          {PRESETS_MINOR.map((minor) => {
            const active = customMinor === null && selected === minor;
            return (
              <button
                key={minor}
                type="button"
                aria-pressed={active}
                onClick={() => {
                  setSelected(minor);
                  setCustom("");
                }}
                className={`rounded-xl border-2 px-5 py-2.5 text-base font-semibold transition-colors ${
                  active
                    ? "border-teal-deep bg-teal-deep text-paper"
                    : "border-charcoal/20 bg-paper text-charcoal hover:border-charcoal/40"
                }`}
              >
                {formatPreset(minor)}
              </button>
            );
          })}
        </div>
      </fieldset>

      {/* Custom amount */}
      <div className="mt-4 max-w-xs">
        <label htmlFor="customAmount" className="field-label">
          Or enter an amount (S$)
        </label>
        <input
          id="customAmount"
          type="number"
          inputMode="decimal"
          min="1"
          max="10000"
          step="1"
          className="field-input"
          placeholder="e.g. 75"
          value={custom}
          onChange={(e) => setCustom(e.target.value)}
        />
        {custom.trim() !== "" && !amountValid && (
          <p className="field-error mt-2">Enter an amount between S$1 and S$10,000.</p>
        )}
      </div>

      {/* Point-of-payment disclaimer — full counsel-approved wording (#38). */}
      <p className="mt-6 max-w-prose text-sm text-charcoal-muted">{LEGAL.contributionDisclaimerFull}</p>

      {error && (
        <p role="alert" className="field-error mt-4">
          {error}
        </p>
      )}

      <button
        type="button"
        onClick={handleContribute}
        disabled={!amountValid || busy}
        className="btn btn-primary mt-5 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {busy
          ? "Taking you to Stripe…"
          : amountValid
            ? `Contribute ${new Intl.NumberFormat("en-SG", { style: "currency", currency: "SGD" }).format(amountMinor / 100)}`
            : "Contribute"}
      </button>
    </div>
  );
}
