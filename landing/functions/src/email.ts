// Transactional email seam.
//
// We enqueue a document into the `mail` collection in the exact shape the
// Firebase "Trigger Email" extension consumes ({ to, message: { subject, html }}).
// Until that extension (or an equivalent SMTP wire-up) is enabled, the doc just
// queues — nothing is sent, and nothing breaks. This keeps us off any custom
// SMTP/secret handling in code (zero-spend, secrets stay in the extension config).
//
// Enable sending: install the "Trigger Email from Firestore" extension on the
// project and point it at the `mail` collection. See functions/README.md.

import { FieldValue } from "firebase-admin/firestore";
import { db } from "./firebaseAdmin";

export async function enqueueEmail(
  to: string,
  subject: string,
  html: string
): Promise<void> {
  await db.collection("mail").add({
    to,
    message: { subject, html },
    createdAt: FieldValue.serverTimestamp(),
  });
}
