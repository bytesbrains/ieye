// Client wrapper for the fiat-contribution callable (functions/src/stripe.ts).
//
// This only INVOKES the function; all the real enforcement (gate is open, user
// is signed in, amount is valid) happens server-side — a client cannot bypass it.
// On success Stripe returns a hosted Checkout URL and we hand the browser over to
// it; card details never touch our frontend (PCI surface stays minimal).

import { httpsCallable } from "firebase/functions";
import { functions } from "./firebase";

interface CheckoutResult {
  url: string | null;
}

/**
 * Start a contribution checkout for `amountMinor` (cents). Redirects the browser
 * to Stripe Checkout on success. Throws on failure — callers map the error to a
 * calm sentence with {@link contributeMoneyError}.
 */
export async function startContributionCheckout(amountMinor: number): Promise<void> {
  const fn = httpsCallable<{ amountMinor: number }, CheckoutResult>(
    functions,
    "createContributionCheckout"
  );
  const res = await fn({ amountMinor });
  const url = res.data?.url;
  if (!url) throw new Error("No checkout URL returned");
  window.location.assign(url);
}

/** Turn a Functions/HttpsError into a calm, human sentence for the UI. */
export function contributeMoneyError(err: unknown): string {
  const code = (err as { code?: string })?.code ?? "";
  if (code === "functions/failed-precondition") return "Contributions aren’t open yet.";
  if (code === "functions/unauthenticated") return "Please sign in to contribute.";
  if (code === "functions/invalid-argument") return "Please choose a valid amount.";
  return "That didn’t go through. Please try again in a moment.";
}
