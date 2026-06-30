import { test, expect } from "@playwright/test";
import { seedPublicSupporter, clearCollection } from "./seed";

// The public supporter wall (#transparency) reads the live publicSupporters
// projection. "yes/no" here is the CONSENT gate, enforced by architecture: only
// opted-in names are ever projected into publicSupporters, so only they appear —
// and the projection carries no amount, so the wall can never show one.
test.describe("supporter wall (live)", () => {
  test.beforeEach(async () => {
    await clearCollection("publicSupporters");
  });
  test.afterEach(async () => {
    await clearCollection("publicSupporters");
  });

  test("empty -> honest 'coming soon' placeholder", async ({ page }) => {
    await page.goto("/");
    await expect(
      page.locator("#transparency").getByText(/supporter wall is coming soon/i)
    ).toBeVisible();
  });

  test("seeded opt-in supporters appear by name, never with an amount", async ({ page }) => {
    await seedPublicSupporter("Asha N.");
    await seedPublicSupporter("Ravi Kumar");
    await seedPublicSupporter("BytesBrains");

    await page.goto("/");
    const wall = page.locator("#transparency");

    await expect(wall.getByText("Asha N.")).toBeVisible();
    await expect(wall.getByText("Ravi Kumar")).toBeVisible();
    await expect(wall.getByText("BytesBrains")).toBeVisible();

    // The live wall replaces the placeholder...
    await expect(wall.getByText(/supporter wall is coming soon/i)).toHaveCount(0);
    // ...and never shows a per-person amount (named ≠ priced, #36).
    await expect(wall.getByText(/\$\s?\d/)).toHaveCount(0);
  });
});
