import { defineConfig, devices } from "@playwright/test";

// E2E config for the landing app, run against the DOCKERIZED Firebase emulator
// (start it first: `npm run e2e:up`). Two dev servers are started so we can
// exercise both states of the build-time fiat flag:
//   - port 5173, flag OFF  -> the default "funder interest" money panel
//   - port 5174, flag ON   -> the live "contribute by card" path
// Both talk to the same emulator. global-setup.ts waits for the emulator and
// clears its data so each run starts clean.

const EMULATOR_ENV = {
  VITE_USE_EMULATOR: "true",
  VITE_FIREBASE_PROJECT_ID: "demo-ieye",
  VITE_FIREBASE_API_KEY: "demo-api-key",
  VITE_FIREBASE_AUTH_DOMAIN: "demo-ieye.firebaseapp.com",
  VITE_EMULATOR_AUTH_URL: "http://127.0.0.1:9099",
  VITE_EMULATOR_FIRESTORE_HOST: "127.0.0.1",
  VITE_EMULATOR_FIRESTORE_PORT: "8080",
};

export default defineConfig({
  testDir: "./e2e/tests",
  globalSetup: "./e2e/global-setup.ts",
  fullyParallel: false, // shared emulator state — keep specs sequential
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: [["list"], ["html", { open: "never" }]],
  timeout: 30_000,
  expect: { timeout: 10_000 },
  use: {
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    // Watchable runs: `--headed` shows the browser; E2E_SLOWMO=350 paces actions
    // so they're visible. Both no-op in normal/CI runs.
    launchOptions: { slowMo: process.env.E2E_SLOWMO ? Number(process.env.E2E_SLOWMO) : 0 },
  },
  webServer: [
    {
      command: "npm run dev -- --host 127.0.0.1 --port 5173 --strictPort",
      url: "http://127.0.0.1:5173",
      reuseExistingServer: !process.env.CI,
      timeout: 120_000,
      env: EMULATOR_ENV,
    },
    {
      command: "npm run dev -- --host 127.0.0.1 --port 5174 --strictPort",
      url: "http://127.0.0.1:5174",
      reuseExistingServer: !process.env.CI,
      timeout: 120_000,
      env: { ...EMULATOR_ENV, VITE_FIAT_CONTRIB_ENABLED: "true" },
    },
  ],
  projects: [
    {
      name: "landing",
      use: { ...devices["Desktop Chrome"], baseURL: "http://127.0.0.1:5173" },
      testIgnore: /fiat\.spec\.ts/,
    },
    {
      name: "fiat",
      use: { ...devices["Desktop Chrome"], baseURL: "http://127.0.0.1:5174" },
      testMatch: /fiat\.spec\.ts/,
    },
  ],
});
