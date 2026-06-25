# GitHub Discussions — setup

A maintainer guide for turning on Discussions and configuring it before inviting
contributors. **Discussions, not the wiki:** the wiki escapes our CI / CODEOWNERS
gates and drifts from the code (see [ADR 0001](adr/0001-record-architecture-decisions.md)).
Use this split:

- **Conversation** (questions, ideas, proposals, announcements) → **Discussions**
- **Versioned truth** (architecture, decisions, standards) → `docs/`
- **Tracked work** (bugs, scoped features) → **Issues**
- **Reserved** → the wiki tab stays **off**

## Enable it

1. Repo **Settings → General → Features → ✅ Discussions**.
2. (Optional, recommended) **Settings → General → Features → ✅ Wikis → uncheck**,
   so the empty wiki tab doesn't invite ungated edits.

## Recommended categories

Trim GitHub's defaults to these. Format matters: **Q&A** lets answers be marked
accepted; **Announcement** is maintainer-post-only; **Open discussion** is a plain
thread.

| Category | Format | Purpose |
|---|---|---|
| 📣 Announcements | Announcement | Releases, roadmap shifts, calls for help. Maintainers post. |
| 🙏 Q&A | Q&A | "How do I…", setup trouble, "is this a bug or expected?" Triage funnel before Issues. |
| 💡 Ideas & proposals | Open | Design proposals and feature pitches *before* they're scoped. Guardrail-touching ones graduate to an [ADR](adr/README.md). |
| 🙌 Show & tell | Open | Things people built on or around iEye; integrations; demos. |
| 💬 General | Open | Anything that doesn't fit the above. |

Keep the list short — empty categories read as a dead project.

## Routing (put this in the welcome post)

- **A clear bug or a scoped, agreed feature** → open an **Issue** (use the
  [templates](../.github/ISSUE_TEMPLATE)). Don't discuss it to death first.
- **"Should we…?" / "What if…?" / not sure yet** → **Ideas & proposals**.
- **A question or setup problem** → **Q&A**.
- **Anything security-sensitive** → **never** a public Discussion or Issue. Follow
  [SECURITY.md](../SECURITY.md).
- **A proposal that touches a [guardrail](../CLAUDE.md)** → discuss in Ideas, then
  capture the outcome as an [ADR](adr/README.md) in the implementing PR.

## Seed the space before inviting

A blank Discussions tab gets no replies. Before the invite, post:

1. **📣 Welcome** — what iEye is (one paragraph + README link), the routing rules
   above, and the pointer to [CONTRIBUTING.md](../CONTRIBUTING.md) and
   [CLAUDE.md](../CLAUDE.md).
2. **💡 A first open proposal** — e.g. "Tier-1 home-mesh sources: which sensors
   first?" — to model the format and lower the bar to the second post.
3. **🙏 A starter Q&A** — e.g. "How do I run the app against the Firebase
   emulator?" — answer it yourself and mark the answer accepted.

## Discussion forms

Category forms (like issue forms) live in
[`.github/DISCUSSION_TEMPLATE/`](../.github/DISCUSSION_TEMPLATE). One is provided —
`ideas-proposals.yml` — which prompts a proposer for the guardrail impact up front,
so the ADR question is asked at the start, not in review. The form's filename slug
must match the category's URL slug (rename it if you name the category differently).
