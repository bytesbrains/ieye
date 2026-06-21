import { SUPPORTERS, ANON_TOTAL, kindNote } from "./mockSupporters";
import { OrgPartnerStrip } from "./OrgPartnerStrip";

// VERSION B — Flat Wall (recommended default, #36).
//
// One undifferentiated field of names. No bands, no ranking, no amount signal
// of any kind. A one-time ₹100 giver, a wire patron, a credits sponsor, and a
// PR author sit side by side at equal visual weight. This is the only version
// with ZERO amount leakage — fully consistent with "named ≠ priced" and the
// privacy-by-architecture brand. Recognition gradient is recovered OFF the wall
// (org strip below + private thank-yous in the account, #43).
export function WallFlat() {
  return (
    <div className="container-wide text-center">
      <p className="text-sm font-semibold uppercase tracking-wide text-teal-deep">
        Transparency
      </p>
      <h2 className="mt-3 text-3xl font-semibold sm:text-4xl">You made this possible.</h2>
      <p className="mx-auto mt-5 max-w-prose text-lg leading-relaxed text-charcoal-soft">
        Everyone below chose to be named. Money, in-kind, and labor — all one wall,
        thanked equally. No amounts are ever shown.
      </p>

      {/* The wall: a single flowing field. Alphabetical-ish order, never by size. */}
      <ul className="mx-auto mt-10 flex max-w-3xl flex-wrap items-center justify-center gap-x-3 gap-y-4">
        {SUPPORTERS.map((s) => {
          const note = kindNote(s.kind);
          return (
            <li
              key={s.id}
              className="inline-flex items-baseline gap-1.5 rounded-full bg-paper px-4 py-2 text-base text-charcoal"
            >
              <span className="font-semibold">{s.name}</span>
              {note && (
                <span className="text-xs font-medium uppercase tracking-wide text-teal-deep">
                  · {note}
                </span>
              )}
            </li>
          );
        })}
      </ul>

      {/* Dedications, surfaced gently — warmth without numbers. */}
      <p className="mx-auto mt-8 max-w-prose text-base italic text-charcoal-muted">
        “For everyone who lives alone.” &nbsp;·&nbsp; “Found, not lost.” &nbsp;·&nbsp; “For my father.”
      </p>

      <p className="mt-8 text-base text-charcoal-muted">
        + {ANON_TOTAL.toLocaleString()} supporters who chose to stay private
      </p>

      <OrgPartnerStrip />
    </div>
  );
}
