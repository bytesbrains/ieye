import { Link } from "react-router-dom";

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
            A guardian for your home — and everyone in it.
          </h1>
          <p className="mt-5 max-w-prose text-lg leading-relaxed text-charcoal-soft sm:text-xl">
            <strong className="font-semibold text-charcoal">iEye Secure</strong> scans your home
            network and shows you what a stranger could reach — exposed cameras, open devices, weak
            Wi-Fi. <strong className="font-semibold text-charcoal">iEye Watch</strong> makes sure
            that if someone who lives alone goes quiet, the people they chose are told.
          </p>

          {/* quiet floor line — secondary, smaller, never carries the hero */}
          <p className="mt-4 font-serif text-lg italic text-charcoal-muted">
            Watches over you, never watches you. You will not go unseen.
          </p>

          <div className="mt-8 flex flex-wrap items-center gap-4">
            <Link to="/app" className="btn btn-primary">
              Scan your home
            </Link>
            <a href="#how-it-works" className="btn btn-secondary">
              How it works
            </a>
          </div>

          <p className="mt-6 text-sm text-charcoal-muted">
            The app is <span className="font-medium text-charcoal-soft">free and open-source.</span>{" "}
            Professional help to secure your home comes from{" "}
            <span className="font-medium text-charcoal-soft">BytesBrains</span> — and funds the
            watch-over mission.
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
