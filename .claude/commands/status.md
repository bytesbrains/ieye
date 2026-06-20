---
description: "CEO Dashboard — cross-team status report on Maktub Protocol progress"
argument-hint: "[--detailed]"
---

You are running a **status check** across the Maktub Protocol project. Act as a Chief of Staff reporting to the CEO.

## What To Check

Scan the project and report on every department:

### ENGINEERING

**1. Smart Contracts (CTO / Architect)**
- Check `contracts/v3/` — which of the 5 Maktub v3 contracts exist?
  - MaktubCore.sol, RecipientRegistry.sol, MktbToken.sol, ExecutorRewards.sol, MktbGovernance.sol
- Do they compile? Run `npx hardhat compile` if contracts exist.
- How complete are they vs the blueprint?

**2. Tests (QA Lead)**
- Check `test/v3/` — do test files exist?
- If yes, run `npx hardhat test` and report pass/fail counts.
- Estimate coverage level.

**3. Frontend (Frontend Lead)**
- Check `app/src/` — has it been updated for Maktub v3?
- Are the pages/components referencing v3 contracts or still v1?

**4. SDK (SDK Lead)**
- Check `sdk/src/` — has it been updated for Maktub v3?
- Does it reference v3 contract ABIs or still v1?

### BUSINESS & OPERATIONS

**5. Legal (General Counsel)**
- Check `docs/legal/` — any regulatory analysis, ToS drafts, jurisdictional assessments?
- Key open legal questions?

**6. Marketing (CMO)**
- Check `docs/marketing/` — go-to-market strategy, content calendar, brand guidelines?
- Website (maktub.it) status?

**7. Community (Head of Community)**
- Check `docs/community/` — onboarding guides, contributor guidelines, FAQ?
- Community channels set up? (Discord, Twitter, GitHub discussions)

**8. Business Development (Head of BD)**
- Check `docs/bizdev/` — partnership pipeline, listing applications, competitive analysis?
- Key partnership conversations in progress?

**9. Security (CISO)**
- Check `docs/security/` — threat models, audit status, bug bounty program, incident playbooks?
- Any open security concerns?

**10. Research (Head of Research)**
- Check `docs/research/` — PRE analysis, scaling research, identity solutions?
- Any findings that change protocol assumptions?

### INFRASTRUCTURE

**11. Documentation**
- Is CLAUDE.md up to date?
- Stale docs referencing CryptoWills v1?

**12. Git Status**
- Branch, uncommitted changes, recent commits

## Output Format

```
MAKTUB PROTOCOL — CEO STATUS REPORT
=====================================

--- ENGINEERING ---
CONTRACTS:  [X/5 built] [compiles: yes/no]
TESTS:      [X tests] [pass/fail] [est. coverage: X%]
FRONTEND:   [v1/v3] [status summary]
SDK:        [v1/v3] [status summary]

--- BUSINESS & OPS ---
LEGAL:      [status summary]
MARKETING:  [status summary]
COMMUNITY:  [status summary]
BIZDEV:     [status summary]
SECURITY:   [status summary]
RESEARCH:   [status summary]

--- INFRASTRUCTURE ---
DOCS:       [up to date / needs update]
GIT:        [branch] [clean/dirty] [last commit: date]

TOP 3 PRIORITIES:
1. ...
2. ...
3. ...

BLOCKERS:
- ...

DECISIONS NEEDED (CEO):
- ...
```

If `--detailed` is passed, expand each section with specifics.
