import { useMemo } from "react";
import { Link } from "react-router-dom";
import { Wordmark } from "../components/Brand";
import { WaitlistCta } from "../components/WaitlistCta";
import { ExposureCheck } from "../components/ExposureCheck";
import { REPO_LINKS } from "../lib/repo";

// The app hub at /app: the outside-in browser teaser + honest, per-platform
// downloads. Windows/Linux/Android can be distributed freely; macOS + iPhone need
// a signed/notarized build (Apple Developer Program), so they read "Available
// soon" — and we nudge people to run the scan on any old Windows/Linux laptop or
// Android phone they already have, which is the easy path today.

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

// Available now — distributable without Apple signing.
const AVAILABLE: { os: "Windows" | "Linux" | "Android"; note: string; hint: string }[] = [
  { os: "Windows", note: "Desktop scan", hint: "Windows may warn “unknown publisher” — choose More info → Run anyway." },
  { os: "Linux", note: "Desktop scan", hint: "AppImage — make it executable, then run." },
  { os: "Android", note: "Mobile scan (APK)", hint: "Allow the install when your browser asks." },
];

// Coming soon — Apple platforms need a signed + notarized build.
const SOON: { os: "macOS" | "iPhone"; note: string; match: OS }[] = [
  { os: "macOS", note: "Signed build coming soon", match: "macOS" },
  { os: "iPhone", note: "Coming to the App Store", match: "iOS" },
];

export function AppHub() {
  const os = useMemo(detectOS, []);
  const releases = `${REPO_LINKS.repo}/releases`;
  const onApple = os === "macOS" || os === "iOS";

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
          runs on your own device. Take a quick look from your browser first, then run the real scan
          from any computer or phone on your home Wi-Fi.
        </p>

        {/* Outside-in browser teaser. bg-paper so the teal overline clears WCAG AA. */}
        <section className="mt-10 rounded-2xl border-2 border-charcoal/10 bg-paper p-7">
          <p className="text-sm font-semibold uppercase tracking-wide text-teal-deep">
            Quick check — from your browser
          </p>
          <h2 className="mt-2 text-2xl font-semibold">See what&rsquo;s visible from the internet</h2>
          <div className="mt-4">
            <ExposureCheck />
          </div>
        </section>

        {/* Install — the real scan. */}
        <section id="install" className="mt-10 scroll-mt-20">
          <h2 className="text-2xl font-semibold">Run the scan on any of these</h2>
          {os && !onApple && (
            <p className="mt-1 text-base text-charcoal-soft">
              Looks like you&rsquo;re on <strong className="text-charcoal">{os}</strong> — grab that one.
            </p>
          )}

          <div className="mt-4 grid gap-4 sm:grid-cols-3">
            {AVAILABLE.map((p) => {
              const recommended = p.os === os;
              return (
                <div
                  key={p.os}
                  className={`rounded-2xl border-2 p-5 ${
                    recommended ? "border-amber bg-amber/5" : "border-charcoal/10 bg-paper"
                  }`}
                >
                  <p className="text-lg font-semibold text-charcoal">
                    {p.os}
                    {recommended && (
                      <span className="ml-2 inline-block rounded-full bg-charcoal px-2 py-0.5 align-middle text-[10px] font-bold uppercase tracking-wide text-paper">
                        For you
                      </span>
                    )}
                  </p>
                  <p className="text-sm text-charcoal-soft">{p.note}</p>
                  <a
                    target="_blank"
                    rel="noopener noreferrer"
                    href={releases}
                    className="btn btn-secondary mt-3 text-sm"
                  >
                    Download
                  </a>
                  <p className="mt-2 text-xs leading-relaxed text-charcoal-muted">{p.hint}</p>
                </div>
              );
            })}
          </div>
          <p className="mt-3 text-sm text-charcoal-muted">
            Builds publish to{" "}
            <a target="_blank" rel="noopener noreferrer" href={releases} className="underline hover:text-charcoal">
              GitHub Releases
            </a>{" "}
            as they land.
          </p>

          {/* Old-device nudge — emphasized when the visitor is on a Mac/iPhone. */}
          <div
            className={`mt-8 rounded-2xl border-2 p-6 ${
              onApple ? "border-amber bg-amber/5" : "border-charcoal/10 bg-paper-dim"
            }`}
          >
            <p className="text-lg font-semibold text-charcoal">
              {onApple
                ? "On a Mac or iPhone? Here’s the easy path today."
                : "No spare computer? You probably already have one."}
            </p>
            <p className="mt-2 max-w-prose text-base leading-relaxed text-charcoal-soft">
              The Mac and iPhone apps are coming soon. In the meantime, almost everyone has an old
              Windows or Linux laptop — or an old Android phone — sitting in a drawer. Dust one off,
              put it on your home Wi-Fi, and run the scan there. It takes a couple of minutes and
              works exactly the same.
            </p>
          </div>

          {/* Coming soon — Apple platforms. */}
          <h3 className="mt-8 text-base font-semibold text-charcoal">Coming soon</h3>
          <div className="mt-3 grid gap-4 sm:grid-cols-2">
            {SOON.map((p) => (
              <div
                key={p.os}
                className={`flex items-center justify-between rounded-2xl border-2 p-5 ${
                  p.match === os ? "border-amber bg-amber/5" : "border-charcoal/10 bg-paper"
                }`}
              >
                <div>
                  <p className="text-lg font-semibold text-charcoal">{p.os}</p>
                  <p className="text-sm text-charcoal-soft">{p.note}</p>
                </div>
                <span className="rounded-full border border-charcoal/25 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-charcoal-soft">
                  Available soon
                </span>
              </div>
            ))}
          </div>
        </section>

        {/* Notify me when the Apple apps land — the early-access waitlist. */}
        <section id="waitlist" className="mt-10 scroll-mt-20 rounded-2xl border-2 border-charcoal/10 bg-paper-dim p-7">
          <h2 className="text-2xl font-semibold">Want the Mac or iPhone app?</h2>
          <p className="mt-2 max-w-prose text-base text-charcoal-soft">
            They&rsquo;re coming soon. Sign in and we&rsquo;ll tell you the moment they land — no form
            to fill in.
          </p>
          <div className="mt-6 max-w-md">
            <WaitlistCta />
          </div>
        </section>
      </main>
    </div>
  );
}
