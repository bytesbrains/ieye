// Firebase initialization seam (Phase 1.5, #43).
//
// Single source of truth for the Firebase app, Auth, and Firestore handles.
// In DEV with VITE_USE_EMULATOR=true we connect to the local emulators so the
// app runs against NO real Firebase project. For a real project (#42), set the
// VITE_FIREBASE_* vars in `.env` and flip VITE_USE_EMULATOR=false.
//
// Security note: the rules in firestore.rules are the boundary, not this file.
// Nothing here grants privilege; admin is read from the ID-token custom claim
// (see auth.ts), never from a Firestore field.

import { initializeApp, type FirebaseApp } from "firebase/app";
import { getAuth, connectAuthEmulator, GoogleAuthProvider, type Auth } from "firebase/auth";
import { getFirestore, connectFirestoreEmulator, type Firestore } from "firebase/firestore";
import { getFunctions, connectFunctionsEmulator, type Functions } from "firebase/functions";

// Callable functions live in asia-south1 (next to Firestore) — the region MUST
// match the deployed functions or callables 404.
const FUNCTIONS_REGION = "asia-south1";

const env = import.meta.env;

const useEmulator = env.VITE_USE_EMULATOR === "true";

const firebaseConfig = {
  apiKey: env.VITE_FIREBASE_API_KEY ?? "demo-api-key",
  authDomain: env.VITE_FIREBASE_AUTH_DOMAIN ?? "demo-ieye.firebaseapp.com",
  projectId: env.VITE_FIREBASE_PROJECT_ID ?? "demo-ieye",
  storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET ?? "demo-ieye.appspot.com",
  messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? "000000000000",
  appId: env.VITE_FIREBASE_APP_ID ?? "1:000000000000:web:0000000000000000000000",
};

export const app: FirebaseApp = initializeApp(firebaseConfig);
export const auth: Auth = getAuth(app);
export const db: Firestore = getFirestore(app);
export const functions: Functions = getFunctions(app, FUNCTIONS_REGION);

// Google provider — the only sign-in method in Phase 1.5.
export const googleProvider = new GoogleAuthProvider();

// Connect to emulators exactly once, in dev only. Guard against HMR double-init.
let emulatorsConnected = false;
export function connectEmulatorsOnce(): void {
  if (!useEmulator || emulatorsConnected) return;
  emulatorsConnected = true;

  const authUrl = env.VITE_EMULATOR_AUTH_URL ?? "http://127.0.0.1:9099";
  const fsHost = env.VITE_EMULATOR_FIRESTORE_HOST ?? "127.0.0.1";
  const fsPort = Number(env.VITE_EMULATOR_FIRESTORE_PORT ?? "8080");
  const fnPort = Number(env.VITE_EMULATOR_FUNCTIONS_PORT ?? "5001");

  // `disableWarnings` keeps the console clean — the banner is informational.
  connectAuthEmulator(auth, authUrl, { disableWarnings: true });
  connectFirestoreEmulator(db, fsHost, fsPort);
  connectFunctionsEmulator(functions, fsHost, fnPort);

  // eslint-disable-next-line no-console
  console.info(
    `[iEye] Firebase emulators connected — Auth ${authUrl}, Firestore ${fsHost}:${fsPort}, Functions ${fsHost}:${fnPort}`
  );
}

connectEmulatorsOnce();

export const IS_EMULATOR = useEmulator;
