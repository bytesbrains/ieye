import { type Page, expect } from "@playwright/test";

export interface TestUser {
  email: string;
  name: string;
}

// Unique per call so tests don't collide on the shared emulator.
export function uniqueUser(prefix = "user"): TestUser {
  const tag = `${prefix}-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;
  return { email: `${tag}@example.com`, name: `Test ${prefix} ${String(Date.now()).slice(-4)}` };
}

/**
 * Drives the Firebase Auth emulator's Google sign-in widget that
 * signInWithRedirect lands on. The CALLER must already have triggered the
 * redirect (clicked a "Continue with Google" button). Resolves once the browser
 * is back on the app (off the :9099 emulator origin).
 *
 * Widget DOM (firebase-tools 13.x): #email-input, #display-name-input, the
 * "Add new account" button when the form is collapsed, and #sign-in to submit.
 */
export async function completeEmulatorGoogleSignIn(page: Page, user: TestUser): Promise<void> {
  await page.waitForURL(/127\.0\.0\.1:9099\/emulator\/auth\/handler/, { timeout: 20_000 });

  const email = page.locator("#email-input");
  if (!(await email.isVisible().catch(() => false))) {
    await page.getByRole("button", { name: /add new account/i }).click();
  }
  await expect(email).toBeVisible();
  await email.fill(user.email);
  await page.locator("#display-name-input").fill(user.name);
  await page.locator("#sign-in").click();

  // Back on the app (any origin that isn't the auth emulator).
  await page.waitForURL((url) => !url.host.includes("9099"), { timeout: 20_000 });
}

/** Sign in through the /signin page and land on /account. */
export async function signInToAccount(page: Page, user: TestUser): Promise<void> {
  await page.goto("/account"); // RequireAuth bounces unauth users to /signin
  await page.waitForURL(/\/signin/, { timeout: 15_000 });
  await page.getByRole("button", { name: /continue with google/i }).click();
  await completeEmulatorGoogleSignIn(page, user);
  await page.waitForURL(/\/account/, { timeout: 20_000 });
  await expect(page.getByRole("heading", { name: /your account/i })).toBeVisible();
}

/** Sign out via the authenticated-app header; lands back on the public home. */
export async function signOut(page: Page): Promise<void> {
  await page.getByRole("button", { name: /sign out/i }).click();
  await page.waitForURL((url) => url.pathname === "/", { timeout: 15_000 });
}
