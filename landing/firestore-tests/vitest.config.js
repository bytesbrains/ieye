import { defineConfig } from 'vitest/config';

// Hermetic config for the Firestore rules suite. Without a config file here,
// Vitest walks UP the tree and loads ../vite.config.ts — which imports `vite`,
// a dependency this standalone package doesn't have. That makes the suite pass
// only when landing/node_modules happens to exist alongside (i.e. on a dev box,
// never in clean CI). Pinning the root to this directory stops the upward
// search: the rules tests are plain Node + emulator and need no Vite at all.
export default defineConfig({
  root: import.meta.dirname,
  // Same reason: an inline (empty) PostCSS config stops Vitest walking up to
  // ../postcss.config.js, which pulls in tailwindcss. These tests touch no CSS.
  css: { postcss: {} },
});
