# Playerbot Parallel Branch Workmap

## Purpose

This file makes the current parallel branch plan explicit inside the repo.

Use it when:

- assigning another Codex instance to a branch
- reviewing whether two branches are safe to run in parallel
- checking the intended scope, file ownership, and acceptance target for a branch

## Current Rule

Parallel work is allowed only when write scopes are clearly disjoint.

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

## Assignment Guidance

Best next assignments:

1. `feature/playerbot-pool-observability`
   - low-risk, high-value scheduler visibility work
2. `feature/playerbot-provisioning-schema`
   - schema/docs lane, safe in parallel with script work
3. `test/openkore-smoke-scenarios`
   - validation lane, safe in parallel with almost everything

If a branch needs to touch `_common.txt`, it should usually be the primary branch
for that round.
