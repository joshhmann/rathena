# Playerbot Foundation Handoff

## Purpose

This document is the current handoff packet for external contributors working on
the remaining playerbot foundation frontier.

Use it when:

- handing work to Claude, Gemini, or another Codex session
- deciding whether a branch should exist at all
- checking which files are still owned by the primary runtime lane
- choosing the next remaining foundation part

This document assumes `master` is the only trusted integrated baseline unless a
branch is explicitly assigned.

## Read First

Before starting any branch:

- `AGENTS.md`
- `doc/project/playerbot-contributor-workflow.md`
- `doc/project/playerbot-merge-guardrails.md`
- `doc/project/playerbot-foundation-program.md`
- `doc/project/playerbot-foundation-priorities.md`
- `doc/project/playerbot-collaborator-brief.md`
- `doc/project/parallel-branch-workmap.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

Then verify locally:

- `git branch --show-current`
- `git log --oneline -n 8`
- `git status --short`

## Current Integrated Baseline

Current baseline on `master` already includes:

- structured trace events and recovery audits
- shared perception facade
- reservation primitives and reservation cleanup
- transactional item/storage foundations
- loadout continuity baseline
- broader participation hooks
- combat/status/death/respawn participation
- session continuity through:
  - NPC/dialog
  - storage
  - trade
  - bank
  - searchstore
  - map-change
  - quit/remove
- market participation through:
  - vending seller open/close
  - vendlist browsing
  - buyingstore seller open/close
  - buyingstore buyer browse and sell
- dedicated skillunit probe lane
- aggregate foundation gate:
  - `bash tools/ci/playerbot-foundation-smoke.sh run`

Current accepted reality:

- the aggregate foundation gate is green
- richer skillunit participation is proven through its separate probe/scenario
  lane, not yet the aggregate combat acceptance formula

## Remaining Foundation Parts

The remaining work is no longer early scaffolding. It is the last foundation
frontier.

### Part 1: Richer Combat And Event Participation

Still missing or intentionally deferred:

- promotion of richer skillunit participation from separate proof lane into the
  aggregate combat acceptance gate
- broader ground-skill / persistent-unit cleanup across repeated transitions
- additional combat-adjacent event continuity where the current legal hooks are
  still thin

Current rule:

- do not break the aggregate gate while pursuing this part
- use the dedicated skillunit probe and scenario lane first

Primary files:

- `src/map/script.cpp`
- `src/map/pc.cpp`
- `npc/custom/playerbot/playerbot_combat_lab.txt`

### Part 2: Deeper Item And Equipment Continuity

Still missing or intentionally deferred:

- more continuity around use/equip/ownership edges beyond the current loadout
  baseline
- broader failure detail on illegal or unavailable re-equip paths
- stronger transition coverage around remaining item-side edge cases

Primary files:

- `src/map/script.cpp`
- `src/map/pc.cpp`
- `npc/custom/playerbot/playerbot_item_lab.txt`

### Part 3: Scenario And Validation Expansion

Still missing:

- more targeted scenario coverage for the remaining combat/event and item
  continuity parts
- more runbook-backed scenarios beyond the current aggregate foundation smoke

Primary files:

- `tools/ci/playerbot-scenario.sh`
- `tools/ci/playerbot-scenario-catalog.sh`
- `doc/project/playerbot-scenario-runner.md`
- additional `tools/ci/*smoke.sh` helpers when narrowly scoped

## Ownership And File Boundaries

### Primary Runtime Lane Only

These files are owned by the main runtime lane unless explicitly delegated:

- `src/map/script.cpp`
- `src/map/pc.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_combat_lab.txt`
- `npc/custom/playerbot/playerbot_item_lab.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `tools/ci/playerbot-foundation-smoke.sh`

Do not put Claude and Gemini on overlapping edits in those files at the same
time.

### Safe Side Lanes

Usually safe for side-lane contributors:

- `doc/project/`
- `tools/ci/`
- read-only operator tooling
- scenario catalog and scenario docs

Side-lane contributors should prefer:

- tooling
- scenario coverage
- contract refinement
- gap audits

They should avoid:

- runtime semantics
- shared cleanup logic
- schema changes in the same turn as runtime work

## Recommended Branches

If you want to hand work to Claude and Gemini, use these branches.

### Claude

Recommended branch:

- `test/playerbot-scenario-expansion`

Scope:

- expand scenario coverage only
- no runtime edits

Allowed files:

- `tools/ci/playerbot-scenario.sh`
- `tools/ci/playerbot-scenario-catalog.sh`
- `doc/project/playerbot-scenario-runner.md`
- new scenario docs under `doc/project/`

Good tasks:

- add runbook-backed scenarios for:
  - `market-buyingstore-partial-fill`
  - `market-buyingstore-reopen`
  - `loadout-denied-recover`
  - `combat-skillunit-promotion-precheck`
- improve scenario list/show output if needed

Forbidden:

- `src/map/*`
- `npc/custom/living_world/_common.txt`
- active selftest NPCs owned by the main runtime lane

Validation:

- `bash tools/ci/playerbot-scenario.sh list`
- `bash tools/ci/playerbot-scenario.sh show <scenario>`
- `bash tools/ci/playerbot-scenario.sh run <scenario>` for at least one new
  scenario
- `git diff --check`

### Gemini

Recommended branch:

- `doc/playerbot-foundation-gap-audit`

Scope:

- docs and contract audit only
- no runtime edits

Allowed files:

- `doc/project/playerbot-status-continuity-contract.md`
- `doc/project/playerbot-combat-frontier-contract.md`
- `doc/project/playerbot-foundation-program.md`
- this handoff doc
- a new remaining-foundation checklist doc if useful

Good tasks:

- identify the remaining foundation gaps after the current market/session
  continuity work
- refine which combat/event participation edges are still truly missing
- tighten scenario expectations against current implementation

Forbidden:

- `src/map/*`
- `npc/custom/living_world/_common.txt`
- aggregate smoke runtime logic

Validation:

- docs must match current implementation
- no invented runtime capabilities
- clean rebase onto current `master`
- `git diff --check`

## Validation Rules

Every contributor should validate against the real integrated baseline.

Minimum bar for runtime work:

- `cmake --build build --target map-server -j4`
- `git diff --check`
- `bash tools/dev/playerbot-dev.sh restart`
- `bash tools/ci/playerbot-foundation-smoke.sh run`

Minimum bar for side-lane work:

- `--help` on any new CLI tool
- one general query or list command
- one focused query or scenario
- clean worktree after commit

## Current Known Constraints

- The aggregate combat gate is intentionally narrower than the dedicated
  skillunit probe lane.
- The current accepted proof model is:
  - aggregate smoke for the stable baseline
  - dedicated probe/scenario lane for richer skillunit participation
- Do not describe separate-probe coverage as if it were already part of the
  aggregate combat acceptance gate.
- Do not present static config as live runtime truth.

## Merge Checklist

A branch is not merge-ready unless:

- it is rebased onto current `master`
- it stays inside its assigned scope
- labels and docs match what the code or queries actually do
- validation commands are included and pass
- it does not overwrite newer slice-log content
- it is reviewed by the primary runtime owner before any merge or cherry-pick

## Current Best Next Moves

Main runtime lane:

1. finish the next richer combat/event participation step without breaking the
   aggregate foundation gate
2. deepen the remaining item/equipment continuity edges

Claude side lane:

1. expand scenario coverage around the already-accepted market and loadout
   baselines

Gemini side lane:

1. produce the remaining-foundation gap audit and tighten contract language for
   the next combat/event promotion steps
