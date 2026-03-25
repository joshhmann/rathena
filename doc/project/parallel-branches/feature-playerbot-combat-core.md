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

## Codex Prompt

Use this branch brief as the source of truth.

Read first:

- `doc/project/parallel-branch-workmap.md`
- `doc/project/parallel-branches/feature-playerbot-combat-core.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/playerbot-execution-plan.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/pseudo-player-research-notes.md`

Do:

- define the first combat-capable playerbot boundary
- keep goals/controller/combat separation explicit
- prefer docs/spec unless a very narrow runtime proof is justified
- update repo-local slice docs before committing

Avoid:

- `_common.txt` scheduler work
- party or merchant work
- pretending full combat AI is done in one slice
