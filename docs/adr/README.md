# Architecture Decision Records

An **ADR** captures one architectural decision: the context, the choice we made,
and the consequences we accepted. New contributors most often lack the *why* — why
`WelfareSignal` can't hold a blob, why there's no `protected` boolean, why mode is
a sink and not two apps. ADRs are where that lives, versioned next to the code and
reviewed in the same PR.

> Code says *what*. ADRs say *why*. The [architecture overview](../architecture.md)
> says *how it fits together*.

## When to write one

Write an ADR when a change:

- alters or reinforces a [non-negotiable guardrail](../../CLAUDE.md) (payload
  shape, edge-only liveness, honest coverage, mechanism-not-outcome, cheap false
  alarms);
- picks one approach where a reasonable person would've picked another (a library,
  a boundary, a data model, a protocol mapping);
- is something a future contributor would otherwise undo, not knowing why it's
  there.

Trivial or easily-reversed changes don't need one. When in doubt, a short ADR is
cheap insurance.

## How

1. Copy [`0000-template.md`](0000-template.md) to the next number:
   `NNNN-short-kebab-title.md` (e.g. `0002-tier1-mesh-source-boundary.md`).
2. Fill it in. Keep it short — a screen or two. Link the issue/PR and any
   guardrail it touches.
3. Open it in the **same PR** as the change it explains, so the decision and the
   code land together.
4. Decisions are **immutable once `Accepted`.** Changed your mind? Write a new ADR
   that supersedes the old one and set the old one's status to
   `Superseded by NNNN`. Don't rewrite history — the trail is the point.

## Index

| # | Title | Status |
|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
