import { test, expect } from "@playwright/test";

// Routing + the convenience auth guards (the real boundary is the rules).
test.describe("routing", () => {
  test("/privacy renders the privacy notice", async ({ page }) => {
    await page.goto("/privacy");
    await expect(page.getByRole("heading", { name: /privacy/i }).first()).toBeVisible();
    await expect(page).toHaveURL(/\/privacy$/);
  });

  test("/terms renders the terms", async ({ page }) => {
    await page.goto("/terms");
    await expect(page.getByRole("heading", { name: /terms/i }).first()).toBeVisible();
    await expect(page).toHaveURL(/\/terms$/);
  });

  test("unknown path falls back to the public landing", async ({ page }) => {
    await page.goto("/this-route-does-not-exist");
    await expect(page.getByRole("heading", { name: /A guardian for your home/i })).toBeVisible();
  });

  test("removed account/admin routes fall back to the landing", async ({ page }) => {
    // The signed-in account/admin space was removed with the contribution
    // subsystem; those paths now hit the catch-all and render the landing.
    await page.goto("/account");
    await expect(page.getByRole("heading", { name: /A guardian for your home/i })).toBeVisible();
  });
});
