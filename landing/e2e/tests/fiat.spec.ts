import { test, expect } from "@playwright/test";
import { signInToAccount, uniqueUser } from "./helpers";

// Runs against the flag-ON dev server (project "fiat", VITE_FIAT_CONTRIB_ENABLED
// =true). We verify the UI flips to the live contribute path. We do NOT complete
// a Stripe checkout — that's an external redirect and isn't end-to-end-able here;
// the backend gate (functions/src/stripe.ts) is the real boundary.
test.describe("fiat contributions (flag ON)", () => {
  test("landing money panel becomes a live 'contribute by card' CTA", async ({ page }) => {
    await page.goto("/");
    const contribute = page.locator("#contribute");
    await expect(contribute.getByText("Help keep iEye running.")).toBeVisible();
    await expect(contribute.getByRole("link", { name: /contribute by card/i })).toBeVisible();
    // The funder-interest (flag-OFF) copy is gone in this state.
    await expect(contribute.getByText("Help us build the senses.")).toHaveCount(0);
  });

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
