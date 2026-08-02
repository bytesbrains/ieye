import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

// Accessibility scan of the key public pages. Asserts no SERIOUS or CRITICAL
// WCAG 2.0/2.1 A/AA violations (the levels that actually block users) — contrast,
// labels, roles, names. Minor/moderate findings are reported by the tool but not
// failed here, to keep the gate meaningful rather than noisy.
const PAGES = ["/", "/app", "/privacy", "/terms"];

for (const path of PAGES) {
  test(`a11y: ${path} has no serious or critical violations`, async ({ page }) => {
    await page.goto(path);
    await page.locator("h1, h2").first().waitFor();

    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
      .analyze();

    const blocking = results.violations.filter(
      (v) => v.impact === "serious" || v.impact === "critical"
    );
    const summary = blocking.map((v) => ({ id: v.id, impact: v.impact, nodes: v.nodes.length }));
    expect(blocking, `serious/critical a11y violations on ${path}: ${JSON.stringify(summary, null, 2)}`).toEqual([]);
  });
}
