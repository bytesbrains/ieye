import { useEffect, useState } from "react";
import { Section } from "./Section";
import type { PublicSupporterDoc, WithId } from "../lib/types";

// Transparency / supporter wall. Reads the live, world-readable publicSupporters
// projection — but LAZILY (dynamic import inside the effect), so Firebase never
// enters the main landing bundle (a first-time visitor downloads none of it).
//
// Flat wall (#36, Version B): name-only, equal weight, no amounts, no size-sort.
// Naming is opt-in and private by default — a name is here only because its owner
// asked, and the backend projects ONLY consented names into publicSupporters, so
// the wall is structurally incapable of showing anyone who didn't opt in (or any
// amount). Empty -> the honest "coming soon" placeholder.

export function SupporterWall() {
  // null = still loading; [] = loaded, none yet.
  const [supporters, setSupporters] = useState<WithId<PublicSupporterDoc>[] | null>(null);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const { fetchPublicSupporters } = await import("../lib/publicSupporters");
        const rows = await fetchPublicSupporters();
        if (!cancelled) setSupporters(rows);
      } catch {
        // Fail soft to the placeholder — the wall must never hard-error the page.
        if (!cancelled) setSupporters([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const named = (supporters ?? []).filter((s) => (s.displayName ?? "").trim() !== "");
  const hasSupporters = named.length > 0;

  return (
    <Section id="transparency" labelledBy="wall-heading" className="bg-paper-dim">
      <div className="container-prose text-center">
        <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-teal-deep">
          Transparency
        </p>
        <h2 id="wall-heading" className="text-3xl font-semibold sm:text-4xl">
          You won&rsquo;t have to trust us. You&rsquo;ll be able to check.
        </h2>
        <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">
          {hasSupporters
            ? "Every contribution that comes in and everything that goes out is shown publicly — so the money is as open as the code. These are the people and partners keeping iEye alive. Naming is opt-in; amounts are never shown."
            : "When contributions open, every one that comes in and everything that goes out will be shown publicly — dated and categorized — so the money is as open as the code. There’s nothing to show yet, because nothing has come in yet."}
        </p>

        {hasSupporters ? (
          <ul
            role="list"
            aria-label="Supporters"
            className="mt-10 flex flex-wrap justify-center gap-3"
          >
            {named.map((s) => (
              <li
                key={s.id}
                className="rounded-xl border-2 border-charcoal/10 bg-paper px-4 py-2 text-base font-medium text-charcoal"
              >
                {s.displayName}
              </li>
            ))}
          </ul>
        ) : (
          // Placeholder — no live supporters yet.
          <div className="mt-10 rounded-2xl border-2 border-dashed border-charcoal/20 bg-paper p-8">
            <p className="text-lg font-semibold text-charcoal">The supporter wall is coming soon.</p>
            <p className="mx-auto mt-2 max-w-prose text-base text-charcoal-soft">
              Naming will always be <strong>opt-in</strong> and private by default: contributors
              choose whether to show their name, and can change that anytime. No one is ever named
              without asking.
            </p>
            <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4" aria-hidden="true">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="h-12 rounded-lg bg-charcoal/5" />
              ))}
            </div>
          </div>
        )}
      </div>
    </Section>
  );
}
