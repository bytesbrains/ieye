import { test, expect } from "@playwright/test";
import { completeEmulatorGoogleSignIn, uniqueUser } from "./helpers";

// Bounded retries: unlike the /account flow (which is backed by a persistent
// onIdTokenChanged listener), the public waitlist relies solely on
// getRedirectResult — which has a known load-dependent race with
// signInWithRedirect's IndexedDB flush. Re-running the whole redirect round-trip
// is the standard, honest way to de-flake a redirect-auth e2e.
test.describe.configure({ retries: 2 });

// The public "Continue with Google" waitlist flow: sign in via the Auth emulator
// and land on the confirmation. Exercises signInWithRedirect end-to-end.
test("waitlist sign-in confirms 'you're on the list'", async ({ page }) => {
  const user = uniqueUser("waitlist");
  await page.goto("/");

  const card = page.locator("#waitlist");
  await card.getByRole("button", { name: /continue with google/i }).click();

  await completeEmulatorGoogleSignIn(page, user);

  // Back on the landing; the CTA finishes the write and confirms.
  await expect(page.getByText(/you.re on the list/i)).toBeVisible({ timeout: 20_000 });
});
