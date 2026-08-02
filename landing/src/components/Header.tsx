import { Link } from "react-router-dom";
import { Wordmark } from "./Brand";

const NAV = [
  { href: "#secure", label: "iEye Secure" },
  { href: "#how-it-works", label: "How it works" },
  { href: "#trust", label: "Trust & privacy" },
  { href: "#bytesbrains", label: "BytesBrains" },
];

export function Header() {
  return (
    <header className="sticky top-0 z-50 border-b border-charcoal/10 bg-paper/90 backdrop-blur">
      <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-5 py-3">
        <a href="#top" className="rounded-md" aria-label="iEye home">
          <Wordmark />
        </a>
        <nav aria-label="Primary" className="hidden items-center gap-6 md:flex">
          {NAV.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="text-base text-charcoal-soft hover:text-charcoal"
            >
              {item.label}
            </a>
          ))}
          <Link
            to="/signin"
            className="rounded-md text-base text-charcoal-soft hover:text-charcoal"
          >
            Sign in
          </Link>
          <Link to="/app" className="btn btn-primary px-5 py-2 text-sm">
            Scan your home
          </Link>
        </nav>
        {/* Mobile: a single clear CTA, no hamburger needed for a one-page scroll */}
        <Link to="/app" className="btn btn-primary px-5 py-2 text-sm md:hidden">
          Scan your home
        </Link>
      </div>
    </header>
  );
}
