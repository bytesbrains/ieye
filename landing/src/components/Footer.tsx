import { Link } from "react-router-dom";
import { Wordmark } from "./Brand";
import { HonestyLine } from "./HonestyLine";

export function Footer() {
  return (
    <footer className="border-t border-charcoal/10 bg-paper">
      {/* Closing beat — one guardian, two threats. */}
      <div className="section">
        <div className="container-prose text-center">
          <h2 className="text-3xl font-semibold sm:text-4xl">
            Secure your home. Watch over the people in it.
          </h2>
          <p className="mt-5 text-lg leading-relaxed text-charcoal-soft">
            iEye is one guardian for both — the app is free and open-source, and BytesBrains is here
            when you want a person to make your home safe.
          </p>
          <div className="mt-8 flex flex-wrap justify-center gap-4">
            <Link to="/app" className="btn btn-primary">
              Scan your home
            </Link>
            <a href="mailto:contact@bytesbrains.com" className="btn btn-secondary">
              Talk to BytesBrains
            </a>
          </div>
        </div>
      </div>

      <div className="border-t border-charcoal/10">
        <div className="mx-auto max-w-5xl px-5 py-10">
          <div className="flex flex-col items-start justify-between gap-6 sm:flex-row sm:items-center">
            <Wordmark />
            <nav aria-label="Footer" className="flex flex-wrap gap-x-6 gap-y-2 text-base">
              <a href="#secure" className="text-charcoal-soft hover:text-charcoal">
                iEye Secure
              </a>
              <a href="#how-it-works" className="text-charcoal-soft hover:text-charcoal">
                How it works
              </a>
              <a href="#trust" className="text-charcoal-soft hover:text-charcoal">
                Trust &amp; privacy
              </a>
              <a href="#bytesbrains" className="text-charcoal-soft hover:text-charcoal">
                BytesBrains
              </a>
              <a href="#open-source" className="text-charcoal-soft hover:text-charcoal">
                Open source
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
            <p className="text-sm text-charcoal-muted">
              iEye is free and open-source (MIT), built on the Maktub Protocol. Professional help to
              secure your premises is provided by BytesBrains, the company behind iEye. There is no
              iEye token and no investment offer.
            </p>
            <p className="text-sm text-charcoal-muted">
              &copy; {new Date().getFullYear()} iEye · BytesBrains.
            </p>
          </div>
        </div>
      </div>
    </footer>
  );
}
