import { test, expect } from "@playwright/test";
import { signInToAccount, uniqueUser } from "./helpers";
import { findUidByEmail, seedManyContributions } from "./seed";

// The account's "Your contributions" had the same unbounded pattern the wall did
// (live query with no limit -> reads + renders everything). It's now paginated:
// the live query is capped at the page size and "Show more" grows the window.
const PAGE = 25; // mirrors DEFAULT_PAGE in lib/useContributions.ts

test("contributions history paginates at scale (query + view)", async ({ page }) => {
  const user = uniqueUser("many");
  await signInToAccount(page, user);
  const uid = await findUidByEmail(user.email);

  await seedManyContributions(uid, 30);

  const rows = page.locator('ul[aria-label="Your contributions"] > li');
  const showMore = page.getByRole("button", { name: /show more contributions/i });

  // First page only — bounded query, not all 30.
  await expect(rows).toHaveCount(PAGE);
  await expect(showMore).toBeVisible();

  // Grow the window to the rest.
  await showMore.click();
  await expect(rows).toHaveCount(30);
  await expect(showMore).toHaveCount(0);
});
