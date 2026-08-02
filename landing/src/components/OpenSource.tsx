import { Section } from "./Section";
import { WaysToContribute } from "./WaysToContribute";

// Open-source (code) contribution only — the donation model has been retired.
// A privacy tool you can't read is just a promise; being open IS the trust moat.
export function OpenSource() {
  return (
    <Section id="open-source" labelledBy="opensource-heading">
      <div className="container-wide">
        <div className="container-prose px-0">
          <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-teal-deep">
            Open source
          </p>
          <h2 id="opensource-heading" className="text-3xl font-semibold sm:text-4xl">
            iEye is built in the open.
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">
            A privacy tool you can&rsquo;t inspect is just a promise. iEye is free and open-source
            (MIT) — the scanner, the app, the code that keeps your data on your phone. Read it,
            question it, or help build it. The code, issues, and roadmap all live on GitHub.
          </p>
        </div>

        <div className="mt-12">
          <WaysToContribute title="Ways to contribute" />
        </div>
      </div>
    </Section>
  );
}
