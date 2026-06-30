import { test, expect } from "@playwright/test";
import { signInToAccount, signOut, uniqueUser } from "./helpers";
import { findUidByEmail, mintCustomClaim, seedContributorRequest, clearCollection } from "./seed";

// Admin is gated by the `admin` custom CLAIM (never a Firestore field). We mint
// the claim in the emulator, then re-sign-in so the fresh ID token carries it
// (the same way a real admin picks up a newly-granted claim on next sign-in),
// and exercise the contributor-request vetting queue. The status advance is a
// client write that only succeeds because the token now holds the claim — i.e.
// it also proves the rules gate.
test.describe("admin", () => {
  // Start from a clean queue — other specs (e.g. the contributor-request flow)
  // create requests that would otherwise linger into this admin view.
  test.beforeEach(async () => {
    await clearCollection("contributorRequests");
  });
  test.afterEach(async () => {
    await clearCollection("contributorRequests");
  });

  test("an admin sees the contributor queue and can advance a request", async ({ page }) => {
    // A request awaiting vetting.
    await seedContributorRequest("requester-uid-1", { skills: "Flutter & Hindi" });

    // Sign in, become admin, re-auth for a token that carries the claim.
    const admin = uniqueUser("admin");
    await signInToAccount(page, admin);
    const uid = await findUidByEmail(admin.email);
    await mintCustomClaim(uid, { admin: true });

    await signOut(page);
    await signInToAccount(page, admin); // same account; new token now has admin:true

    // The admin nav + shell are now available.
    await expect(page.getByRole("link", { name: "Admin", exact: true })).toBeVisible();
    await page.goto("/admin");
    await expect(page.getByRole("heading", { name: "Admin", exact: true })).toBeVisible();

    // The queue shows the seeded request, awaiting vetting. Scope to its row so
    // the assertion is robust to any other requests in the queue.
    const row = page.getByRole("listitem").filter({ hasText: "Flutter & Hindi" });
    await expect(row).toBeVisible();
    const advance = row.getByRole("button", { name: /advance to vetted/i });
    await expect(advance).toBeVisible();

    // Vet it — the write succeeds under the rules (admin claim) and the next
    // action becomes "Advance to invited".
    await advance.click();
    await expect(row.getByRole("button", { name: /advance to invited/i })).toBeVisible({
      timeout: 15_000,
    });
  });
});
