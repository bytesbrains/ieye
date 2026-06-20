// Shared chrome for authenticated routes: app header + centered main + footer note.

import type { ReactNode } from "react";
import { AppHeader } from "./AppHeader";

export function AppLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <a
        href="#app-main"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-[100] focus:rounded-md focus:bg-charcoal focus:px-4 focus:py-2 focus:text-paper"
      >
        Skip to content
      </a>
      <AppHeader />
      <main id="app-main" className="mx-auto w-full max-w-3xl px-5 py-10 sm:py-14">
        {children}
      </main>
    </>
  );
}
