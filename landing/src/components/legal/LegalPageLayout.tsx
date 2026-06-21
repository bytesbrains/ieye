import type { ReactNode } from "react";
import { Link } from "react-router-dom";
import { Wordmark } from "../Brand";

// Shared shell for the published legal pages (/privacy, /terms). Plain, calm,
// high-contrast, generous measure — same accessibility bar as the rest of the
// site (the audience skews older / non-technical). No Firebase here, so these
// pages stay in their own lightweight lazy chunk.
export function LegalPageLayout({
  title,
  version,
  effectiveDate,
  intro,
  children,
}: {
  title: string;
  version?: string;
  effectiveDate?: string;
  intro?: ReactNode;
  children: ReactNode;
}) {
  return (
    <main className="min-h-screen bg-paper px-5 py-12">
      <div className="mx-auto max-w-3xl">
        <Link to="/" className="btn-ghost text-sm">
          ← Back to home
        </Link>

        <header className="mt-6 border-b border-charcoal/10 pb-6">
          <Wordmark />
          <h1 className="mt-5 font-serif text-3xl font-semibold text-charcoal sm:text-4xl">
            {title}
          </h1>
          {(effectiveDate || version) && (
            <p className="mt-3 text-sm text-charcoal-muted">
              {effectiveDate && <>Effective {effectiveDate}</>}
              {effectiveDate && version && " · "}
              {version && (
                <>
                  Version <code className="text-charcoal-soft">{version}</code>
                </>
              )}
            </p>
          )}
          {intro && (
            <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">{intro}</p>
          )}
        </header>

        <div className="mt-8">{children}</div>
      </div>
    </main>
  );
}

// Consistent typography primitives (no @tailwindcss/typography in this project).
export function LegalH2({ id, children }: { id?: string; children: ReactNode }) {
  return (
    <h2 id={id} className="mt-10 font-serif text-xl font-semibold text-charcoal">
      {children}
    </h2>
  );
}

export function LegalP({ children }: { children: ReactNode }) {
  return <p className="mt-3 text-base leading-relaxed text-charcoal-soft">{children}</p>;
}

export function LegalUL({ children }: { children: ReactNode }) {
  return (
    <ul className="mt-3 list-disc space-y-2 pl-5 text-base leading-relaxed text-charcoal-soft">
      {children}
    </ul>
  );
}
