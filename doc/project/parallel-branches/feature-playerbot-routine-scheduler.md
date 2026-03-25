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

## Codex Prompt

Use this branch brief as the source of truth.

Read first:

- `doc/project/parallel-branch-workmap.md`
- `doc/project/parallel-branches/feature-playerbot-routine-scheduler.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/playerbot-execution-plan.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`

Do:

- push routine groups, schedule buckets, and recurring presence policy
- prefer config/docs/scheduler-demo work first
- validate with restart plus OpenKore CLI smoke tests
- update repo-local slice docs before committing

Avoid:

- `_common.txt` unless truly necessary
- uncoordinated SQL schema work
- party, merchant, or combat semantics
