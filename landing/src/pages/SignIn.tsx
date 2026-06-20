// /signin — Google sign-in entry. Redirects to where the user was headed
// (or /account) once signed in. Honest framing: this is the CONTRIBUTION
// account, distinct from the mobile safety-app identity (THREAT-MODEL §1).

import { useEffect } from "react";
import { Link, Navigate, useLocation, useNavigate } from "react-router-dom";
import { Wordmark } from "../components/Brand";
import { GoogleSignInButton } from "../components/app/GoogleSignInButton";
import { useAuth } from "../auth/AuthProvider";
import { Spinner } from "../components/app/Spinner";

export function SignIn() {
  const { user, loading } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const from = (location.state as { from?: string } | null)?.from ?? "/account";

  useEffect(() => {
    if (!loading && user) navigate(from, { replace: true });
  }, [loading, user, from, navigate]);

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Spinner />
      </div>
    );
  }
  if (user) return <Navigate to={from} replace />;

  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-5 py-12">
      <div className="w-full max-w-md rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-8 sm:p-10">
        <div className="flex justify-center">
          <Wordmark />
        </div>
        <h1 className="mt-8 text-center text-3xl font-semibold">Sign in to your account</h1>
        <p className="mt-4 text-center text-base text-charcoal-soft">
          This is your iEye <strong>contribution</strong> account — for supporting the project and
          managing how you appear. It&rsquo;s separate from the safety app on your phone.
        </p>

        <div className="mt-8">
          <GoogleSignInButton />
        </div>

        <p className="mt-6 text-center text-sm text-charcoal-muted">
          We only read your name, email, and photo from Google to set up your profile. You can
          delete your account and data at any time.
        </p>

        <div className="mt-8 text-center">
          <Link to="/" className="btn-ghost text-sm">
            Back to the iEye home page
          </Link>
        </div>
      </div>
    </main>
  );
}
