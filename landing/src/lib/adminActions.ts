// Client wrappers for the admin-claim callables (functions/src/adminClaims.ts).
//
// These only INVOKE the functions; the actual authorization (caller must be an
// admin) is enforced server-side from the caller's ID-token claim — a client
// cannot bypass it. The UI gate (RequireAdmin) is convenience, not the boundary.

import { httpsCallable } from "firebase/functions";
import { functions } from "./firebase";

export interface AdminActionResult {
  ok: boolean;
  uid: string;
  email: string | null;
  note?: string;
}

type Target = { email?: string; uid?: string };

export async function callGrantAdmin(target: Target): Promise<AdminActionResult> {
  const fn = httpsCallable<Target, AdminActionResult>(functions, "grantAdmin");
  const res = await fn(target);
  return res.data;
}

export async function callRevokeAdmin(target: Target): Promise<AdminActionResult> {
  const fn = httpsCallable<Target, AdminActionResult>(functions, "revokeAdmin");
  const res = await fn(target);
  return res.data;
}

/** Turn a Functions/HttpsError into a calm, human sentence for the UI. */
export function adminActionError(err: unknown): string {
  const code = (err as { code?: string })?.code ?? "";
  const message = (err as { message?: string })?.message ?? "";
  if (code === "functions/permission-denied") return "Only admins can manage admin access.";
  if (code === "functions/unauthenticated") return "Please sign in again.";
  // Last-admin guard (and similar server-side preconditions) — surface the
  // function's own sentence, which already explains what to do.
  if (code === "functions/failed-precondition") {
    return message.replace(/^.*?:\s*/, "") || "That can’t be done right now.";
  }
  if (code === "functions/not-found" || /no user record/i.test(message)) {
    return "No account found for that email — they need to sign in once first.";
  }
  if (code === "functions/invalid-argument") return "Enter the person’s email address.";
  return "That didn’t go through. Please try again in a moment.";
}
