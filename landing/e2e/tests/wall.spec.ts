import { test, expect } from "@playwright/test";
import { seedDoc, seedManyPublicSupporters, seedPublicSupporter, clearCollection } from "./seed";

// Mirrors PAGE_SIZE in SupporterWall.tsx — the page size for query + view.
const PAGE = 60;

// The public supporter wall (#transparency) reads the live publicSupporters
// projection. "yes/no" here is the CONSENT gate, enforced by architecture: only
// opted-in names are ever projected into publicSupporters, so only they appear —
// and the projection carries no amount/email, so the wall can never show one.
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

  test("seeded opt-in supporters appear by name", async ({ page }) => {
    await seedPublicSupporter("Asha N.");
    await seedPublicSupporter("Ravi Kumar");
    await seedPublicSupporter("BytesBrains");

    await page.goto("/");
    const wall = page.locator("#transparency");

    await expect(wall.getByText("Asha N.")).toBeVisible();
    await expect(wall.getByText("Ravi Kumar")).toBeVisible();
    await expect(wall.getByText("BytesBrains")).toBeVisible();
    await expect(wall.getByText(/supporter wall is coming soon/i)).toHaveCount(0);
  });

  test("PRIVACY: only the display name is visible — never email or amount", async ({ page }) => {
    // Even if a row somehow carried private fields, the wall must not render them.
    await seedDoc("publicSupporters", {
      displayName: "Mallory Private",
      email: "mallory@secret.example",
      amountMinor: "999999",
    });

    await page.goto("/");
    const wall = page.locator("#transparency");

    await expect(wall.getByText("Mallory Private")).toBeVisible();
    // No email — neither the address nor any "@" text anywhere on the wall.
    await expect(wall).not.toContainText("mallory@secret.example");
    await expect(wall.getByText(/@/)).toHaveCount(0);
    // No amount — neither the raw minor units nor a currency figure.
    await expect(wall).not.toContainText("999999");
    await expect(wall.getByText(/\$\s?\d/)).toHaveCount(0);
  });

  test("SCALE: paginates hundreds of supporters in query and view", async ({ page }) => {
    await seedManyPublicSupporters(130); // "Supporter 0001".."Supporter 0130"

    await page.goto("/");
    const items = page.locator('#transparency ul[aria-label="Supporters"] > li');
    const showMore = page.getByRole("button", { name: /show more supporters/i });

    // First page only — the query is bounded, the view shows PAGE, not all 130.
    await expect(items).toHaveCount(PAGE);
    await expect(page.locator("#transparency").getByText("Supporter 0130")).toHaveCount(0);
    await expect(showMore).toBeVisible();

    // Page 2.
    await showMore.click();
    await expect(items).toHaveCount(PAGE * 2);
    await expect(showMore).toBeVisible();

    // Page 3 (final, 10 left) — last page, control disappears.
    await showMore.click();
    await expect(items).toHaveCount(130);
    await expect(page.locator("#transparency").getByText("Supporter 0130")).toBeVisible();
    await expect(showMore).toHaveCount(0);
  });
});
