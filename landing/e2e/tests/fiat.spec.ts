import { test, expect } from "@playwright/test";
import { signInToAccount, uniqueUser } from "./helpers";

// Runs against the flag-ON dev server (project "fiat", VITE_FIAT_CONTRIB_ENABLED
// =true). We verify the UI flips to the live contribute path. We do NOT complete
// a Stripe checkout — that's an external redirect and isn't end-to-end-able here;
// the backend gate (functions/src/stripe.ts) is the real boundary.
test.describe("fiat contributions (flag ON)", () => {
  // NOTE: the landing money panel was retired with the donation model (the public
  // page no longer surfaces contributions). The /account contribution flow and its
  // backend remain for now — covered below — pending a separate cleanup.
  test("account shows the amount picker + full point-of-payment disclaimer", async ({ page }) => {
    await signInToAccount(page, uniqueUser("fiat"));

    await expect(page.getByRole("heading", { name: /make a contribution/i })).toBeVisible();
    // Amount controls present (locale-tolerant: at least the custom field + presets).
    await expect(page.getByText(/choose an amount/i)).toBeVisible();
    await expect(page.getByLabel(/enter an amount/i)).toBeVisible();
    // Full counsel-approved disclaimer at the point of payment (#38).
    await expect(page.getByText(/not a tax-deductible charitable donation/i)).toBeVisible();
    // A contribute button exists and is actionable (we stop short of Stripe).
    await expect(page.getByRole("button", { name: /^contribute/i })).toBeEnabled();
  });
});
