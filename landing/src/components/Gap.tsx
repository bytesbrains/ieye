import { Section } from "./Section";

export function Gap() {
  return (
    <Section id="the-gap" labelledBy="gap-heading" className="bg-paper-dim">
      <div className="container-prose">
        <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-teal-deep">
          The gap iEye closes
        </p>
        <h2 id="gap-heading" className="text-3xl font-semibold sm:text-4xl">
          Living alone isn&rsquo;t the danger. Being alone when something goes wrong is.
        </h2>
        <div className="mt-6 space-y-5 text-lg leading-relaxed text-charcoal-soft">
          <p>
            Millions of people live alone — by choice, by circumstance, by the simple arithmetic of
            long lives and faraway children. Today, the time between{" "}
            <em className="text-charcoal">something happened</em> and{" "}
            <em className="text-charcoal">someone found out</em> can be minutes if you&rsquo;re
            lucky, or weeks if you&rsquo;re not.
          </p>
          <p>
            iEye exists to make sure it&rsquo;s always minutes or hours — never weeks.
          </p>
        </div>

        {/* Anonymized composites — witness, not leverage. Each resolves toward iEye. */}
        <div className="mt-10 space-y-6">
          <figure className="rounded-2xl border border-charcoal/10 bg-paper p-6 sm:p-7">
            <blockquote className="text-lg leading-relaxed text-charcoal-soft">
              A man in his thirties collapsed in his own kitchen on a weekday evening. He lived
              alone. No one was expecting to hear from him, so no one came.
            </blockquote>
            <figcaption className="mt-3 text-base font-medium text-charcoal">
              With iEye, the fall is felt the moment it happens — and help is on its way in minutes.
            </figcaption>
          </figure>

          <figure className="rounded-2xl border border-charcoal/10 bg-paper p-6 sm:p-7">
            <blockquote className="text-lg leading-relaxed text-charcoal-soft">
              An elderly woman lived alone after her husband passed; her children called on Sundays
              from abroad. One week a call went unanswered, then another, and the silence stretched
              on.
            </blockquote>
            <figcaption className="mt-3 text-base font-medium text-charcoal">
              With iEye, that silence reaches the people she chose within hours — not weeks.
            </figcaption>
          </figure>
        </div>

        <p className="mt-8 text-lg leading-relaxed text-charcoal-soft">
          Neither of them needed a miracle. They needed{" "}
          <strong className="font-semibold text-charcoal">someone to know, in time.</strong> That
          single thing — help arriving in time — is the whole of iEye.
        </p>
        <p className="mt-4 text-base text-charcoal-muted">
          Stories like these are anonymized composites. iEye can&rsquo;t promise to save everyone —
          no app can, and we will never pretend otherwise. What it <em>can</em> do is get help to
          you fast enough to save a life when a life can be saved, and make sure going silent never
          again means going unseen.
        </p>
      </div>
    </Section>
  );
}
