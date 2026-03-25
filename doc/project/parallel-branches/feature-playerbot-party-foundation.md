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
