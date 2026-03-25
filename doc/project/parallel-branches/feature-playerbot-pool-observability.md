# `feature/playerbot-pool-observability`

## Goal

Expose pool and scheduler state clearly enough that supply, starvation, parked
count, and assignment failures are easy to diagnose.

## Scope

- add clearer scheduler/pool status surfaces
- show requested actors vs effective supply vs active vs pending vs parked
- surface pool shortage and unassigned slots
- keep this slice script-first if possible

## Preferred Files

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

## Avoid

- SQL schema changes
- routine scheduling
- party/combat/merchant semantics

## Acceptance

- operator can tell why a controller did not fully populate
- CLI status makes supply shortages obvious
- no regression in controller start/stop/park behavior

## Codex Prompt

Use this branch brief as the source of truth.

Read first:

- `doc/project/parallel-branch-workmap.md`
- `doc/project/parallel-branches/feature-playerbot-pool-observability.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/openkore-test-harness.md`

Do:

- improve pool and scheduler visibility only
- expose requested actors vs effective supply vs active vs pending vs parked
- make shortage and unassigned-slot states obvious in CLI status
- validate with restart plus OpenKore CLI smoke tests
- update repo-local slice docs before committing

Avoid:

- SQL schema changes
- routine scheduling
- party, merchant, or combat semantics
