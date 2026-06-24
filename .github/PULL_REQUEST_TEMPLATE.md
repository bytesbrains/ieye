<!--
  Thanks for contributing to iEye! Please read CONTRIBUTING.md first.
  Use a Conventional Commit title, e.g. "feat(app): per-person rhythm baseline (#64)".
-->

## What & why

<!-- What does this change, and why? Link the issue it closes. -->

Closes #

## How I verified it

<!-- Tests added/run, manual steps, screenshots for UI. -->

- [ ] `flutter analyze` + `flutter test` pass (if `app/` changed)
- [ ] `npm run build` passes (if `landing/` changed)
- [ ] Firestore rules tests pass (if rules changed)

## Guardrail check

iEye holds these lines [structurally](../CLAUDE.md). Confirm this PR keeps them:

- [ ] The welfare alert stays **benign and recoverable** — it cannot carry or trigger an irreversible secret/will.
- [ ] **Liveness stays one bit at the edge** — no GPS traces, rhythm baselines, or unlock timelines are logged, synced, or sent off-device.
- [ ] Copy/UX watches **over** the user, never watches them — no "monitor / track / surveil"; promises the **mechanism, not the outcome**; no fake "protected" shield.
- [ ] If this touches honesty copy / legal / consent wording, I expect the [CODEOWNERS](.github/CODEOWNERS) review gate.

## Notes for reviewers

<!-- Anything that needs extra eyes, trade-offs made, follow-ups. -->
