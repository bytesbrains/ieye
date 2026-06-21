// Single Admin SDK initialization for all functions.
//
// The Admin SDK runs with full privileges and BYPASSES Firestore security
// rules — that is exactly why money writes, admin-claim minting, and the public
// supporter projection live here and not in the client (THREAT-MODEL §4/§5).
// Everything in this codebase must therefore enforce its own authorization.

import { initializeApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

if (getApps().length === 0) {
  initializeApp();
}

export const auth = getAuth();
export const db = getFirestore();
