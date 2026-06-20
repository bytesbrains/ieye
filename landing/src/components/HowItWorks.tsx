import { Section } from "./Section";
import { HonestyLine } from "./HonestyLine";

// Fast / slow path glyphs. Sharp wedge = the acute break; soft dots = the slow silence.
// No alarm-red, no countdowns. Amber for the fast hope, teal for the calm slow path.
function FastGlyph() {
  return (
    <svg viewBox="0 0 48 48" className="h-10 w-10" aria-hidden="true">
      <path
        d="M26 4 L12 26 L22 26 L18 44 L36 20 L26 20 Z"
        className="fill-amber-deep"
      />
    </svg>
  );
}
function SlowGlyph() {
  return (
    <svg viewBox="0 0 48 48" className="h-10 w-10" aria-hidden="true">
      <circle cx="10" cy="24" r="3.5" className="fill-teal-deep" />
      <circle cx="24" cy="24" r="3.5" className="fill-teal-deep/70" />
      <circle cx="38" cy="24" r="3.5" className="fill-teal-deep/40" />
    </svg>
  );
}

export function HowItWorks() {
  return (
    <Section id="how-it-works" labelledBy="how-heading">
      <div className="container-wide">
        <div className="container-prose px-0">
          <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-teal-deep">
            How it works — two speeds
          </p>
          <h2 id="how-heading" className="text-3xl font-semibold sm:text-4xl">
            You don&rsquo;t have to do anything. You just live.
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">
            iEye learns the rhythm of your ordinary days. When that rhythm breaks, it acts — at the
            speed the moment needs.
          </p>
        </div>

        {/* one baseline, two branches */}
        <div className="mt-12 grid gap-6 md:grid-cols-2">
          {/* FAST — reads first; carries the strongest hope */}
          <article className="flex flex-col rounded-2xl border-2 border-amber/40 bg-amber/5 p-7">
            <div className="flex items-center gap-3">
              <FastGlyph />
              <h3 className="text-2xl font-semibold text-charcoal">When seconds matter</h3>
            </div>
            <p className="mt-4 text-lg leading-relaxed text-charcoal-soft">
              <strong className="font-semibold text-charcoal">Something just happened.</strong> A hard
              fall. A crash. A heart that suddenly isn&rsquo;t right. iEye feels the break the instant
              it happens, asks once — <em>are you okay?</em> — and if you can&rsquo;t answer, it
              summons help in <strong className="font-semibold text-charcoal">minutes.</strong>
            </p>
            <p className="mt-4 text-base font-medium text-amber-deep">
              This is the speed that can save a life.
            </p>
          </article>

          {/* SLOW — the silence path */}
          <article className="flex flex-col rounded-2xl border-2 border-teal/30 bg-teal/5 p-7">
            <div className="flex items-center gap-3">
              <SlowGlyph />
              <h3 className="text-2xl font-semibold text-charcoal">When no one would have noticed</h3>
            </div>
            <p className="mt-4 text-lg leading-relaxed text-charcoal-soft">
              <strong className="font-semibold text-charcoal">The days went quiet.</strong> No fall,
              no alarm — just a silence where your ordinary life used to be. iEye notices the absence,
              checks gently, and if you can&rsquo;t be reached, tells the few people you chose — so
              you&rsquo;re <strong className="font-semibold text-charcoal">found in hours, not weeks.</strong>
            </p>
            <p className="mt-4 text-base font-medium text-teal-deep">
              No one is ever left undiscovered.
            </p>
          </article>
        </div>

        <div className="container-prose mt-10 px-0">
          <p className="text-lg leading-relaxed text-charcoal-soft">
            Fast or slow, the promise is the same:{" "}
            <strong className="font-semibold text-charcoal">iEye gets help to you in time.</strong>{" "}
            It&rsquo;s not a doctor or an ambulance — it&rsquo;s the thing that makes sure they&rsquo;re{" "}
            <em>called</em>, for you, fast.
          </p>
          <HonestyLine className="mt-4" />
        </div>
      </div>
    </Section>
  );
}
