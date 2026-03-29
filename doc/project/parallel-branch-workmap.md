# Playerbot Parallel Branch Workmap

## Purpose

This file makes the current parallel branch plan explicit inside the repo.

Use it when:

- assigning another Codex instance to a branch
- reviewing whether two branches are safe to run in parallel
- checking the intended scope, file ownership, and acceptance target for a branch

Also read:

- `doc/project/playerbot-collaborator-brief.md`
- `doc/project/playerbot-foundation-handoff.md`

## Current Rule

Parallel work is allowed only when write scopes are clearly disjoint.

Default operating mode for playerbot work:

- prefer a named branch for each coherent slice
- prefer a sub-agent or separate Codex instance for each branch when scopes are disjoint
- use the main thread as the reviewer/integrator when multiple branches are active
- avoid stacking unrelated work on one branch when parallel lanes are already available

Unsafe overlap:

- two branches editing `npc/custom/living_world/_common.txt`
- two branches editing the same `src/map/*` or `src/char/*` runtime files
- two branches writing the same SQL migration
- two branches changing the same controller config format at once

Required for every branch:

- repo-local doc updates
- CLI validation first
- desktop-client validation when visual or interaction-heavy
- SQL artifact when DB changes
- branch brief kept current enough that another Codex instance can start from the repo alone
- side-lane labels must distinguish static config from live runtime truth

## Parallel Policy

This is now the preferred policy, not a one-off tactic.

Use branches plus sub-agents by default when:

- there are 2 or more disjoint write scopes available
- one lane is docs/schema/config and another is runtime/script work
- one lane is validation/tooling and another is implementation

Keep work in the main thread when:

- the slice owns `_common.txt`
- the slice owns the same `src/map/*` or `src/char/*` hotspot as another active lane
- the very next step is blocked on the result
- the change is too coupled to split cleanly

Main-thread responsibilities when sub-agents are active:

- assign branches and scope
- review pass/fail on returned work
- reject scope drift
- keep merge order coherent

## Branch Index

- `feature/playerbot-scheduler-supply`
  - repo brief: [feature-playerbot-scheduler-supply.md](/root/dev/rathena/doc/project/parallel-branches/feature-playerbot-scheduler-supply.md)
  - status: implemented
- `feature/playerbot-pool-observability`
  - repo brief: [feature-playerbot-pool-observability.md](/root/dev/rathena/doc/project/parallel-branches/feature-playerbot-pool-observability.md)
  - status: ready
- `feature/playerbot-provisioning-schema`
  - repo brief: [feature-playerbot-provisioning-schema.md](/root/dev/rathena/doc/project/parallel-branches/feature-playerbot-provisioning-schema.md)
  - status: ready
- `feature/playerbot-routine-scheduler`
  - repo brief: [feature-playerbot-routine-scheduler.md](/root/dev/rathena/doc/project/parallel-branches/feature-playerbot-routine-scheduler.md)
  - status: ready
- `feature/playerbot-party-foundation`
  - repo brief: [feature-playerbot-party-foundation.md](/root/dev/rathena/doc/project/parallel-branches/feature-playerbot-party-foundation.md)
  - status: ready
- `feature/playerbot-merchant-state`
  - repo brief: [feature-playerbot-merchant-state.md](/root/dev/rathena/doc/project/parallel-branches/feature-playerbot-merchant-state.md)
  - status: ready
- `feature/playerbot-combat-core`
  - repo brief: [feature-playerbot-combat-core.md](/root/dev/rathena/doc/project/parallel-branches/feature-playerbot-combat-core.md)
  - status: ready
- `test/openkore-smoke-scenarios`
  - repo brief: [test-openkore-smoke-scenarios.md](/root/dev/rathena/doc/project/parallel-branches/test-openkore-smoke-scenarios.md)
  - status: ready

## Current Foundation Program Lanes

Current preferred primary lane:

1. observability and replayability
2. perception facade
3. reservation primitives
4. recovery/state-boundary formalization
5. transactional inventory/equipment/storage
6. broader participation hooks

Safe side lanes while the primary lane is active:

- contract docs and slice logging
- scenario runner / trace viewer tooling
- reservation and scheduler inspection tooling
- SQL-only preparation work after an interface is frozen

Unsafe side lanes:

- another lane editing `_common.txt` while the primary lane owns shared
  controller/runtime semantics
- another lane editing the same `src/map/*` or `src/char/*` hotspot files
- side lanes that change the active contract mid-slice

## Assignment Guidance

Best next assignments:

1. `test/playerbot-scenario-expansion`
   - scenario-runner and runbook lane
2. `doc/playerbot-foundation-gap-audit`
   - docs/contracts lane for the remaining frontier
3. tooling or diagnostics branches that stay out of runtime hotspots
   - only when their write scope is clearly disjoint from the primary lane

If a branch needs to touch `_common.txt`, it should usually be the primary branch
for that round.

## Side-Lane Guardrail

For tooling and diagnostics branches:

- do not present configured scheduler/controller fields as live runtime demand
- if a tool only reads config/state tables, label them honestly as configured
  thresholds or supply snapshots
- if a tool wants to report live requested/runtime demand, it must say exactly
  which live runtime source it reads
