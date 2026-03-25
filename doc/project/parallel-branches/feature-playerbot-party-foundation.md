# `feature-playerbot-party-foundation`

## Goal

Define and begin implementing the first party-capable playerbot semantics.

## Scope

- invite eligibility
- accept/decline behavior
- first party-state policy docs
- runtime feasibility path for party-capable persistent bots

## Preferred Files

- `src/map/*`
- `src/char/*`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/headless-pc-v1-slice-log.md`

## Avoid

- `_common.txt` scheduler/controller work
- SQL provisioning work unless explicitly coordinated
- merchant/combat feature work

## Acceptance

- repo has a concrete party-foundation slice spec and, if implemented, one narrow proof path
- validation plan is explicit

## Codex Prompt

Use this branch brief as the source of truth.

Read first:

- `doc/project/parallel-branch-workmap.md`
- `doc/project/parallel-branches/feature-playerbot-party-foundation.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/openkore-test-harness.md`

Do:

- define the first narrow party-capable playerbot foundation
- prefer runtime/docs work over broad feature expansion
- keep proofs small and defensible
- validate with CLI first, then desktop client if interaction requires it
- update repo-local slice docs before committing

Avoid:

- `_common.txt` scheduler/controller work
- merchant or combat work
- unrelated schema drift
