// Admin custom-claim management — the SECURED path that replaces any manual
// bootstrap. The `admin` claim is the only thing that unlocks the admin surface
// (rules read request.auth.token.admin), so minting it is privileged:
//
//   - Only an existing admin may call grantAdmin / revokeAdmin (caller's own
//     ID-token claim is checked server-side — a client cannot fake it).
//   - Every change is written to the append-only adminAudit trail.
//   - The claim is set via the Admin SDK; no client can ever write its own.
//
// Bootstrapping the FIRST admin is a deliberate out-of-band act (Admin SDK /
// owner operation), done once; from then on admins manage each other here.

import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { auth } from "./firebaseAdmin";
import { writeAudit } from "./audit";

interface TargetInput {
  uid?: string;
  email?: string;
}

function assertCallerIsAdmin(req: CallableRequest): string {
  if (!req.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  if (req.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Only admins can manage admin access.");
  }
  return req.auth.uid;
}

function hasAdminClaim(claims: Record<string, unknown> | undefined): boolean {
  return claims?.admin === true;
}

/**
 * Count users that currently hold the `admin` claim. The auth backend is the
 * source of truth (not a Firestore registry that could drift), so an admin
 * bootstrapped out-of-band is counted too. Paginated; at this phase the whole
 * user base fits in one page.
 */
async function countAdmins(): Promise<number> {
  let count = 0;
  let pageToken: string | undefined;
  do {
    const res = await auth.listUsers(1000, pageToken);
    for (const u of res.users) {
      if (hasAdminClaim(u.customClaims)) count++;
    }
    pageToken = res.pageToken;
  } while (pageToken);
  return count;
}

async function resolveTarget(data: TargetInput): Promise<{ uid: string; email: string | null }> {
  if (data?.uid) {
    const u = await auth.getUser(data.uid);
    return { uid: u.uid, email: u.email ?? null };
  }
  if (data?.email) {
    const u = await auth.getUserByEmail(data.email.trim());
    return { uid: u.uid, email: u.email ?? null };
  }
  throw new HttpsError("invalid-argument", "Provide the target user's uid or email.");
}

/** Grant the `admin` claim. Admin-only. Idempotent. */
export const grantAdmin = onCall(async (req: CallableRequest<TargetInput>) => {
  const actorUid = assertCallerIsAdmin(req);
  const { uid, email } = await resolveTarget(req.data ?? {});

  const user = await auth.getUser(uid);
  await auth.setCustomUserClaims(uid, { ...(user.customClaims ?? {}), admin: true });
  await writeAudit({ action: "grantAdmin", actorUid, targetUid: uid, targetEmail: email });

  logger.info("grantAdmin", { actorUid, targetUid: uid });
  // The target must refresh their ID token (next sign-in / token refresh) for
  // the claim to take effect — surfaced to the caller so the UI can say so.
  return { ok: true, uid, email, note: "User must sign out and back in to pick up the claim." };
});

/** Revoke the `admin` claim. Admin-only. Idempotent. */
export const revokeAdmin = onCall(async (req: CallableRequest<TargetInput>) => {
  const actorUid = assertCallerIsAdmin(req);
  const { uid, email } = await resolveTarget(req.data ?? {});

  const user = await auth.getUser(uid);

  // Last-admin guard: if the target currently holds the claim and is the ONLY
  // admin, refuse — revoking would lock everyone out of the admin surface,
  // recoverable only by the out-of-band bootstrap. (No-op revokes of a
  // non-admin stay idempotent and skip the check.) Enforced here, not in the
  // UI — the UI is not the boundary.
  if (hasAdminClaim(user.customClaims) && (await countAdmins()) <= 1) {
    throw new HttpsError(
      "failed-precondition",
      "You can't revoke the last admin. Grant another admin first."
    );
  }

  const claims = { ...(user.customClaims ?? {}) };
  delete claims.admin;
  await auth.setCustomUserClaims(uid, claims);
  await writeAudit({ action: "revokeAdmin", actorUid, targetUid: uid, targetEmail: email });

  logger.info("revokeAdmin", { actorUid, targetUid: uid });
  return { ok: true, uid, email, note: "Access ends after their token refreshes (≤1h or next sign-in)." };
});
