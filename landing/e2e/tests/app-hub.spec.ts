import { test, expect } from "@playwright/test";

// The /app hub — the outside-in browser teaser + install links. The teaser calls
// /api/exposure (a Cloud Function in prod); here we mock it to exercise each
// honest UI state without needing the function running.
test.describe("/app hub — outside-in exposure teaser", () => {
  test("exposed result lists what's visible from the internet + points inside", async ({ page }) => {
    await page.route("**/api/exposure", (route) =>
      route.fulfill({
        contentType: "application/json",
        body: JSON.stringify({
          status: "exposed",
          ip: "203.0.113.7",
          ports: [554, 80],
          vulns: ["CVE-2021-0001"],
        }),
      })
    );
    await page.goto("/app");
    await page.getByRole("button", { name: /check my exposure/i }).click();

    await expect(page.getByText(/Visible from the internet on your connection/i)).toBeVisible();
    await expect(page.getByText(/camera stream \(RTSP\)/i)).toBeVisible();
    await expect(page.getByText(/known vulnerabilit/i)).toBeVisible();
    // Honest: the real check is inside — the browser can't do that.
    await expect(page.getByText(/install the app below and run the full/i)).toBeVisible();
  });

  test("clean result is honest — 'nothing found' is NOT 'you're safe'", async ({ page }) => {
    await page.route("**/api/exposure", (route) =>
      route.fulfill({
        contentType: "application/json",
        body: JSON.stringify({ status: "clean", ip: "203.0.113.7" }),
      })
    );
    await page.goto("/app");
    await page.getByRole("button", { name: /check my exposure/i }).click();

    await expect(page.getByText(/Nothing showed up for your connection/i)).toBeVisible();
    await expect(page.getByText(/never appear in a scan like this/i)).toBeVisible();
  });

  test("a failed / non-JSON check degrades gracefully", async ({ page }) => {
    await page.route("**/api/exposure", (route) =>
      route.fulfill({ status: 500, contentType: "text/plain", body: "boom" })
    );
    await page.goto("/app");
    await page.getByRole("button", { name: /check my exposure/i }).click();

    await expect(page.getByText(/Couldn.t run the check right now/i)).toBeVisible();
  });

  test("install: Win/Linux/Android download; macOS/iPhone honestly 'Available soon'", async ({ page }) => {
    await page.goto("/app");
    const install = page.locator("#install");
    await expect(install.getByRole("heading", { name: /run the scan/i })).toBeVisible();
    // Available-now downloads link to GitHub Releases.
    const dl = install.getByRole("link", { name: /^download$/i }).first();
    await expect(dl).toHaveAttribute("href", "https://github.com/bytesbrains/ieye/releases");
    await expect(dl).toHaveAttribute("target", "_blank");
    // Apple platforms are honestly not downloadable yet.
    await expect(install.getByText("macOS")).toBeVisible();
    await expect(install.getByText(/available soon/i).first()).toBeVisible();
    // The "use an old device you already own" nudge.
    await expect(install.getByText(/old Windows or Linux laptop/i)).toBeVisible();
  });
});
