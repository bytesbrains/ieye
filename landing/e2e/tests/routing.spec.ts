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
    await expect(page.getByRole("heading", { name: "iEye gets help to you in time." })).toBeVisible();
  });

  test("/account requires sign-in — redirects to /signin", async ({ page }) => {
    await page.goto("/account");
    await expect(page).toHaveURL(/\/signin/);
    await expect(page.getByRole("heading", { name: /sign in to your account/i })).toBeVisible();
    await expect(page.getByRole("button", { name: /continue with google/i })).toBeVisible();
  });

  test("/admin without admin claim does not show the admin shell", async ({ page }) => {
    await page.goto("/admin");
    // Unauthenticated -> bounced to sign-in (a non-admin would land on /account).
    await expect(page).toHaveURL(/\/signin|\/account/);
  });
});
