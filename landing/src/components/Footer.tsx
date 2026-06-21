import { Link } from "react-router-dom";
import { Wordmark } from "./Brand";
import { HonestyLine } from "./HonestyLine";
import { LEGAL } from "../lib/legalCopy";

export function Footer() {
  return (
    <footer className="border-t border-charcoal/10 bg-paper">
      {/* Join / belonging beat */}
      <div className="section">
        <div className="container-prose text-center">
          <h2 className="text-3xl font-semibold sm:text-4xl">
            Help should reach people in time. Too often it doesn&rsquo;t.
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">
            iEye only stays alive if people who agree with that keep it running. Give your skills,
            lend a hand, or just tell the person you&rsquo;re worried about. If it helps even one
            person get help in time, it has done everything we hoped.
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-4">
            <a href="#waitlist" className="btn btn-primary">
              Notify me when it opens
            </a>
            <a href="#contribute" className="btn btn-secondary">
              Help build iEye
            </a>
          </div>
        </div>
      </div>

      <div className="border-t border-charcoal/10">
        <div className="mx-auto max-w-5xl px-5 py-10">
          <div className="flex flex-col items-start justify-between gap-6 sm:flex-row sm:items-center">
            <Wordmark />
            <nav aria-label="Footer" className="flex flex-wrap gap-x-6 gap-y-2 text-base">
              <a href="#how-it-works" className="text-charcoal-soft hover:text-charcoal">
                How it works
              </a>
              <a href="#trust" className="text-charcoal-soft hover:text-charcoal">
                Trust &amp; privacy
              </a>
              <a href="#contribute" className="text-charcoal-soft hover:text-charcoal">
                Ways to help
              </a>
              <a href="#transparency" className="text-charcoal-soft hover:text-charcoal">
                Transparency
              </a>
              <Link to="/privacy" className="text-charcoal-soft hover:text-charcoal">
                Privacy
              </Link>
              <Link to="/terms" className="text-charcoal-soft hover:text-charcoal">
                Terms
              </Link>
            </nav>
          </div>

          <div className="mt-8 max-w-prose space-y-3">
            <HonestyLine />
            {/* Canonical contribution disclaimer — single source of truth (lib/legalCopy).
                Was a near-duplicate paraphrase; reconciled per PR #50 so footer + CTA
                render identical, Legal-approved wording. */}
            <p className="text-sm text-charcoal-muted">{LEGAL.contributionDisclaimerShort}</p>
            <p className="text-sm text-charcoal-muted">
              iEye is a free, open public good, built on the Maktub Protocol. There is no iEye token
              and no investment offer.
            </p>
            <p className="text-sm text-charcoal-faint">
              &copy; {new Date().getFullYear()} iEye. A welfare app for people who live alone.
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
}
