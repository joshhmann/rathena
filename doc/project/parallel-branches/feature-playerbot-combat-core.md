# `feature-playerbot-combat-core`

## Goal

Lay out the first combat-capable playerbot runtime/design boundary without
trying to finish full combat AI in one jump.

The implementation-facing source of truth for this frontier is:

- `doc/project/playerbot-combat-frontier-contract.md`

## Scope

- define combat-core subsystem boundary
- identify reuse points for future expanded condition logic
- specify goals/controller/combat separation
- runtime feasibility notes for support/heal/assist roles
- record death / respawn recovery truth for combat ownership
- keep the first mechanic participation matrix aligned with current baseline

## Preferred Files

- `doc/project/pseudo-player-architecture.md`
- `doc/project/playerbot-execution-plan.md`
- `doc/project/headless-pc-v1-slice-log.md`

## Avoid

- `_common.txt` scheduler work
- merchant/party semantics
- broad source edits unless the slice is explicitly implementation-ready

## Acceptance

- repo has a concrete combat frontier contract with clear non-goals, recovery
  truth, and mechanic participation matrix entries

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
- document death / respawn recovery truth for combat ownership
- keep the mechanic participation matrix concrete and current
- prefer docs/spec unless a very narrow runtime proof is justified
- update repo-local slice docs before committing

Avoid:

- `_common.txt` scheduler work
- party or merchant work
- pretending full combat AI is done in one slice
