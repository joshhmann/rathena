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
