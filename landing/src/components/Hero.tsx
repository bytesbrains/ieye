export function Hero() {
  return (
    <section
      id="top"
      aria-labelledby="hero-heading"
      className="relative overflow-hidden px-5 pb-16 pt-12 sm:pt-16"
    >
      {/* soft twilight wash behind the hero — calm, never alarm */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[480px] bg-gradient-to-b from-teal/15 via-paper to-paper"
      />
      <div className="mx-auto grid max-w-5xl items-center gap-10 md:grid-cols-2 md:gap-12">
        <div className="order-2 md:order-1">
          <h1
            id="hero-heading"
            className="text-4xl font-semibold leading-[1.1] sm:text-5xl md:text-[3.4rem]"
          >
            iEye gets help to you in time.
          </h1>
          <p className="mt-5 max-w-prose text-lg leading-relaxed text-charcoal-soft sm:text-xl">
            If you fall, crash, or your heart goes wrong, iEye notices in seconds and brings help in{" "}
            <strong className="font-semibold text-charcoal">minutes</strong> — fast enough to save a
            life when a life can be saved. And if you simply go silent, the people you chose are
            told, so{" "}
            <strong className="font-semibold text-charcoal">no one is ever left undiscovered.</strong>
          </p>

          {/* quiet floor line — secondary, smaller, never carries the hero */}
          <p className="mt-4 font-serif text-lg italic text-charcoal-muted">
            You will not go unseen.
          </p>

          <div className="mt-8 flex flex-wrap items-center gap-4">
            <a href="#how-it-works" className="btn btn-primary">
              See how it works
            </a>
            <a href="#contribute" className="btn btn-secondary">
              Ways to contribute
            </a>
          </div>

          <p className="mt-6 text-sm text-charcoal-muted">
            A free, open public good — not a business. iEye is{" "}
            <span className="font-medium text-charcoal-soft">not a substitute for emergency services.</span>
          </p>
        </div>

        <div className="order-1 md:order-2">
          <figure className="relative mx-auto max-w-md">
            <img
              src="/ieye-logo-scene.png"
              width={640}
              height={640}
              alt="A lighthouse standing on a calm sea at twilight, casting one warm beam of light out over the water — a beacon keeping watch."
              className="w-full rounded-2xl shadow-sm"
              // Lowercase HTML attribute (typed via src/html-attrs.d.ts): React 18
              // drops + warns on the camelCase fetchPriority prop, so we set the
              // attribute React 18 actually emits — the LCP hint reaches the DOM.
              fetchpriority="high"
            />
          </figure>
        </div>
      </div>
    </section>
  );
}
