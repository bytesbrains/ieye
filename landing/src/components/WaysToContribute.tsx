import { REPO_LINKS } from "../lib/repo";

// Concrete ways to help build iEye, now that the repo is public. Presentational
// only (external links + copy, no Firebase), so it's shared by the public
// landing AND the signed-in account dashboard.

interface Way {
  title: string;
  body: string;
  href: string;
  cta: string;
}

const WAYS: Way[] = [
  {
    title: "Join the discussion",
    body: "Shape where iEye goes, ask questions, and float ideas before they become work.",
    href: REPO_LINKS.discussions,
    cta: "Open Discussions",
  },
  {
    title: "Report or pick up an issue",
    body: "Found a bug or want a feature? Open an issue — or grab a “good first issue” to get started.",
    href: REPO_LINKS.goodFirstIssues,
    cta: "Browse issues",
  },
  {
    title: "Open a pull request",
    body: "Fixes, features, refactors. Read the contributor guide first — one focused change, with the gates green.",
    href: REPO_LINKS.contributing,
    cta: "Read CONTRIBUTING",
  },
  {
    title: "Write tests",
    body: "Help grow the Flutter, Firestore-rules, and Playwright e2e suites. For a safety app, coverage is lives-in-time insurance.",
    href: REPO_LINKS.repo,
    cta: "See the code",
  },
  {
    title: "Build the SDKs & device support",
    body: "The Maktub Protocol TypeScript SDK, the Flutter app, and new senses — home mesh (PIR, kettle, Wi-Fi) and wearables.",
    href: REPO_LINKS.issues,
    cta: "Find SDK/device work",
  },
  {
    title: "Docs & translations",
    body: "Make iEye clear, and reachable India-first — Hindi and beyond, so it helps the people it’s for.",
    href: REPO_LINKS.repo,
    cta: "Improve the docs",
  },
];

// Open external GitHub links in a new tab, safely.
const EXT = { target: "_blank", rel: "noopener noreferrer" } as const;

export function WaysToContribute({ title }: { title?: string }) {
  return (
    <div>
      {title && <h3 className="text-2xl font-semibold text-charcoal">{title}</h3>}
      <p className="mt-2 max-w-prose text-base text-charcoal-soft">
        iEye is <strong>free and open source</strong> (MIT), built in the open on GitHub — anyone can
        read the code, question it, and help make it better. You don&rsquo;t need permission to start.
      </p>

      <ul role="list" className="mt-6 grid gap-4 sm:grid-cols-2">
        {WAYS.map((w) => (
          <li
            key={w.title}
            className="rounded-2xl border-2 border-charcoal/10 bg-paper p-5"
          >
            <h4 className="text-base font-semibold text-charcoal">{w.title}</h4>
            <p className="mt-1.5 text-sm leading-relaxed text-charcoal-soft">{w.body}</p>
            <a
              {...EXT}
              href={w.href}
              className="mt-3 inline-block text-sm font-semibold text-teal-deep underline decoration-teal/40 underline-offset-4 hover:text-teal hover:decoration-teal"
            >
              {w.cta} →
            </a>
          </li>
        ))}
      </ul>

      <div className="mt-6 flex flex-wrap items-center gap-4">
        <a {...EXT} href={REPO_LINKS.repo} className="btn btn-primary">
          View iEye on GitHub
        </a>
        <a {...EXT} href={REPO_LINKS.contributing} className="btn-ghost text-sm">
          Read the contributor guide
        </a>
      </div>
      <p className="mt-4 text-sm text-charcoal-muted">
        Be kind — participation is governed by our{" "}
        <a {...EXT} href={REPO_LINKS.codeOfConduct} className="underline hover:text-charcoal">
          Code of Conduct
        </a>
        . iEye is a public good, not a business; there is no token and no investment offer.
      </p>
    </div>
  );
}
