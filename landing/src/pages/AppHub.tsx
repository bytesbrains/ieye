import { Link } from "react-router-dom";
import { Wordmark } from "../components/Brand";
import { WaitlistCta } from "../components/WaitlistCta";
import { REPO_LINKS } from "../lib/repo";

// The app hub at /app: the honest browser-check placeholder + install links +
// the early-access waitlist. A browser CANNOT scan a home LAN (sandbox), so the
// browser check is framed as outside-in only ("what's visible from the internet")
// and marked coming soon; the real scan is the installable app.
const PLATFORMS = [
  { t: "macOS", note: "Desktop scan + live Wi-Fi check" },
  { t: "Windows", note: "Desktop scan" },
  { t: "Linux", note: "Desktop scan" },
  { t: "Android", note: "Mobile scan" },
];

export function AppHub() {
  const releases = `${REPO_LINKS.repo}/releases`;
  return (
    <div className="min-h-screen bg-paper">
      <header className="border-b border-charcoal/10">
        <div className="mx-auto flex max-w-4xl items-center justify-between px-5 py-3">
          <Link to="/" aria-label="iEye home">
            <Wordmark />
          </Link>
          <Link to="/" className="text-base text-charcoal-soft hover:text-charcoal">
            ← Home
          </Link>
        </div>
      </header>

      <main className="mx-auto max-w-4xl px-5 py-12">
        <h1 className="text-4xl font-semibold sm:text-5xl">Get iEye Secure</h1>
        <p className="mt-4 max-w-prose text-lg leading-relaxed text-charcoal-soft">
          Scan your home network for exposed cameras, open devices, and weak Wi-Fi. The full scan
          runs on your own device — install it below.
        </p>

        {/* Quick browser check — outside-in only (a browser can't reach your LAN). */}
        <section className="mt-10 rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7">
          <p className="text-sm font-semibold uppercase tracking-wide text-teal-deep">
            Quick check — from your browser
          </p>
          <h2 className="mt-2 text-2xl font-semibold">See what&rsquo;s visible from the internet</h2>
          <p className="mt-2 max-w-prose text-base leading-relaxed text-charcoal-soft">
            A browser can&rsquo;t look inside your home network — that&rsquo;s exactly the protection
            the app exists for. But we can show you what&rsquo;s visible on your connection from the
            outside. <span className="font-medium text-charcoal">Coming soon.</span>
          </p>
        </section>

        {/* Install the app — the real scan. Binaries on GitHub Releases. */}
        <section className="mt-8">
          <h2 className="text-2xl font-semibold">Install the app — the full home scan</h2>
          <div className="mt-4 grid gap-4 sm:grid-cols-2">
            {PLATFORMS.map((p) => (
              <div
                key={p.t}
                className="flex items-center justify-between rounded-2xl border-2 border-charcoal/10 bg-paper p-5"
              >
                <div>
                  <p className="text-lg font-semibold text-charcoal">{p.t}</p>
                  <p className="text-sm text-charcoal-soft">{p.note}</p>
                </div>
                <a
                  target="_blank"
                  rel="noopener noreferrer"
                  href={releases}
                  className="btn btn-secondary text-sm"
                >
                  Downloads
                </a>
              </div>
            ))}
          </div>
          <p className="mt-3 text-sm text-charcoal-muted">
            Builds are published on{" "}
            <a
              target="_blank"
              rel="noopener noreferrer"
              href={releases}
              className="underline hover:text-charcoal"
            >
              GitHub Releases
            </a>
            . iOS is App Store only — get on the list below and we&rsquo;ll tell you the moment it
            lands (TestFlight first).
          </p>
        </section>

        {/* iOS / notify — the early-access waitlist. */}
        <section id="waitlist" className="mt-10 rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7">
          <h2 className="text-2xl font-semibold">On iPhone? Get early access.</h2>
          <p className="mt-2 max-w-prose text-base text-charcoal-soft">
            iEye isn&rsquo;t on the App Store yet. Sign in and we&rsquo;ll tell you the moment it is —
            no form to fill in.
          </p>
          <div className="mt-6 max-w-md">
            <WaitlistCta />
          </div>
        </section>
      </main>
    </div>
  );
}
