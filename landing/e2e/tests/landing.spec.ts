import { test, expect } from "@playwright/test";

// Public landing — every section renders with its real, honest copy. No auth.
test.describe("public landing page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("hero leads with the promise, not the floor", async ({ page }) => {
    await expect(page.getByRole("heading", { name: "iEye gets help to you in time." })).toBeVisible();
    await expect(page.getByText("You will not go unseen.")).toBeVisible();
    await expect(page.getByRole("link", { name: /see how it works/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /ways to contribute/i })).toBeVisible();
  });

  test("header nav exposes the four sections + sign in", async ({ page }) => {
    const nav = page.getByRole("navigation", { name: "Primary" });
    for (const label of ["How it works", "Trust & privacy", "Ways to help", "Transparency"]) {
      await expect(nav.getByRole("link", { name: label })).toBeVisible();
    }
    await expect(page.getByRole("link", { name: /^sign in$/i })).toBeVisible();
  });

  test("the gap section frames the real danger", async ({ page }) => {
    await expect(
      page.getByRole("heading", { name: /Living alone isn.t the danger/i })
    ).toBeVisible();
  });

  test("how it works shows both speeds and the capability claim", async ({ page }) => {
    await expect(page.getByRole("heading", { name: /You don.t have to do anything/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: /When seconds matter/i })).toBeVisible();
    await expect(page.getByRole("heading", { name: /When no one would have noticed/i })).toBeVisible();
    await expect(page.getByText(/This is the speed that can save a life/i)).toBeVisible();
  });

  test("trust section states watch-over-not-watch-you", async ({ page }) => {
    const trust = page.locator("#trust");
    await expect(trust.getByRole("heading")).toContainText("We watch");
    await expect(trust.getByRole("heading")).toContainText("never watch");
  });

  test("roadmap: four tiers, honest state pills, why-funds, honesty line", async ({ page }) => {
    const roadmap = page.locator("#roadmap");
    await expect(roadmap.getByRole("heading", { name: "More senses. Never more surveillance." })).toBeVisible();
    await expect(roadmap.getByText("Where iEye is going")).toBeVisible();

    for (const tier of [
      "The phone in your pocket",
      "Quiet helpers around the home",
      "The helper on your wrist",
      "A purpose-built guardian",
    ]) {
      await expect(roadmap.getByRole("heading", { name: tier })).toBeVisible();
    }
    // State carried in TEXT, not colour alone.
    await expect(roadmap.getByText("Here today")).toBeVisible();
    await expect(roadmap.getByText("Next").first()).toBeVisible();
    await expect(roadmap.getByText("Later")).toBeVisible();

    // The "why it costs money" band + honest capability claim.
    await expect(roadmap.getByText("Why it costs money")).toBeVisible();
    await expect(roadmap.getByText("Hardware buys signal")).toBeVisible();
    await expect(roadmap.getByText(/not a substitute for emergency services/i)).toBeVisible();

    // Brand guardrail: no surveillance verbs leak into the roadmap copy.
    await expect(roadmap).not.toContainText(/\bsurveil\b/i);
  });

  test("contribute: waitlist, skills, and (default) funder-interest panel", async ({ page }) => {
    const contribute = page.locator("#contribute");
    await expect(contribute.getByRole("heading", { name: /Want it for someone you love/i })).toBeVisible();
    await expect(contribute.getByRole("button", { name: /continue with google/i })).toBeVisible();
    await expect(contribute.getByRole("heading", { name: /Help build iEye/i })).toBeVisible();

    // Flag OFF (default build): interest capture, never a live "donate".
    await expect(contribute.getByText("Help us build the senses.")).toBeVisible();
    await expect(contribute.getByRole("link", { name: /register funder interest/i })).toBeVisible();
    await expect(contribute.getByText(/Contributing money isn.t open yet/i)).toBeVisible();
    await expect(contribute.getByText(/not tax-deductible/i)).toBeVisible();
    // No loud donate CTA on the public page.
    await expect(contribute.getByRole("button", { name: /^donate$/i })).toHaveCount(0);
  });

  test("supporter wall is honestly 'coming soon'", async ({ page }) => {
    await expect(page.locator("#transparency").getByText(/supporter wall is coming soon/i)).toBeVisible();
  });

  test("footer links to legal pages and section anchors", async ({ page }) => {
    const footer = page.getByRole("contentinfo");
    await expect(footer.getByRole("link", { name: "Privacy", exact: true })).toHaveAttribute("href", "/privacy");
    await expect(footer.getByRole("link", { name: "Terms", exact: true })).toHaveAttribute("href", "/terms");
  });

  test("skip link is reachable for keyboard users", async ({ page }) => {
    await page.keyboard.press("Tab");
    await expect(page.getByRole("link", { name: /skip to content/i })).toBeFocused();
  });
});
