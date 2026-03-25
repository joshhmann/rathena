# `feature-playerbot-merchant-state`

## Goal

Define the first persistent merchant-capable bot state and runtime policy.

## Scope

- merchant bot role/state design
- stock/profile tables or schema notes
- online/offline merchant behavior policy
- keep economy semantics separate from general social controllers

## Preferred Files

- `doc/project/bot-state-schema.md`
- `doc/project/pseudo-player-architecture.md`
- `sql-files/main.sql`
- `sql-files/upgrades/*`

## Avoid

- `_common.txt` scheduler edits
- party/combat runtime work
- changing existing social controller behavior in this slice

## Acceptance

- merchant-capable bot state is explicitly modeled in repo docs or schema
- branch does not regress current social scheduler/controller behavior

## Codex Prompt

Use this branch brief as the source of truth.

Read first:

- `doc/project/parallel-branch-workmap.md`
- `doc/project/parallel-branches/feature-playerbot-merchant-state.md`
- `doc/project/bot-state-schema.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/headless-pc-v1-slice-log.md`

Do:

- model the first merchant-capable bot state and merchant role policy
- prefer docs/schema first
- add SQL artifacts if schema changes are made
- update repo-local slice docs before committing

Avoid:

- `_common.txt` scheduler edits
- party or combat semantics
- destabilizing current social controller behavior
