import { Link } from "react-router-dom";
import { Section } from "./Section";
import { WaitlistCta } from "./WaitlistCta";
import { LEGAL } from "../lib/legalCopy";

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
          {/* Waitlist — register interest via Google sign-in (name + email
              captured from the profile; written to the user's own doc). */}
          <div id="waitlist" className="rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7 sm:p-8">
            <h3 className="text-2xl font-semibold text-charcoal">Want it for someone you love?</h3>
            <p className="mt-2 text-base text-charcoal-soft">
              iEye isn&rsquo;t open to the public yet. Sign in with Google and we&rsquo;ll tell you the
              moment it is — no form to fill in.
            </p>
            <div className="mt-6">
              <WaitlistCta />
            </div>
          </div>

          {/* Contribute your skills — sign in, then the contributor-request
              form on /account (one source of truth, writes contributorRequests). */}
          <div className="rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7 sm:p-8">
            <h3 className="text-2xl font-semibold text-charcoal">Help build iEye</h3>
            <p className="mt-2 text-base text-charcoal-soft">
              Give what you know — specs, testing, code, design, translation. iEye is built in the
              open by people who care.
            </p>
            <div className="mt-6">
              <Link to="/account" className="btn btn-primary w-full">
                {/* Google "G" glyph */}
                <svg className="h-5 w-5" viewBox="0 0 24 24" aria-hidden="true">
                  <path
                    fill="#EA4335"
                    d="M12 10.2v3.9h5.5c-.24 1.4-1.66 4.1-5.5 4.1a6.2 6.2 0 0 1 0-12.4c1.94 0 3.25.82 4 1.53l2.72-2.62C17.06 2.9 14.76 2 12 2a10 10 0 0 0 0 20c5.77 0 9.6-4.06 9.6-9.78 0-.66-.07-1.16-.16-1.66H12z"
                  />
                </svg>
                Sign in to offer your skills
              </Link>
              <p className="mt-4 text-sm text-charcoal-muted">
                You&rsquo;ll sign in with Google, then tell us how you can help on your account page.
              </p>
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
          {/* Canonical contribution disclaimer — single source of truth (lib/legalCopy). */}
          <p className="mx-auto mt-4 max-w-prose text-sm text-charcoal-muted">
            {LEGAL.contributionDisclaimerShort}
          </p>
        </div>
      </div>
    </Section>
  );
}
