// Tamper-evident consent record for the public supporter wall (THREAT-MODEL §5.3,
// #38 §4.5 "evidence of lawful basis").
//
// A user's opt-in flags + consentVersion live on their own (client-writable)
// `users` doc — that is a *request to publish*, not proof of consent. This module
// writes an append-only `consentLog` entry, server-timestamped, every time the
// consent-relevant state changes. The collection has NO allow rule, so the
// default-deny block makes it unreadable/unwritable to every client — only the
// Admin SDK writes it. This is the durable record of who consented to what, when.

import { FieldValue } from "firebase-admin/firestore";
import { db } from "./firebaseAdmin";

export interface ConsentState {
  optInDisplayName: boolean;
  optInDisplayAmount: boolean;
  consentVersion: string | null;
}

/** The consent-bearing fields, read defensively from a (possibly absent) user doc. */
export function readConsentState(data: Record<string, unknown> | undefined): ConsentState {
  return {
    optInDisplayName: data?.optInDisplayName === true,
    optInDisplayAmount: data?.optInDisplayAmount === true,
    consentVersion: typeof data?.consentVersion === "string" ? data.consentVersion : null,
  };
}

export function consentChanged(a: ConsentState, b: ConsentState): boolean {
  return (
    a.optInDisplayName !== b.optInDisplayName ||
    a.optInDisplayAmount !== b.optInDisplayAmount ||
    a.consentVersion !== b.consentVersion
  );
}

/**
 * Append a server-timestamped consent record. `action` distinguishes a genuine
 * grant/extension (something is now opted in) from a withdrawal (all flags off).
 */
export async function recordConsent(uid: string, state: ConsentState): Promise<void> {
  const granting = state.optInDisplayName || state.optInDisplayAmount;
  await db.collection("consentLog").add({
    uid,
    action: granting ? "consent" : "withdraw",
    optInDisplayName: state.optInDisplayName,
    optInDisplayAmount: state.optInDisplayAmount,
    consentVersion: state.consentVersion,
    recordedAt: FieldValue.serverTimestamp(),
  });
}
