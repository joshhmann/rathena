# `feature-playerbot-routine-scheduler`

## Goal

Move from controller-local fixed rosters to recurring bot routines with schedule
groups, regions, and role-aware activation.

## Scope

- routine groups
- timezone or schedule buckets
- recurring presence policy
- parked/offline to active handoff by routine

## Preferred Files

- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/roadmap.md`
- `doc/project/headless-pc-v1-slice-log.md`

## Avoid

- `_common.txt` unless absolutely necessary
- SQL schema unless coordinated with provisioning branch
- party/combat/merchant semantics

## Acceptance

- at least one controller can be driven by a routine/schedule concept instead of a static always-on policy
- recurring-presence policy is documented clearly
