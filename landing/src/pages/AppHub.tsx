import { useMemo } from "react";
import { Link } from "react-router-dom";
import { Wordmark } from "../components/Brand";
import { WaitlistCta } from "../components/WaitlistCta";
import { ExposureCheck } from "../components/ExposureCheck";
import { REPO_LINKS } from "../lib/repo";

// The app hub at /app: the outside-in browser teaser (ExposureCheck) + install
// links + the early-access waitlist. A browser can't scan a home LAN, so the
// teaser is outside-in only; the real scan is the installable app.

type OS = "macOS" | "Windows" | "Linux" | "Android" | "iOS" | null;

function detectOS(): OS {
  if (typeof navigator === "undefined") return null;
  const ua = navigator.userAgent;
  if (/iPhone|iPad|iPod/.test(ua)) return "iOS";
  if (/Android/.test(ua)) return "Android";
  if (/Macintosh|Mac OS X/.test(ua)) return "macOS";
  if (/Windows/.test(ua)) return "Windows";
  if (/Linux/.test(ua)) return "Linux";
  return null;
}

const PLATFORMS: { os: Exclude<OS, "iOS" | null>; note: string }[] = [
  { os: "macOS", note: "Desktop scan + live Wi-Fi check" },
  { os: "Windows", note: "Desktop scan" },
  { os: "Linux", note: "Desktop scan" },
  { os: "Android", note: "Mobile scan" },
];

export function AppHub() {
  const os = useMemo(detectOS, []);
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
          runs on your own device — install it below. Or take a quick look from your browser first.
        </p>

        {/* Outside-in browser teaser — interactive, honest, free. bg-paper (not
            paper-dim) so the teal overline clears WCAG AA contrast. */}
        <section className="mt-10 rounded-2xl border-2 border-charcoal/10 bg-paper p-7">
          <p className="text-sm font-semibold uppercase tracking-wide text-teal-deep">
            Quick check — from your browser
          </p>
          <h2 className="mt-2 text-2xl font-semibold">See what&rsquo;s visible from the internet</h2>
          <div className="mt-4">
            <ExposureCheck />
          </div>
        </section>

        {/* Install the app — the real scan. Binaries on GitHub Releases. */}
        <section id="install" className="mt-10 scroll-mt-20">
          <h2 className="text-2xl font-semibold">Install the app — the full home scan</h2>
          {os && os !== "iOS" && (
            <p className="mt-1 text-base text-charcoal-soft">
              Looks like you&rsquo;re on <strong className="text-charcoal">{os}</strong> — grab that one.
            </p>
          )}
          <div className="mt-4 grid gap-4 sm:grid-cols-2">
            {PLATFORMS.map((p) => {
              const recommended = p.os === os;
              return (
                <div
                  key={p.os}
                  className={`flex items-center justify-between rounded-2xl border-2 p-5 ${
                    recommended ? "border-amber bg-amber/5" : "border-charcoal/10 bg-paper"
                  }`}
                >
                  <div>
                    <p className="text-lg font-semibold text-charcoal">
                      {p.os}
                      {recommended && (
                        <span className="ml-2 inline-block rounded-full bg-charcoal px-2 py-0.5 align-middle text-[10px] font-bold uppercase tracking-wide text-paper">
                          For you
                        </span>
                      )}
                    </p>
                    <p className="text-sm text-charcoal-soft">{p.note}</p>
                  </div>
                  <a
                    target="_blank"
                    rel="noopener noreferrer"
                    href={releases}
                    className="btn btn-secondary text-sm"
                  >
                    Get {p.os}
                  </a>
                </div>
              );
            })}
          </div>
          <p className="mt-3 text-sm text-charcoal-muted">
            First builds are on the way — published to{" "}
            <a
              target="_blank"
              rel="noopener noreferrer"
              href={releases}
              className="underline hover:text-charcoal"
            >
              GitHub Releases
            </a>{" "}
            as they land. iOS is App Store only — get on the list below.
          </p>
        </section>

        {/* iOS / notify — the early-access waitlist. */}
        <section
          id="waitlist"
          className={`mt-10 scroll-mt-20 rounded-2xl border-2 p-7 ${
            os === "iOS" ? "border-amber bg-amber/5" : "border-charcoal/10 bg-paper-dim"
          }`}
        >
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
