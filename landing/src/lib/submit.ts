// Single integration seam for Phase-1 forms.
//
// Phase 1 is PUBLIC-ONLY with NO backend (see #42/#43). These functions are
// deliberately stubbed: they validate, simulate a short round-trip, and resolve
// success so the UI can show a real success state. No data leaves the browser.
//
// TODO(#42/#43): wire to Firestore once the BytesBrains Firebase project exists.
//   - submitInterest()  -> collection `waitlist`   { email, source, createdAt }
//   - submitSkills()    -> collection `contributorRequests`
//                          { name, email, skills, note, status: "requested", createdAt }
//   Server logic (validation, rate-limiting, dedupe, notify) belongs in a Cloud
//   Function; Firestore security rules gate writes. Keep this module the ONLY
//   place the rest of the app talks to a backend, so the swap is one file.

export type SubmitResult = { ok: true } | { ok: false; error: string };

export interface InterestPayload {
  email: string;
  /** which form / section the signup came from, for later analytics */
  source: "waitlist";
}

export interface SkillsPayload {
  name: string;
  email: string;
  /** comma-joined selected skill areas */
  skills: string[];
  note: string;
}

const FAKE_LATENCY_MS = 650;

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Register interest in iEye (waitlist / "notify me when this opens").
 * STUB: resolves success without persisting. See module TODO.
 */
export async function submitInterest(payload: InterestPayload): Promise<SubmitResult> {
  await delay(FAKE_LATENCY_MS);
  // TODO(#42/#43): replace with Firestore write via the integration seam above.
  if (import.meta.env.DEV) {
    // eslint-disable-next-line no-console
    console.info("[stub] submitInterest", payload);
  }
  return { ok: true };
}

/**
 * Offer to contribute skills / help build iEye.
 * STUB: resolves success without persisting. See module TODO.
 */
export async function submitSkills(payload: SkillsPayload): Promise<SubmitResult> {
  await delay(FAKE_LATENCY_MS);
  // TODO(#42/#43): replace with Firestore write via the integration seam above.
  if (import.meta.env.DEV) {
    // eslint-disable-next-line no-console
    console.info("[stub] submitSkills", payload);
  }
  return { ok: true };
}

/** Lightweight email check — good enough for client-side UX, not a validator of record. */
export function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}
