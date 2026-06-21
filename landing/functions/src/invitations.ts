// Contributor invitation — fires when an admin advances a request to 'invited'.
//
// The admin shell can only move a contributorRequest's status FORWARD and can
// never rewrite its owner (firestore.rules enforces this structurally); actually
// REACHING OUT to the person is backend work. On the transition into 'invited'
// we enqueue the invitation email FIRST, then stamp invitedAt — so if the
// enqueue fails the function errors before the stamp, leaving the transition
// re-drivable instead of marked-sent-with-no-email-out. Guarded so it runs
// exactly once per transition (no loop when we write invitedAt back).

import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { auth } from "./firebaseAdmin";
import { enqueueEmail } from "./email";

function inviteHtml(): string {
  return [
    "<p>Good news — your request to help build <strong>iEye</strong> has been accepted.</p>",
    "<p>iEye gets help to people in time — and it only exists because people like you build it in the open.</p>",
    "<p>We&rsquo;ll follow up shortly with how to get started. Welcome aboard.</p>",
    "<p>— The iEye team</p>",
  ].join("");
}

export const onContributorRequestInvited = onDocumentUpdated(
  "contributorRequests/{id}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after) return;

    const prevStatus = before.get("status");
    const nextStatus = after.get("status");

    // Only on the transition INTO 'invited'. (If it was already invited, the
    // invitedAt write below re-triggers this — prevStatus === 'invited' stops it.)
    if (nextStatus !== "invited" || prevStatus === "invited") return;

    const ownerUid = after.get("ownerUid");
    let email: string | undefined;
    try {
      email = (await auth.getUser(ownerUid)).email ?? undefined;
    } catch (err) {
      logger.warn("invite: could not resolve owner email", { ownerUid, err });
    }

    // Enqueue the email BEFORE stamping. If enqueueEmail throws, the function
    // errors here and invitedAt is never written, so the transition can be
    // re-driven — we never mark an invite "sent" without it being queued.
    if (email) {
      await enqueueEmail(email, "You're invited to help build iEye", inviteHtml());
      logger.info("invite enqueued", { ownerUid });
    }

    // Stamp last, so its presence means the invite really went out.
    await after.ref.set({ invitedAt: FieldValue.serverTimestamp() }, { merge: true });
  }
);
