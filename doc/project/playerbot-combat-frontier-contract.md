# Playerbot Combat Frontier Contract

## Purpose

This document defines the next foundation frontier after the current
observability, perception, reservation, recovery, item, and participation
baseline is green.

It is implementation-facing. The goal is to make the next combat/status/death
work slice concrete enough that later behavior work can layer on top of it
without re-litigating the same recovery rules.

Use this together with:

- `doc/project/playerbot-foundation-program.md`
- `doc/project/playerbot-foundation-priorities.md`
- `doc/project/playerbot-failure-recovery.md`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/playerbot-foundation-smoke.md`

## Current Baseline Truth

The repo already has:

- a green integrated foundation smoke path
- structured trace events
- shared perception queries
- reservation primitives
- recovery audits and unified per-bot incident/timeline surfaces
- transactional item/storage foundations
- NPC, trade, storage, guild, and participation hooks

What is still missing for the next frontier:

- deeper equipment/loadout continuity across death and respawn
- broader mechanic cleanup when combat interrupts an active session
- richer combat/event participation beyond the first legal attack/death/respawn
  hooks
- a more complete matrix for the remaining first-class mechanics that still
  need to behave like normal player paths under combat pressure

## Combat Participation Contract v1

Combat participation is not full combat AI.

For this frontier, "combat participation" means the bot can legally take part
in the combat lifecycle as a server participant, with clear ownership and
cleanup rules.

The first legal combat slice is now present in the repo:

- explicit bot-facing attack start/stop
- target-validity and combat-state reads
- death and respawn trace coverage
- death / respawn recovery audits
- reservation and participation cleanup on death / respawn
- repo-local combat smoke:
  - `tools/ci/playerbot-combat-smoke.sh`

Minimum contract:

- acquire or clear a combat target intentionally
- start or stop combat intent explicitly
- read whether the bot is alive, dead, or respawning
- observe whether a target is still valid before committing to combat intent
- clear stale combat intent when the bot dies, warps, or loses ownership
- emit trace/recovery records when combat intent is denied, aborted, or
  reconciled

Non-goals for this frontier:

- skill rotation logic
- full battle AI planning
- support/heal/assist policy trees
- loot strategy
- path-planning optimization beyond basic attack viability checks

### Combat Authority Rules

The combat frontier should treat these as the primary authorities:

- live world actor state for alive/dead and local combat validity
- controller epoch or owner token for who is allowed to issue intent
- reservation table for contested targets or occupied interaction resources
- persisted runtime state only for recovery and post-restart inspection

The contract should fail closed when those sources disagree.

## Death / Respawn Recovery Truth

Death and respawn are recovery events, not just visual changes.

The bot should not keep stale combat ownership or interaction claims after a
death/respawn transition.

### Required Truth Rules

| Case | Source of truth | Required recovery action | Trace / audit expectation |
| --- | --- | --- | --- |
| Bot dies while in combat | live actor state | clear combat target and any combat intent tied to that actor | `death` or `combat` failure trace plus recovery audit |
| Bot dies while holding a reservation | reservation table + live actor state | release the stale claim or mark it expired during recovery | `reservation.released` plus recovery audit |
| Bot dies during NPC/dialog/storage/trade participation | live session state plus the relevant session authority | close or invalidate the active participation state before allowing a new intent | recovery audit for the affected mechanic |
| Bot respawns with stale combat intent | live actor state | clear stale target/intent before resuming any controller loop | respawn / reconcile trace |
| Bot respawns with stale map or target context | runtime state plus live actor state | prefer live placement and current actor validity over cached intent | reconcile / recovery trace |
| Bot is revived after KO/death | live actor state | re-evaluate target validity and re-arm only if the current controller still owns the actor | recovery trace with explicit reason/result |

### Recovery Order

When a death/respawn event is observed, the recovery order is:

1. trust live actor state
2. clear combat intent first
3. release stale contested claims tied to that actor
4. close invalid participation sessions if they cannot survive the transition
5. reconcile runtime state from the live position/state

The rule is simple:

- if the actor is dead, combat ownership is not still valid
- if the actor respawns, old combat context is not automatically valid

## Mechanic Participation Matrix

This matrix records the current baseline and the next frontier gap for the
remaining first-class player mechanics.

| Mechanic | Current repo truth | Next frontier requirement | Primary authority |
| --- | --- | --- | --- |
| Combat target / attack intent | Not yet surfaced through bot-facing verbs | add explicit attack start/stop and target-validity reads | live actor state |
| Status / buffs / ailments | Engine support exists, but there is no bot-facing continuity contract yet | add status continuity reads and cleanup rules around death/respawn | live actor state |
| Death / KO | Engine support exists; recovery hooks already exist for runtime presence | clear combat and participation state on death | live actor state + recovery audit |
| Respawn / revive | Runtime restore exists for headless presence, but not a combat-frontier contract | reconcile stale combat context after respawn/revive | live actor state + runtime state |
| NPC / dialog / menu | Participation hooks and recovery handling already exist | keep dialog claims from surviving death/warp | reservation/session authority |
| Trade | Participation hooks and rollback/recovery handling already exist | release trade state cleanly when combat/death interrupts the session | trade/session authority |
| Storage | Participation hooks and recovery handling already exist | close or recover storage cleanly across death/warp | storage/session authority |
| Equip / unequip / use / consume | transactional item layer exists; deeper continuity is still thin | preserve legal loadout continuity through respawn without duplicate ownership | transactional inventory state |
| Map change / warp | headless runtime restore and handoff behavior exist | clear combat intent and invalid claims on handoff | live actor state + owner token |
| Guild callbacks | guild participation exists | do not leave stale combat claims across guild-related state changes | live guild state + runtime state |
| Party callbacks | party participation exists | clear or re-evaluate combat support state on party movement/handoff | live party state + runtime state |
| Merchant open / close | merchant participation exists | keep combat/death cleanup from leaving stale merchant ownership | live actor state + merchant runtime |

The matrix is intentionally asymmetric:

- some mechanics already have participation hooks but need combat-safe cleanup
- some mechanics are not yet surfaced as bot-facing combat verbs at all
- some mechanics are only partially covered by the current transactional layer

## Contract Boundaries

The frontier is successful when:

- bots can participate in combat lifecycle events without stale state
- death and respawn produce deterministic cleanup and recovery output
- status/combat/death transitions use one explicit authority per failure class
- existing participation hooks do not leak stale claims across combat transitions

The frontier is not successful if:

- combat intent survives death without an explicit reconcile
- respawn reuses stale target or claim state
- mechanic-specific sessions keep running when the actor authority has changed
- recovery decisions require guessing between competing sources of truth

## What This Frontier Does Not Try To Solve

Do not expand this frontier into full AI.

Not included:

- combat rotation planning
- skill build optimization
- party support logic
- loot routing
- merchant economy behavior
- guild politics or social rivalry behavior

Those belong later. This frontier is about legal participation and recovery
truth first.
