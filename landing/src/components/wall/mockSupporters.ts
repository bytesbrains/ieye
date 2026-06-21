// Mock supporter data for the wall-preview comparison (#36).
//
// THIS IS DESIGN MOCK DATA ONLY — not wired to Firestore, never shipped on the
// live wall. It exists so CEO/Designer/Marketing can compare the two wall
// treatments emotionally before locking one. See /wall-preview.
//
// Honors the #36 shared rules (wall Version B — Flat Wall):
//   - every entry here is a CONSENTED, opt-in-to-be-named supporter
//   - NO exact per-person amount exists in this data, by design
//   - money/in-kind/labor coexist at equal weight, never ranked
//   - anonymous contributors are represented only as one aggregate count

export type SupporterKind = "money" | "inkind" | "labor";

export interface MockSupporter {
  /** Stable key — display names are free-text and not guaranteed unique. */
  id: string;
  /** Free-text display name the contributor set (handle / name / dedication). */
  name: string;
  kind: SupporterKind;
  /** Optional one-line message (warmth, never a number). */
  message?: string;
}

/** Named, consented supporters — deliberately mixed kinds, no amounts. */
export const SUPPORTERS: MockSupporter[] = [
  { id: "asha-foundation", name: "Asha Foundation", kind: "inkind", message: "Compute, gladly given." },
  { id: "r-mehta", name: "R. Mehta", kind: "money" },
  { id: "priya-k", name: "Priya K.", kind: "money", message: "For everyone who lives alone." },
  { id: "cloud-credits-co", name: "Cloud Credits Co.", kind: "inkind" },
  { id: "j-nandal", name: "J. Nandal", kind: "money" },
  { id: "k-rao", name: "K. Rao", kind: "labor", message: "Wrote the escalation tests." },
  { id: "in-memory-of-d", name: "In memory of D.", kind: "money", message: "Found, not lost." },
  { id: "m-singh", name: "M. Singh", kind: "money" },
  { id: "devkit-io", name: "devkit.io", kind: "inkind" },
  { id: "a-patel", name: "A. Patel", kind: "labor", message: "Issue triage, every week." },
  { id: "s-roy", name: "S. Roy", kind: "money" },
  { id: "lena-o", name: "Lena O.", kind: "money" },
  { id: "for-my-father", name: "for my father", kind: "money" },
  { id: "tariq-h", name: "Tariq H.", kind: "labor" },
  { id: "meadowlark-press", name: "Meadowlark Press", kind: "inkind" },
  { id: "b-costa", name: "B. Costa", kind: "money" },
];

/** Private supporters (consented to contribute, opted OUT of naming) — count only. */
export const ANON_TOTAL = 128;

/**
 * Organizations on the partner strip.
 * Relationship/opt-in only — NEVER amount-gated, NEVER tiered. Equal weight.
 * (No real logos in the mock; rendered as equal-sized name plates.)
 */
export const ORG_PARTNERS: { id: string; name: string; kind: SupporterKind }[] = [
  { id: "asha-foundation", name: "Asha Foundation", kind: "inkind" },
  { id: "cloud-credits-co", name: "Cloud Credits Co.", kind: "inkind" },
  { id: "devkit-io", name: "devkit.io", kind: "inkind" },
  { id: "meadowlark-press", name: "Meadowlark Press", kind: "inkind" },
  { id: "northwind-labs", name: "Northwind Labs", kind: "money" },
];

const KIND_LABEL: Record<SupporterKind, string> = {
  money: "contribution",
  inkind: "in-kind",
  labor: "labor",
};

/** Accessible label for a non-money supporter; money needs no qualifier. */
export function kindNote(kind: SupporterKind): string | null {
  return kind === "money" ? null : KIND_LABEL[kind];
}
