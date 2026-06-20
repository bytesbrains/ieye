// Lazy boundary for all authenticated views. Importing this pulls in Firebase
// (via AuthProvider) and the auth'd pages — so a visitor who only sees the
// public landing never downloads any of it.

import { AuthProvider } from "./AuthProvider";
import { RequireAuth, RequireAdmin } from "./guards";
import { SignIn } from "../pages/SignIn";
import { Account } from "../pages/Account";
import { Admin } from "../pages/Admin";

export type AuthView = "signin" | "account" | "admin";

export default function AuthShell({ view }: { view: AuthView }) {
  return (
    <AuthProvider>
      {view === "signin" && <SignIn />}
      {view === "account" && (
        <RequireAuth>
          <Account />
        </RequireAuth>
      )}
      {view === "admin" && (
        <RequireAdmin>
          <Admin />
        </RequireAdmin>
      )}
    </AuthProvider>
  );
}
