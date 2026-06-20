import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Static build -> dist/. Firebase Hosting serves dist/ (see firebase.json).
export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "dist",
    sourcemap: false,
  },
});
