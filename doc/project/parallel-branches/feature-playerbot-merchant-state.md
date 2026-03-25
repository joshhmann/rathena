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
