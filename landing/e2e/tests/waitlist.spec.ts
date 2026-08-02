import { test, expect } from "@playwright/test";
import { completeEmulatorGoogleSignIn, uniqueUser } from "./helpers";

// The getRedirectResult-vs-auth-state race this used to expose is now fixed in
// the app (lib/waitlist.ts falls back to the resolved auth state when
// getRedirectResult races to null), so this passes first-attempt. One retry
// stays as ordinary belt-and-suspenders for a redirect round-trip e2e.
test.describe.configure({ retries: 1 });

// The "Continue with Google" early-access waitlist flow now lives on the /app
// hub: sign in via the Auth emulator and land on the confirmation. Exercises
// signInWithRedirect end-to-end.
test("waitlist sign-in confirms 'you're on the list'", async ({ page }) => {
  const user = uniqueUser("waitlist");
  await page.goto("/app");

  const card = page.locator("#waitlist");
  await card.getByRole("button", { name: /continue with google/i }).click();

  await completeEmulatorGoogleSignIn(page, user);

  // Back on the landing; the CTA finishes the write and confirms.
  await expect(page.getByText(/you.re on the list/i)).toBeVisible({ timeout: 20_000 });
});
