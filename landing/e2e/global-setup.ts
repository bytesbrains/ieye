// Runs once before the e2e suite. Confirms the dockerized Firebase emulator is
// reachable (fail fast with a helpful message if not), then wipes its Auth +
// Firestore data so every run starts from a clean slate.

const PROJECT_ID = "demo-ieye";
const AUTH = "http://127.0.0.1:9099";
const FIRESTORE = "http://127.0.0.1:8080";

async function waitFor(url: string, label: string, timeoutMs = 60_000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  let lastErr: unknown;
  while (Date.now() < deadline) {
    try {
      const res = await fetch(url);
      if (res.ok) return;
    } catch (err) {
      lastErr = err;
    }
    await new Promise((r) => setTimeout(r, 1000));
  }
  throw new Error(
    `Firebase ${label} emulator not reachable at ${url} after ${timeoutMs}ms — is it running? ` +
      `Start it with: npm run e2e:up\n(last error: ${String(lastErr)})`
  );
}

async function clearAuth(): Promise<void> {
  await fetch(`${AUTH}/emulator/v1/projects/${PROJECT_ID}/accounts`, { method: "DELETE" });
}

async function clearFirestore(): Promise<void> {
  await fetch(
    `${FIRESTORE}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
    { method: "DELETE" }
  );
}

export default async function globalSetup(): Promise<void> {
  await waitFor(`${AUTH}/`, "Auth");
  await waitFor(`${FIRESTORE}/`, "Firestore");
  await clearAuth();
  await clearFirestore();
  // eslint-disable-next-line no-console
  console.log("[e2e] emulator ready and cleared.");
}
