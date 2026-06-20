import { Section } from "./Section";
import { WaitlistForm } from "./WaitlistForm";
import { SkillsForm } from "./SkillsForm";

export function Contribute() {
  return (
    <Section id="contribute" labelledBy="contribute-heading">
      <div className="container-wide">
        <div className="container-prose px-0">
          <p className="mb-3 text-sm font-semibold uppercase tracking-wide text-teal-deep">
            Ways to help
          </p>
          <h2 id="contribute-heading" className="text-3xl font-semibold sm:text-4xl">
            iEye is a public good. It only stays alive if people keep it running.
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">
            It&rsquo;s free, open, and meant to outlive any company. Keeping a safety net running has
            a real cost, even when no one profits from it. If it matters to you, you can help in
            whatever way you have.
          </p>
        </div>

        {/* Phase 1: NO live payment / no money UI / no crypto address.
            Contributions are framed as coming soon (Phase 2, Legal-gated #39). */}
        <div className="mt-12 grid gap-8 lg:grid-cols-2">
          {/* Waitlist — register interest / notify me */}
          <div id="waitlist" className="rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7 sm:p-8">
            <h3 className="text-2xl font-semibold text-charcoal">Want it for someone you love?</h3>
            <p className="mt-2 text-base text-charcoal-soft">
              iEye isn&rsquo;t open to the public yet. Leave your email and we&rsquo;ll tell you the
              moment it is.
            </p>
            <div className="mt-6">
              <WaitlistForm />
            </div>
          </div>

          {/* Contribute your skills */}
          <div className="rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7 sm:p-8">
            <h3 className="text-2xl font-semibold text-charcoal">Help build iEye</h3>
            <p className="mt-2 text-base text-charcoal-soft">
              Give what you know — specs, testing, code, design, translation. iEye is built in the
              open by people who care.
            </p>
            <div className="mt-6">
              <SkillsForm />
            </div>
          </div>
        </div>

        {/* Money: coming soon, explicitly no live payment yet. */}
        <div className="container-prose mt-10 rounded-2xl border-2 border-dashed border-charcoal/20 bg-paper px-6 py-7 text-center">
          <p className="text-sm font-semibold uppercase tracking-wide text-charcoal-muted">
            Coming soon
          </p>
          <p className="mt-2 text-lg font-semibold text-charcoal">
            Contributing money isn&rsquo;t open yet.
          </p>
          <p className="mx-auto mt-2 max-w-prose text-base text-charcoal-soft">
            When it opens, you&rsquo;ll be able to <strong>contribute</strong> by card, bank, or
            crypto — every contribution shown on a public ledger you can check yourself. Until then,
            the most valuable thing you can give is your skills or a heads-up that you&rsquo;re
            interested.
          </p>
          <p className="mx-auto mt-4 max-w-prose text-sm text-charcoal-muted">
            iEye is received by BytesBrains Pte Ltd (Singapore), a company, not a charity —
            contributions support the project and are <strong>not</strong> tax-deductible. We say so
            because honesty is the whole point.
          </p>
        </div>
      </div>
    </Section>
  );
}
