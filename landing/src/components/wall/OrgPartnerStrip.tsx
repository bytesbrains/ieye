import { ORG_PARTNERS } from "./mockSupporters";

// Org / partner strip (#36 decision lock).
//
// Relationship + explicit opt-in ONLY — never amount-gated, never tiered.
// Every plate is the SAME size: a small in-kind sponsor and a large one look
// identical. This is how organizations get recognition without re-introducing
// an amount signal through the back door.
//
// Used identically by BOTH wall versions, so the partner treatment is constant
// and only the *individual* wall changes between A and B.
export function OrgPartnerStrip() {
  return (
    <div className="mt-12 border-t border-charcoal/10 pt-8">
      <p className="text-center text-sm font-semibold uppercase tracking-wide text-teal-deep">
        Organizations standing with us
      </p>
      <p className="mx-auto mt-2 max-w-prose text-center text-sm text-charcoal-muted">
        Listed by partnership, not by amount. Every name carries equal weight.
      </p>

      <ul className="mt-6 flex flex-wrap items-center justify-center gap-3">
        {ORG_PARTNERS.map((org) => (
          <li key={org.id}>
            {/* Equal-sized plate stands in for a real logo in the mock. */}
            <div className="flex h-14 min-w-[150px] items-center justify-center rounded-xl border-2 border-charcoal/15 bg-paper px-5 text-center text-base font-semibold text-charcoal-soft">
              {org.name}
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
