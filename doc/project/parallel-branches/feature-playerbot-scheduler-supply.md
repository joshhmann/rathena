# `feature/playerbot-scheduler-supply`

## Goal

Make scheduler actor budgeting reflect real assignable supply from parked pools.

## Scope

- scheduler should use effective supply, not only configured weight
- pooled supply should respect occupancy and controller ownership
- status output should expose effective supply clearly

## Owned Files

- `npc/custom/living_world/_common.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

## Avoid

- SQL schema work
- provisioning tables
- party or merchant semantics

## Acceptance

- scheduler can still activate a controller when only a subset of its pool is available
- restart does not leave the pool looking exhausted from stale script reservations
- CLI smoke test proves pooled bots still repopulate cleanly

## Codex Prompt

Use this branch brief as the source of truth.

Read first:

- `doc/project/parallel-branch-workmap.md`
- `doc/project/parallel-branches/feature-playerbot-scheduler-supply.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/openkore-test-harness.md`

Do:

- work only on scheduler supply-aware budgeting and pool-supply accounting
- prefer changes in the owned files above
- validate with restart plus OpenKore CLI smoke tests
- update repo-local slice docs before committing

Avoid:

- SQL schema work
- provisioning work
- party, merchant, or combat semantics
