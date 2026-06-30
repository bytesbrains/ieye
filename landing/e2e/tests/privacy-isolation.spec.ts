import { test, expect } from "@playwright/test";
import { signInToAccount, uniqueUser } from "./helpers";
import { findUidByEmail, seedContribution } from "./seed";

// The sharpest "what's visible vs not" condition: contributions are PRIVATE to
// their owner. The Firestore rules permit reading only where ownerUid == your
// uid, and the query scopes to that — so another person's contribution (amount,
// status, existence) must never surface in your account. We prove it by seeding
// one row for the signed-in user and one for a DIFFERENT uid, then asserting only
// our own is visible.
test("a signed-in user sees ONLY their own contributions, never another's", async ({ page }) => {
  const user = uniqueUser("owner");
  await signInToAccount(page, user);
  const uid = await findUidByEmail(user.email);

  // Mine — should appear.
  await seedContribution(uid, { amountMinor: "2500" }); // S$25.00
  // Someone else's — must NEVER appear in my account.
  await seedContribution("a-different-persons-uid", { amountMinor: "5000000" }); // S$50,000.00

  // Mine reflects live...
  await expect(page.getByText(/25\.00/)).toBeVisible();
  await expect(page.getByText("paid")).toBeVisible();

  // ...and the other person's contribution is nowhere on my account — not the
  // amount, not even a hint. (Rules + query scope it out entirely.)
  await expect(page.getByText(/50,?000\.00/)).toHaveCount(0);
  await expect(page.getByText("5000000")).toHaveCount(0);
});
