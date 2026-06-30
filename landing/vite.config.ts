import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Static build -> dist/. Firebase Hosting serves dist/ (see firebase.json).
export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "dist",
    sourcemap: false,
  },
  server: {
    // Pre-compile the Firebase-laden modules so the FIRST sign-in interaction
    // (a dynamic import on click + a signInWithRedirect round-trip) isn't racing
    // Vite's on-demand transform — which made the redirect-auth e2e flake on a
    // cold dev server. Benefits real first-time dev sign-in too; no prod impact.
    warmup: {
      clientFiles: [
        "./src/lib/firebase.ts",
        "./src/lib/waitlist.ts",
        "./src/lib/waitlistPending.ts",
        "./src/auth/AuthProvider.tsx",
      ],
    },
  },
});
