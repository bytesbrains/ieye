# 0001. Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-06-26
- **Deciders:** @bytesbrains
- **Issue / PR:** —
- **Guardrail touched:** (none)

## Context

iEye is opening to outside contributors. The codebase encodes several decisions
that are *non-obvious and easy to undo in good faith* — `WelfareSignal` can't hold
a free-form blob, `CoverageState` has no `protected` boolean, "mode" is a pluggable
sink rather than two apps. These follow from the [`CLAUDE.md`](../../CLAUDE.md)
guardrails, but the reasoning lives only in code comments and one person's head. A
new contributor can't tell a deliberate constraint from an accidental gap, and a
well-meaning PR can quietly weaken a guardrail.

We considered a GitHub wiki for this kind of background, but a wiki lives in a
separate repo, escapes our CI and CODEOWNERS gates, and goes stale the moment a PR
changes behaviour — unacceptable for a welfare/safety product where docs make
promises about how help is delivered.

## Decision

We will record significant architectural decisions as **Architecture Decision
Records** in [`docs/adr/`](README.md), versioned next to the code. Each ADR follows
[`0000-template.md`](0000-template.md), lands in the **same PR** as the change it
explains, and is **immutable once `Accepted`** — superseding decisions are written
as new ADRs, never edits.

## Alternatives considered

- **GitHub wiki** — separate repo, no review/CI/CODEOWNERS, drifts from the code.
  Rejected; the gates we built exist precisely so docs that make safety promises
  stay reviewed and current.
- **Decisions only in code comments** — good for local *what*, poor for
  cross-cutting *why* and for the alternatives we rejected. ADRs complement
  comments, they don't replace them.
- **No formal record** — the status quo; doesn't scale past one author and loses
  the rationale that stops guardrails from eroding.

## Consequences

- Contributors get a single, reviewed home for the *why* behind the design; the
  [architecture overview](../architecture.md) links here.
- A small per-decision cost: a screen of writing in the PR that makes the call.
- The ADR log becomes the audit trail for guardrail-sensitive changes — which the
  [CODEOWNERS](../../.github/CODEOWNERS) legal/security gate already watches for.
- This very practice is itself an ADR (#0001), so the convention is self-documenting.
