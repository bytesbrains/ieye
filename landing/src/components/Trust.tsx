import { Section } from "./Section";

export function Trust() {
  return (
    <Section id="trust" labelledBy="trust-heading" className="bg-charcoal text-paper">
      <div className="container-prose">
        <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-amber-warm">
          Trust &amp; privacy
        </p>
        <h2 id="trust-heading" className="text-3xl font-semibold text-paper sm:text-4xl">
          We watch <span className="text-amber-warm">over</span> you. We never watch{" "}
          <span className="text-amber-warm">you.</span>
        </h2>

        <div className="mt-6 space-y-5 text-lg leading-relaxed text-paper/85">
          <p>
            iEye is the privacy project, so it&rsquo;s built to know as little about you as possible.
            It doesn&rsquo;t record where you go, when you sleep, or what you do — it reads one thing
            only: <em className="text-paper">a sign of life, or a sign that something&rsquo;s wrong.</em>
          </p>
          <p>
            That signal stays on your phone. Nothing about your day is stored on a server or shared
            with anyone.
          </p>
          <p>
            It&rsquo;s the difference between a lighthouse and a camera — a beam that brings help{" "}
            <strong className="font-semibold text-paper">in</strong>, not a lens pointed{" "}
            <strong className="font-semibold text-paper">at</strong> you. We built it that way on
            purpose, so the promise and the privacy tell the same story.
          </p>
        </div>

        <ul className="mt-8 grid gap-4 sm:grid-cols-3" role="list">
          {[
            { t: "Privacy by architecture", d: "Not by policy. Liveness is one bit, read at the edge." },
            { t: "Stays on your phone", d: "No location traces, sleep logs, or unlock timelines synced." },
            { t: "Open to verify", d: "Built in the open — you can read the code, not just trust us." },
          ].map((item) => (
            <li
              key={item.t}
              className="rounded-xl border border-paper/15 bg-paper/5 p-5"
            >
              <p className="font-semibold text-paper">{item.t}</p>
              <p className="mt-1.5 text-base text-paper/75">{item.d}</p>
            </li>
          ))}
        </ul>
      </div>
    </Section>
  );
}
