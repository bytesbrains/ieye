// Authenticated-app header: brand + nav between /account and /admin + sign-out.
// Distinct from the public landing Header (which is anchor-scroll based).

import { Link, useNavigate } from "react-router-dom";
import { Wordmark } from "../Brand";
import { useAuth } from "../../auth/AuthProvider";

export function AppHeader() {
  const { user, isAdmin, signOut } = useAuth();
  const navigate = useNavigate();

  async function handleSignOut() {
    await signOut();
    navigate("/");
  }

  return (
    <header className="sticky top-0 z-50 border-b border-charcoal/10 bg-paper/90 backdrop-blur">
      <div className="mx-auto flex max-w-5xl flex-wrap items-center justify-between gap-3 px-5 py-3">
        <Link to="/" className="rounded-md" aria-label="iEye home">
          <Wordmark />
        </Link>

        <nav aria-label="Account" className="flex items-center gap-2 sm:gap-4">
          <Link
            to="/account"
            className="rounded-md px-3 py-2 text-base text-charcoal-soft hover:text-charcoal"
          >
            My account
          </Link>
          {isAdmin && (
            <Link
              to="/admin"
              className="rounded-md px-3 py-2 text-base font-semibold text-teal-deep hover:text-teal"
            >
              Admin
            </Link>
          )}
          {user && (
            <span className="hidden items-center gap-2 sm:flex" aria-hidden="true">
              {user.photoURL ? (
                <img
                  src={user.photoURL}
                  alt=""
                  className="h-8 w-8 rounded-full border border-charcoal/15"
                  referrerPolicy="no-referrer"
                />
              ) : null}
            </span>
          )}
          <button type="button" onClick={handleSignOut} className="btn btn-secondary px-4 py-2 text-sm">
            Sign out
          </button>
        </nav>
      </div>
    </header>
  );
}
