import { Section } from "./Section";

export function SupporterWall() {
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
          When contributions open, every one that comes in and everything that goes out will be
          shown publicly — dated and categorized — so the money is as open as the code. There&rsquo;s
          nothing to show yet, because nothing has come in yet.
        </p>

        {/* Placeholder supporter wall — no live data in Phase 1. */}
        <div className="mt-10 rounded-2xl border-2 border-dashed border-charcoal/20 bg-paper p-8">
          <p className="text-lg font-semibold text-charcoal">The supporter wall is coming soon.</p>
          <p className="mx-auto mt-2 max-w-prose text-base text-charcoal-soft">
            Naming will always be <strong>opt-in</strong> and private by default: contributors choose
            whether to show their name, and can change that anytime. No one is ever named without
            asking.
          </p>
          <div className="mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4" aria-hidden="true">
            {Array.from({ length: 8 }).map((_, i) => (
              <div
                key={i}
                className="h-12 rounded-lg bg-charcoal/5"
              />
            ))}
          </div>
        </div>
      </div>
    </Section>
  );
}
