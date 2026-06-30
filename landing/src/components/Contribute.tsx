import { Link } from "react-router-dom";
import { Section } from "./Section";
import { WaitlistCta } from "./WaitlistCta";
import { WaysToContribute } from "./WaysToContribute";
import { LEGAL } from "../lib/legalCopy";
import { FIAT_CONTRIB_ENABLED } from "../lib/flags";
import { REPO_LINKS } from "../lib/repo";

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

          {/* Help build iEye — the repo is public (#1), so point straight at
              GitHub. Detailed paths are in the WaysToContribute block below. */}
          <div className="rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7 sm:p-8">
            <h3 className="text-2xl font-semibold text-charcoal">Help build iEye</h3>
            <p className="mt-2 text-base text-charcoal-soft">
              iEye is free and open source, built in public. The code, the issues, and the roadmap
              all live on GitHub — no permission needed to jump in.
            </p>
            <div className="mt-6 flex flex-wrap gap-3">
              <a
                target="_blank"
                rel="noopener noreferrer"
                href={REPO_LINKS.repo}
                className="btn btn-primary"
              >
                View on GitHub
              </a>
              <a
                target="_blank"
                rel="noopener noreferrer"
                href={REPO_LINKS.discussions}
                className="btn btn-secondary"
              >
                Join the discussion
              </a>
            </div>
          </div>
        </div>

        {/* Detailed, concrete ways to contribute now that the repo is public. */}
        <div className="mt-12">
          <WaysToContribute title="Ways to contribute" />
        </div>

        {/* Money panel. Two states, switched by the FIAT_CONTRIB_ENABLED flag
            (default OFF, until Legal #39 clears + a Stripe account exists):
              - OFF: funder/sponsor INTEREST capture — no payment, no amount, no
                     crypto address. Calm btn-secondary, never a loud "donate".
              - ON:  an active "contribute by card" CTA into the signed-in flow
                     on /account (the amount picker + point-of-payment disclaimer
                     live there). The actual checkout is Stripe-hosted. */}
        {FIAT_CONTRIB_ENABLED ? (
          <div className="container-prose mt-10 rounded-2xl border-2 border-charcoal/10 bg-paper-dim px-6 py-7 text-center">
            <p className="text-sm font-semibold uppercase tracking-wide text-teal-deep">
              Contribute
            </p>
            <p className="mt-2 text-lg font-semibold text-charcoal">Help keep iEye running.</p>
            <p className="mx-auto mt-2 max-w-prose text-base text-charcoal-soft">
              A one-time contribution by card. iEye is free and open — your contribution funds the
              infrastructure, development, and work that keeps the safety net alive. Every
              contribution appears on a public ledger you can check yourself.
            </p>
            <div className="mt-6">
              <Link to="/account" className="btn btn-primary">
                Contribute by card
              </Link>
            </div>
            <p className="mx-auto mt-4 max-w-prose text-sm text-charcoal-muted">
              {LEGAL.contributionDisclaimerShort}
            </p>
          </div>
        ) : (
          <div className="container-prose mt-10 rounded-2xl border-2 border-dashed border-charcoal/20 bg-paper px-6 py-7 text-center">
            <p className="text-sm font-semibold uppercase tracking-wide text-charcoal-muted">
              Why this needs support
            </p>
            <p className="mt-2 text-lg font-semibold text-charcoal">Help us build the senses.</p>
            <p className="mx-auto mt-2 max-w-prose text-base text-charcoal-soft">
              iEye is free and open, and always will be — but making the sign of life dependable
              costs real money: the sensors, the learning, and the harness that rehearses
              emergencies so we never test them on a real person. We can&rsquo;t take contributions
              live just yet, so we&rsquo;re starting by gathering the people and partners who want to
              help fund this. Register your interest, and you&rsquo;ll be the first to know the
              moment it opens.
            </p>
            <div className="mt-6">
              <Link to="/account" className="btn btn-secondary">
                Register funder interest
              </Link>
            </div>
            {/* Same honest "coming soon" promise as before — money isn't open yet. */}
            <p className="mx-auto mt-4 max-w-prose text-sm text-charcoal-soft">
              Contributing money isn&rsquo;t open yet. When it opens, you&rsquo;ll be able to help by
              card, bank, or crypto — every contribution on a public ledger you can check yourself.
            </p>
            {/* Canonical contribution disclaimer — single source of truth (lib/legalCopy). */}
            <p className="mx-auto mt-4 max-w-prose text-sm text-charcoal-muted">
              {LEGAL.contributionDisclaimerShort}
            </p>
          </div>
        )}
      </div>
    </Section>
  );
}
