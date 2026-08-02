import React, { Suspense, lazy } from "react";
import ReactDOM from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import App from "./App";
import { Spinner } from "./components/app/Spinner";
import "./index.css";

// The public landing (/) ships in the main bundle — fast, no Firebase. The app
// hub (/app) and legal pages are their own chunks; Firebase enters only on a real
// waitlist sign-in click. (The signed-in account/admin space was removed with the
// payments + contribution subsystem — iEye takes no donations.)
const AppHub = lazy(() =>
  import("./pages/AppHub").then((m) => ({ default: m.AppHub }))
);
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
//   /        -> public landing (no auth, no Firebase)
//   /app     -> the app hub — exposure teaser + install links + early-access waitlist
//   /privacy, /terms -> published legal pages (own chunks, no Firebase)
const router = createBrowserRouter([
  { path: "/", element: <App /> },
  {
    path: "/app",
    element: (
      <Lazy>
        <AppHub />
      </Lazy>
    ),
  },
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
  // Unknown paths fall back to the public landing.
  { path: "*", element: <App /> },
]);

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);
