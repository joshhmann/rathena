# `feature/playerbot-provisioning-schema`

## Goal

Define the first persistent SQL-backed bot identity model instead of relying on
hand-seeded accounts and chars forever.

## Scope

- add initial bot profile tables
- define bot-to-account/char linkage
- document the provisioning workflow
- add checked-in SQL artifacts only; runtime adoption can stay minimal in this slice

## Preferred Files

- `sql-files/main.sql`
- `sql-files/upgrades/*`
- `doc/project/bot-state-schema.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/headless-pc-v1-slice-log.md`

## Avoid

- `_common.txt` controller changes
- map/char runtime changes unless the schema truly needs a tiny surface
- scheduler logic changes

## Acceptance

- repo contains a concrete first bot-profile schema
- SQL upgrade is checked in
- docs explain how provisioning maps to persistent recurring bot identities
