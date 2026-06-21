// Append-only audit trail for privileged actions (admin grant/revoke).
//
// Written ONLY by the Admin SDK; the `adminAudit` collection is not matched by
// any allow rule, so the default-deny block makes it unreadable/unwritable to
// every client. This gives a tamper-evident record of who changed whose access.

import { FieldValue } from "firebase-admin/firestore";
import { db } from "./firebaseAdmin";

export type AuditAction = "grantAdmin" | "revokeAdmin";

export async function writeAudit(params: {
  action: AuditAction;
  actorUid: string;
  targetUid: string;
  targetEmail?: string | null;
}): Promise<void> {
  await db.collection("adminAudit").add({
    action: params.action,
    actorUid: params.actorUid,
    targetUid: params.targetUid,
    targetEmail: params.targetEmail ?? null,
    at: FieldValue.serverTimestamp(),
  });
}
