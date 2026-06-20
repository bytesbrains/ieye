// Route guards (Phase 1.5, #43).
//
// These are CONVENIENCE redirects, not a security boundary. The Firestore
// rules deny unauthorized reads/writes regardless of what the UI renders. We
// still guard so users land somewhere sensible: signed-out users go to a
// sign-in prompt; non-admins never see the admin shell chrome.

import type { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "./AuthProvider";
import { Spinner } from "../components/app/Spinner";

function FullPageLoading({ label }: { label: string }) {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 text-charcoal-soft">
      <Spinner />
      <p className="text-base">{label}</p>
    </div>
  );
}

/** Requires any signed-in user. Redirects to /signin otherwise. */
export function RequireAuth({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth();
  const location = useLocation();

  if (loading) return <FullPageLoading label="Checking your sign-in…" />;
  if (!user) {
    return <Navigate to="/signin" replace state={{ from: location.pathname }} />;
  }
  return <>{children}</>;
}

/** Requires the admin custom claim. Non-admins are sent to /account. */
export function RequireAdmin({ children }: { children: ReactNode }) {
  const { user, isAdmin, loading } = useAuth();
  const location = useLocation();

  if (loading) return <FullPageLoading label="Checking your access…" />;
  if (!user) {
    return <Navigate to="/signin" replace state={{ from: location.pathname }} />;
  }
  if (!isAdmin) {
    // Signed in but not an admin — bounce to their own account, not an error.
    return <Navigate to="/account" replace />;
  }
  return <>{children}</>;
}
