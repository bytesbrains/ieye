#!/usr/bin/env node
// grant-admin.mjs — LOCAL EMULATOR ONLY.
//
// Mints the `admin` custom claim on a user in the **Auth emulator**, so you can
// view /admin during development. This is the local stand-in for the
// production path, where the claim is minted ONLY by a secured backend / Admin
// SDK (THREAT-MODEL §4). There is deliberately NO client UI that mints claims.
//
// Usage:
//   1. Start emulators:           npm run emulators
//   2. Sign in once via the app (http://localhost:5173/signin) with Google —
//      the Auth emulator creates a local user for you.
//   3. Grant yourself admin:      npm run grant-admin -- you@example.com
//   4. Sign out + back in (or reload) so the new token carries the claim.
//
// The Auth emulator exposes an unauthenticated admin REST API on its host. We
// talk to it directly — no service-account credentials needed locally.

const AUTH_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
const PROJECT = process.env.GCLOUD_PROJECT || "demo-ieye";
const BASE = `http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1`;
// The emulator accepts any non-empty key for the API key query param.
const KEY = "owner";

const email = process.argv[2];
if (!email) {
  console.error("Usage: npm run grant-admin -- <email-of-a-signed-in-emulator-user>");
  process.exit(1);
}

async function main() {
  // 1. Look the user up by email to get their localId (uid).
  const lookupRes = await fetch(`${BASE}/projects/${PROJECT}/accounts:lookup?key=${KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: "Bearer owner" },
    body: JSON.stringify({ email: [email] }),
  });
  const lookup = await lookupRes.json();
  const user = lookup.users && lookup.users[0];
  if (!user) {
    console.error(
      `No emulator user found for ${email}. Sign in once via the app first, then re-run.`
    );
    process.exit(1);
  }

  // 2. Set the custom claim { admin: true } on that user.
  const updateRes = await fetch(`${BASE}/projects/${PROJECT}/accounts:update?key=${KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: "Bearer owner" },
    body: JSON.stringify({
      localId: user.localId,
      customAttributes: JSON.stringify({ admin: true }),
    }),
  });
  if (!updateRes.ok) {
    console.error("Failed to set claim:", await updateRes.text());
    process.exit(1);
  }

  console.log(`✅ Granted admin to ${email} (uid ${user.localId}).`);
  console.log("   Sign out and back in (or reload) so the new ID token carries the claim.");
}

main().catch((err) => {
  console.error(
    "Could not reach the Auth emulator. Is `npm run emulators` running?\n",
    err.message
  );
  process.exit(1);
});
