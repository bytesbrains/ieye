import { test, expect } from "@playwright/test";
import { signInToAccount, uniqueUser, type TestUser } from "./helpers";

// Signed-in account flows. Each test signs in a fresh emulator user, so state is
// isolated. These write to the user's OWN users/{uid} doc + contributorRequests
// — exactly what the rules allow.
test.describe("account (signed in)", () => {
  let user: TestUser;

  test.beforeEach(async ({ page }) => {
    user = uniqueUser("acct");
    await signInToAccount(page, user);
  });

  test("profile is seeded from the Google identity", async ({ page }) => {
    const profile = page.getByRole("region").filter({ hasText: "Profile" }).first();
    await expect(page.getByText(user.email)).toBeVisible();
    await expect(page.getByText(user.name)).toBeVisible();
  });

  test("opt-in to be named persists (request to publish)", async ({ page }) => {
    const toggle = page.getByRole("switch", { name: /request to show my name/i });
    await expect(toggle).toHaveAttribute("aria-checked", "false");
    await toggle.click();
    await expect(toggle).toHaveAttribute("aria-checked", "true");
    await expect(page.getByText("Saved.").first()).toBeVisible();
  });

  test("funder-interest can be registered", async ({ page }) => {
    const toggle = page.getByRole("switch", { name: /register my interest in helping fund/i });
    await expect(toggle).toHaveAttribute("aria-checked", "false");
    await toggle.click();
    await expect(toggle).toHaveAttribute("aria-checked", "true");
    await expect(page.getByText("Saved.").first()).toBeVisible();
  });

  test("contributor request submits and shows status", async ({ page }) => {
    await page.getByLabel(/what can you help with/i).fill("Flutter, Hindi translation");
    await page.getByRole("button", { name: /ask to help build iEye/i }).click();
    // The live subscription swaps the form for the status view.
    await expect(page.getByText(/Received — we.ll review it/i)).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText("requested")).toBeVisible();
  });
});
