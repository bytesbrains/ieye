// Auth state context (Phase 1.5, #43).
//
// Holds the signed-in Firebase user and — critically — whether they are an
// admin. Admin is read from the ID-token custom claim (`claims.admin`), NEVER
// from a Firestore read or a `role` field (THREAT-MODEL §7.2). The claim is the
// only source of admin truth; the UI is not a security boundary (the rules are).

import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import {
  onIdTokenChanged,
  signInWithRedirect,
  getRedirectResult,
  signOut as fbSignOut,
  type User,
} from "firebase/auth";
import { auth, googleProvider } from "../lib/firebase";

export interface AuthState {
  /** Firebase user, or null when signed out. */
  user: User | null;
  /** True only when the ID-token carries the `admin` custom claim. */
  isAdmin: boolean;
  /** True until the first auth state + claim resolution completes. */
  loading: boolean;
  signInWithGoogle: () => Promise<void>;
  signOut: () => Promise<void>;
  /** Force a token refresh (e.g. after an admin claim is minted backend-side). */
  refreshClaims: () => Promise<void>;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

async function readAdminClaim(user: User | null): Promise<boolean> {
  if (!user) return false;
  // getIdTokenResult() decodes the claims without an extra Firestore read.
  const token = await user.getIdTokenResult();
  return token.claims.admin === true;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Finalize any pending redirect sign-in. We use signInWithRedirect (not
    // signInWithPopup): on *.web.app, COOP severs the popup's cross-window
    // channel (window.closed polling + auth-iframe postMessage), so the popup
    // opens, the user signs in, and the promise NEVER resolves — auth hangs.
    // A redirect is a top-level navigation, immune to that. getRedirectResult
    // completes the exchange on return and surfaces errors (e.g.
    // auth/unauthorized-domain) that would otherwise be swallowed.
    getRedirectResult(auth).catch((e) => {
      console.error("[auth] redirect sign-in did not complete:", e);
    });

    // onIdTokenChanged fires on sign-in, sign-out, AND token refresh — so a
    // newly-minted admin claim is picked up on the next refresh without a
    // separate onAuthStateChanged listener (which is a strict subset of this).
    const unsub = onIdTokenChanged(auth, async (u) => {
      setUser(u);
      setIsAdmin(await readAdminClaim(u));
      setLoading(false);
    });
    return unsub;
  }, []);

  const value = useMemo<AuthState>(
    () => ({
      user,
      isAdmin,
      loading,
      signInWithGoogle: async () => {
        // Navigates away to Google and back — the click handler's code after
        // this await does not run (the page unloads). Signed-in state is picked
        // up by getRedirectResult + onIdTokenChanged on return.
        await signInWithRedirect(auth, googleProvider);
      },
      signOut: async () => {
        await fbSignOut(auth);
      },
      refreshClaims: async () => {
        if (!auth.currentUser) return;
        await auth.currentUser.getIdToken(true); // force refresh
        setIsAdmin(await readAdminClaim(auth.currentUser));
      },
    }),
    [user, isAdmin, loading]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within <AuthProvider>");
  return ctx;
}
