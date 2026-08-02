import React, { Suspense, lazy } from "react";
import ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import App from "./App";
import { Spinner } from "./components/app/Spinner";
import "./index.css";

// The public landing (/) ships in the main bundle — fast, no Firebase.
// Everything auth'd (which pulls in Firebase + the auth context) is lazy-loaded
// so a first-time visitor to the landing page never downloads Firebase.
const AuthShell = lazy(() => import("./auth/AuthShell"));

// Designer-only #36 artifact — split into its own chunk so the landing page's
// main bundle never carries the wall components or their mock data.
const WallPreview = lazy(() =>
  import("./pages/WallPreview").then((m) => ({ default: m.WallPreview }))
);

// The app hub (/app) — install links + early-access waitlist. Its own chunk so
// the landing bundle stays lean; Firebase only enters on a real waitlist click.
const AppHub = lazy(() =>
  import("./pages/AppHub").then((m) => ({ default: m.AppHub }))
);

// Published legal pages — own chunks, no Firebase.
const Privacy = lazy(() =>
  import("./pages/Privacy").then((m) => ({ default: m.Privacy }))
);
const Terms = lazy(() => import("./pages/Terms").then((m) => ({ default: m.Terms })));

function Lazy({ children }: { children: React.ReactNode }) {
  return (
    <Suspense
      fallback={
        <div className="flex min-h-screen items-center justify-center">
          <Spinner />
        </div>
      }
    >
      {children}
    </Suspense>
  );
}

// Routes:
//   /        -> public landing (Phase 1, unchanged, no auth, no Firebase)
//   /signin  -> Google sign-in        (lazy, behind AuthProvider)
//   /account -> signed-in user space  (lazy, RequireAuth)
//   /admin   -> admin shell           (lazy, RequireAdmin — admin custom claim)
const router = createBrowserRouter([
  { path: "/", element: <App /> },
  // The app hub — install links + early-access waitlist (lazy, its own chunk).
  {
    path: "/app",
    element: (
      <Lazy>
        <AppHub />
      </Lazy>
    ),
  },
  // Designer comparison artifact for #36 — lazy-loaded (its own chunk, no Firebase).
  {
    path: "/wall-preview",
    element: (
      <Lazy>
        <WallPreview />
      </Lazy>
    ),
  },
  // Published legal pages — lazy, no Firebase.
  {
    path: "/privacy",
    element: (
      <Lazy>
        <Privacy />
      </Lazy>
    ),
  },
  {
    path: "/terms",
    element: (
      <Lazy>
        <Terms />
      </Lazy>
    ),
  },
  {
    path: "/signin",
    element: (
      <Lazy>
        <AuthShell view="signin" />
      </Lazy>
    ),
  },
  {
    path: "/account",
    element: (
      <Lazy>
        <AuthShell view="account" />
      </Lazy>
    ),
  },
  {
    path: "/admin",
    element: (
      <Lazy>
        <AuthShell view="admin" />
      </Lazy>
    ),
  },
  // Unknown paths fall back to the public landing.
  { path: "*", element: <App /> },
]);

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);
