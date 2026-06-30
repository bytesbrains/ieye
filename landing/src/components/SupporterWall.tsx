import { useEffect, useRef, useState } from "react";
import { Section } from "./Section";
import type { PublicSupporterDoc, WithId } from "../lib/types";

// Transparency / supporter wall. Reads the live, world-readable publicSupporters
// projection — but LAZILY (dynamic import inside the effect), so Firebase never
// enters the main landing bundle (a first-time visitor downloads none of it).
//
// Flat wall (#36, Version B): name-only, equal weight, no amounts, no size-sort.
// We render ONLY displayName — the projection carries nothing private (no email,
// no uid, no amount), and we never reach for any other field, so the wall cannot
// leak who gave or how much even if a row somehow carried extra data.
//
// PAGINATED in both dimensions: the query is bounded by PAGE_SIZE and walked with
// a cursor (lib/publicSupporters), and the view loads a page at a time via "Show
// more" — so hundreds/thousands of supporters never blow up the read or the DOM.
// Empty -> the honest "coming soon" placeholder.

const PAGE_SIZE = 60;

export function SupporterWall() {
  // null = still loading the first page; [] = loaded, none yet.
  const [supporters, setSupporters] = useState<WithId<PublicSupporterDoc>[] | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const cursorRef = useRef<unknown>(undefined);
  const seenIds = useRef<Set<string>>(new Set());

  async function loadNextPage(): Promise<void> {
    try {
      const { fetchPublicSupporters } = await import("../lib/publicSupporters");
      const page = await fetchPublicSupporters(PAGE_SIZE, cursorRef.current);
      cursorRef.current = page.cursor ?? cursorRef.current;
      setHasMore(page.hasMore);
      // De-dupe defensively so a cursor edge can never double-render a name.
      const fresh = page.rows.filter((r) => !seenIds.current.has(r.id));
      fresh.forEach((r) => seenIds.current.add(r.id));
      setSupporters((prev) => [...(prev ?? []), ...fresh]);
    } catch {
      // Fail soft to the placeholder — the wall must never hard-error the page.
      setSupporters((prev) => prev ?? []);
      setHasMore(false);
    }
  }

  useEffect(() => {
    void loadNextPage();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function handleShowMore() {
    setLoadingMore(true);
    try {
      await loadNextPage();
    } finally {
      // Always re-enable, even if a future loadNextPage starts throwing —
      // otherwise the button could stick disabled.
      setLoadingMore(false);
    }
  }

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
          <>
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
            {hasMore && (
              <div className="mt-8">
                <button
                  type="button"
                  onClick={handleShowMore}
                  disabled={loadingMore}
                  className="btn btn-secondary disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {loadingMore ? "Loading…" : "Show more supporters"}
                </button>
              </div>
            )}
          </>
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
