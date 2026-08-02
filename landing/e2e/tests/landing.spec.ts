import { test, expect } from "@playwright/test";

// Public landing — repositioned to lead with iEye Secure (home security), with
// iEye Watch (welfare) as the deeper why and BytesBrains as the sponsoring
// company. No auth. The old donation/supporter-wall model has been retired.
test.describe("public landing page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("hero leads with the dual-guardian promise + a scan CTA", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /A guardian for your home/i })
    ).toBeVisible();
    await expect(page.getByText(/You will not go unseen/i)).toBeVisible();
    await expect(
      page.locator("#top").getByRole("link", { name: /scan your home/i })
    ).toBeVisible();
  });

  test("header nav exposes the new sections + sign in + scan CTA", async ({ page }) => {
    const nav = page.getByRole("navigation", { name: "Primary" });
    for (const label of ["iEye Secure", "How it works", "Trust & privacy", "BytesBrains"]) {
      await expect(nav.getByRole("link", { name: label })).toBeVisible();
    }
    await expect(page.getByRole("link", { name: /^sign in$/i })).toBeVisible();
    await expect(nav.getByRole("link", { name: /scan your home/i })).toHaveAttribute("href", "/app");
  });

  test("iEye Secure section leads with the home-security scan", async ({ page }) => {
    const secure = page.locator("#secure");
    await expect(
      secure.getByRole("heading", { name: /See what a stranger could reach in your home/i })
    ).toBeVisible();
    await expect(secure.getByText(/Finds exposed cameras/i)).toBeVisible();
    await expect(secure.getByText(/Checks your Wi-Fi/i)).toBeVisible();
  });

  test("iEye Watch (how it works) shows both speeds and the capability claim", async ({ page }) => {
    await expect(page.getByText(/iEye Watch — the reason we exist/i)).toBeVisible();
    await expect(page.getByRole("heading", { name: /When seconds matter/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: /When no one would have noticed/i })).toBeVisible();
    await expect(page.getByText(/This is the speed that can save a life/i)).toBeVisible();
  });

  test("trust section states watch-over-not-watch-you", async ({ page }) => {
    const trust = page.locator("#trust");
    await expect(trust.getByRole("heading")).toContainText("We watch");
    await expect(trust.getByRole("heading")).toContainText("never watch");
  });

  test("BytesBrains section funds the mission and gives a contact", async ({ page }) => {
    const bb = page.locator("#bytesbrains");
    await expect(bb.getByRole("heading", { name: /help you secure it/i })).toBeVisible();
    await expect(bb.getByText(/every audit funds the watch-over mission/i)).toBeVisible();
    await expect(bb.getByRole("link", { name: /contact@bytesbrains\.com/i })).toBeVisible();
  });

  test("roadmap: four tiers with honest state pills", async ({ page }) => {
    const roadmap = page.locator("#roadmap");
    await expect(roadmap.getByRole("heading", { name: "More senses. Never less privacy." })).toBeVisible();
    for (const tier of [
      "The phone in your pocket",
      "Quiet helpers around the home",
      "The helper on your wrist",
      "A purpose-built guardian",
    ]) {
      await expect(roadmap.getByRole("heading", { name: tier })).toBeVisible();
    }
    await expect(roadmap.getByText("Here today")).toBeVisible();
    // Brand guardrail: no surveillance vocabulary in the roadmap copy.
    await expect(roadmap).not.toContainText(/surveil|monitor|track you|spy/i);
  });

  test("open-source section points at the public GitHub repo", async ({ page }) => {
    const os = page.locator("#open-source");
    await expect(os.getByRole("heading", { name: /ways to contribute/i })).toBeVisible();
    const ghLink = os.getByRole("link", { name: /view iEye on GitHub/i });
    await expect(ghLink).toHaveAttribute("href", "https://github.com/bytesbrains/ieye");
    await expect(ghLink).toHaveAttribute("target", "_blank");
  });

  test("the reposition dropped the 'not a business' framing", async ({ page }) => {
    // iEye is now sponsored by BytesBrains (a company) — the old public-good /
    // "not a business" donation framing must be gone from the page.
    await expect(page.locator("body")).not.toContainText(/not a business/i);
  });

  test("footer links to legal pages", async ({ page }) => {
    const footer = page.getByRole("contentinfo");
    await expect(footer.getByRole("link", { name: "Privacy", exact: true })).toHaveAttribute("href", "/privacy");
    await expect(footer.getByRole("link", { name: "Terms", exact: true })).toHaveAttribute("href", "/terms");
  });

  test("skip link is reachable for keyboard users", async ({ page }) => {
    await page.keyboard.press("Tab");
    await expect(page.getByRole("link", { name: /skip to content/i })).toBeFocused();
  });
});
