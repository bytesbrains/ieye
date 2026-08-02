import { Section } from "./Section";

// The sponsoring company. iEye (the app) is free and open-source; BytesBrains is
// the company behind it, offering paid help to secure a home or premises — and
// that revenue is what funds the watch-over mission. This replaces the old
// donation model (which framed iEye as "not a business" — no longer true).
export function BytesBrains() {
  return (
    <Section id="bytesbrains" labelledBy="bytesbrains-heading" className="bg-paper-dim">
      <div className="container-prose">
        <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-teal-deep">
          BytesBrains — the company behind iEye
        </p>
        <h2 id="bytesbrains-heading" className="text-3xl font-semibold sm:text-4xl">
          Found something serious? We&rsquo;ll help you secure it.
        </h2>
        <div className="mt-5 space-y-5 text-lg leading-relaxed text-charcoal-soft">
          <p>
            Some fixes need hands-on help — locking down a router you can&rsquo;t get into,
            separating your cameras from your phones, checking a whole property. That&rsquo;s what
            BytesBrains does: a professional audit and remediation to secure your premises, so your
            devices work for you and no one else.
          </p>
          <p>
            The app stays free and open-source. BytesBrains is how iEye pays for itself —{" "}
            <strong className="font-semibold text-charcoal">every audit funds the watch-over
            mission</strong>, so the guardian that keeps watch over people who live alone keeps
            getting better.
          </p>
        </div>

        <div className="mt-8 flex flex-wrap items-center gap-4">
          <a href="mailto:contact@bytesbrains.com" className="btn btn-primary">
            Secure my home
          </a>
          <a
            href="mailto:contact@bytesbrains.com?subject=iEye%20—%20secure%20my%20premises"
            className="text-base text-charcoal-soft underline hover:text-charcoal"
          >
            contact@bytesbrains.com
          </a>
        </div>
      </div>
    </Section>
  );
}
