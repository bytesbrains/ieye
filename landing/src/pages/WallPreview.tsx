import { WallFlat } from "../components/wall/WallFlat";

// Designer reference for #36 — the chosen supporter-wall treatment.
//
// Version B (Flat Wall) was selected over Version A (Named Tiers): it's the only
// treatment with zero amount leakage — every named supporter at equal weight, no
// coarse whale-ranking to exploit. This page renders it from mock data so the
// team has a living reference for the layout before the live wall is built
// (Phase 2, post-#39). NOT a shipped page; lives in the main bundle (no Firebase)
// at /wall-preview. The public landing keeps its "coming soon" placeholder until
// real, reconciled data exists.

export function WallPreview() {
  return (
    <main className="min-h-screen bg-paper px-5 py-12">
      <div className="mx-auto max-w-5xl">
        <a href="/" className="btn-ghost text-sm">
          ← Back to landing
        </a>

        <header className="mt-6">
          <p className="text-sm font-semibold uppercase tracking-wide text-teal-deep">
            Design reference · issue #36
          </p>
          <h1 className="mt-2 font-serif text-3xl font-semibold text-charcoal sm:text-4xl">
            Supporter wall — Flat Wall (chosen)
          </h1>
          <p className="mt-4 max-w-prose text-lg leading-relaxed text-charcoal-soft">
            The rule made visible: <strong>opt-in to be named is not opt-in to be priced</strong>.
            Every named supporter sits at equal weight; no amount is ever shown. Mock data — not
            wired to the ledger.
          </p>
        </header>

        <div className="mt-8 overflow-hidden rounded-2xl border-2 border-charcoal/15 bg-paper-dim">
          <div className="border-b border-charcoal/10 bg-paper px-5 py-3">
            <span className="text-sm font-semibold text-charcoal">Version B · Flat Wall</span>
          </div>
          <div className="px-5 py-12 sm:px-8">
            <WallFlat />
          </div>
        </div>

        {/* The invariants this layout enforces. */}
        <section className="mt-10 rounded-2xl border border-charcoal/10 bg-paper-dim px-5 py-6 sm:px-8">
          <h2 className="font-serif text-xl font-semibold text-charcoal">What this guarantees</h2>
          <ul className="mt-3 space-y-2 text-base text-charcoal-soft">
            <li>• Invisible by default — only consented, opt-in-named supporters appear.</li>
            <li>• No per-person amounts, ever. No live balance. No size-sort, no ranking.</li>
            <li>• Money, in-kind, and labor share one wall — recognition isn’t money-gated.</li>
            <li>• Private contributors appear only as one aggregate count.</li>
            <li>
              • Org/partner strip is <strong>relationship/opt-in, never amount-gated</strong> —
              equal logo weight.
            </li>
            <li>• Recognition gradient lives off the wall: org strip + private receipts (#43).</li>
            <li>• Consent is revocable; toggling off removes the entry on next publish (#39 gate).</li>
          </ul>
        </section>
      </div>
    </main>
  );
}
