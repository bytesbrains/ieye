import { test, expect } from "@playwright/test";
import { signInToAccount, uniqueUser } from "./helpers";
import { findUidByEmail, seedContribution } from "./seed";

// "Full contribution flow" — minus Stripe's external hosted checkout, which
// can't be driven in-emulator. We pick up exactly where Stripe hands back: the
// webhook (functions/src/stripe.ts) writes a `contributions` row, and the
// signed-in account reflects it LIVE (useMyContributions is an onSnapshot). So we
// seed the same row the webhook would and assert the account screen updates.
//
// Reflection is data-driven, NOT flag-gated: a recorded contribution always
// shows in the owner's history. (The ABILITY to start a contribution IS flag-
// gated — covered in fiat.spec.ts / landing.spec.ts.)
test("a recorded fiat contribution reflects live in the account history", async ({ page }) => {
  const user = uniqueUser("contrib");
  await signInToAccount(page, user);

  // Before the webhook writes: the honest empty state.
  await expect(page.getByText(/no contributions yet/i)).toBeVisible();

  // The webhook would record a contribution owned by this user.
  const uid = await findUidByEmail(user.email);
  await seedContribution(uid, { amountMinor: "2500", currency: "SGD", status: "paid" });

  // The live subscription updates without a reload: empty state gone, the fiat
  // amount + status shown (formatFiatMinor renders S$25.00 / $25.00 per locale).
  await expect(page.getByText(/no contributions yet/i)).toHaveCount(0);
  await expect(page.getByText(/25\.00/)).toBeVisible();
  await expect(page.getByText("paid")).toBeVisible();
});
