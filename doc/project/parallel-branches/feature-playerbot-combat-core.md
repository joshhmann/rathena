# `feature-playerbot-combat-core`

## Goal

Lay out the first combat-capable playerbot runtime/design boundary without
trying to finish full combat AI in one jump.

## Scope

- define combat-core subsystem boundary
- identify reuse points for future expanded condition logic
- specify goals/controller/combat separation
- runtime feasibility notes for support/heal/assist roles

## Preferred Files

- `doc/project/pseudo-player-architecture.md`
- `doc/project/playerbot-execution-plan.md`
- `doc/project/headless-pc-v1-slice-log.md`

## Avoid

- `_common.txt` scheduler work
- merchant/party semantics
- broad source edits unless the slice is explicitly implementation-ready

## Acceptance

- repo has a concrete combat-core design note with clear non-goals and future integration points
