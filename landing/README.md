# iEye — Phase 1 landing page

The public, hope-first landing page for **iEye** — a welfare / liveness app built on the
Maktub Protocol: _iEye gets help to you in time._

This is **Phase 1: public-only**. No auth, no live money, no backend. It is built so that
auth / profile / admin (#43) can be layered on later without a rewrite.

## Stack

- **Vite + React 18 + TypeScript**
- **Tailwind CSS** (warm-paper / charcoal base, beacon-amber accent, twilight-teal)
- Static build → `dist/`, **Firebase Hosting-ready**

## Run

```bash
cd landing
npm install
npm run dev      # local dev server (http://localhost:5173)
npm run build    # type-check + production build to dist/
npm run preview  # serve the production build locally
```

## Structure

```
landing/
├─ index.html              # SEO + Open Graph + favicon wiring
├─ firebase.json           # Hosting → dist/, SPA rewrite, asset caching
├─ .firebaserc             # PLACEHOLDER project id (CEO creates the real one, #42)
├─ .env.example            # no secrets needed in Phase 1; template for #42/#43
├─ public/
│  ├─ ieye-logo-scene.png  # hero illustration + OG image
│  ├─ ieye-appicon.png
│  └─ icons/               # favicons + site.webmanifest (from brand/icons/web)
└─ src/
   ├─ App.tsx              # one-page assembly + skip link
   ├─ components/          # Hero, Gap, HowItWorks (two speeds), Trust, Contribute, …
   └─ lib/
      └─ submit.ts         # SINGLE integration seam for the forms (stubbed — see TODO)
```

## What's stubbed (Phase 1)

- **Forms** (waitlist email + "contribute your skills") have full UI + validation, but
  `src/lib/submit.ts` resolves a client-side success state without persisting. It is the
  only place the app talks to a backend, so wiring Firestore later is a one-file change.
  Look for `// TODO(#42/#43): wire to Firestore …`.
- **Money / contributions** are framed as _coming soon_. No payment UI, no crypto address
  (that's Phase 2, Legal-gated #39).
- **Supporter wall** is a placeholder (opt-in-to-be-named explained, no live data).

## Brand + honesty guardrails honored

- Hope-first per **#40 / #41**: lead with "iEye gets help to you in time"; dignity line
  ("you will not go unseen") is the quiet floor.
- Capability never guarantee ("_can_ save lives"); "not a substitute for emergency services".
- "contribution" never "donation"; no "dead man's switch"; no "monitor / track / surveil".
- Lighthouse-not-camera; no alarm-red; no green "protected" shield.
- Accessibility: semantic HTML, 18px+ base type, visible focus, keyboard + screen-reader
  friendly, respects `prefers-reduced-motion`.

## Deploy (do NOT run until the project exists)

```bash
# After the CEO creates the BytesBrains Firebase project (#42) and sets it in .firebaserc:
npm run build && firebase deploy --only hosting
```
