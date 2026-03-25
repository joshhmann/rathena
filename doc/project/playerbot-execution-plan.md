# Playerbot Execution Plan

## Purpose

Turn the current `headless_pc` and playerbot demos into a decision-complete
execution plan that can be worked in parallel without constant merge conflicts.

This plan starts from the current repo state after:

- `headless_pc` lifecycle/durability work
- scheduler/controller demos
- config-backed social controllers
- script-only parked pool assignment

## Current Baseline

Already proven:

- socketless `BL_PC` bring-up
- spawn/remove/reconcile/restore lifecycle
- owner-aware control and routing
- controller demos for patrol, escort, follow, and formation
- scheduler, grace windows, and parked/offline lifecycle
- config-backed social controllers
- script-only parked pool assignment
- OpenKore CLI smoke testing

Still missing:

- scheduler budgeting from real pool supply
- provisioning workflow
- routine/timezone scheduling
- party/combat/merchant semantics
- progression state

## Phase Order

### Phase 1: Scheduler And Pool Hardening

Goal:

- make the scheduler reason from actual assignable supply rather than static
  requested actor counts

Slices:

1. supply-aware scheduler budgeting
2. pool shortage and unassigned-slot visibility
3. operator-safe restore/reconcile/park controls
4. scheduler fairness and anti-thrash cooldowns

Definition of done:

- occupied or unavailable pool identities reduce effective controller supply
- partial controller fills are safe and visible
- park/restore/start/stop remains stable through CLI smoke tests

### Phase 2: Persistent Identity And Provisioning

Goal:

- stop treating seeded accounts/chars as the long-term provisioning model

Slices:

1. SQL schema for:
   - `bot_profile`
   - `bot_identity_link`
   - `bot_appearance`
   - `bot_runtime_state`
   - `bot_behavior_config`
2. bot-to-account/char linkage policy
3. provisioning flow for creating and tagging bots in batches
4. config/controller migration from fixed roster to persistent identity lookup

Definition of done:

- a bot can be provisioned once and later activated without editing NPC scripts
- SQL artifacts fully define the schema and migration path

Current status:

- first persistent identity slice committed:
  - `bot_profile`
  - `bot_identity_link`
  - `bot_appearance`
  - `bot_runtime_state`
- `bot_behavior_config` remains the next schema slice in this phase

### Phase 3: Routine Scheduler And World Presence

Goal:

- make recurring bots behave like recurring world characters, not per-controller
  props

Slices:

1. routine groups and timezone/schedule cohorts
2. world scheduler registry with:
   - global caps
   - per-map soft caps
   - route/travel caps
3. parked/offline recurring pool management
4. multi-map traveler and commuter support
5. regional role-based controller assignment

Definition of done:

- recurring named bots come online/offline by policy
- parking is the normal lifecycle, not deletion
- at least one traveler lane crosses more than one map

### Phase 4: Interaction And Party Foundation

Goal:

- make bots socially usable, not just visible

Slices:

1. interaction policy surface:
   - ambient
   - clickable
   - party candidate
   - merchant candidate
2. invite accept/decline handling
3. follow/assist party controller
4. persistent party-preference and party-state data

Definition of done:

- one bot can be invited and respond predictably
- one follower/assist lane works across handoff and map changes

### Phase 5: Commerce, Combat, And Progression

Goal:

- move from persistent presence to AzerothCore-style recurring playerbot
  characters

Slices:

1. merchant state and fakeplayer/fronted commerce lanes
2. combat/controller goal layer
3. event participation semantics
4. progression state:
   - build tag
   - level/job policy
   - equipment profile
   - activity budget

Definition of done:

- one merchant-capable recurring bot lane exists
- one combat/event lane exists
- at least one recurring bot shows persistent progression state over time

## Parallel Work Lanes

These are the approved parallel-safe work lanes.

### Lane 1: Docs And Slice Logs

Files:

- `doc/project/*`

Safe with:

- every code lane

Hotspot:

- `doc/project/headless-pc-v1-slice-log.md`

### Lane 2: SQL And Persistence Contract

Files:

- `sql-files/main.sql`
- `sql-files/upgrades/*`

Safe with:

- docs
- most NPC-only demo work

Unsafe with:

- runtime lifecycle changes that alter the meaning of persisted data

### Lane 3: Char-Server Protocol

Files:

- `src/char/char_mapif.cpp`
- `src/char/char_mapif.hpp`

Safe with:

- docs
- SQL-only work
- NPC-only work when packet contracts are unchanged

Unsafe with:

- simultaneous map-runtime packet/ack changes

### Lane 4: Map Runtime And Lifecycle Core

Files:

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- spillover:
  - `src/map/pc.cpp`
  - `src/map/clif.cpp`
  - `src/map/map.cpp`

Rule:

- single-owner lane only

This is the highest-conflict hotspot and should not run in parallel with new
protocol or new script-buildin contract work unless one side is read-only.

### Lane 5: Script Buildin Surface

Files:

- `src/map/script.cpp`

Safe with:

- docs
- NPC demo work that only consumes existing buildins

Unsafe with:

- concurrent runtime API changes in `src/map/chrif.cpp`

### Lane 6: NPC Controllers And Demos

Files:

- `npc/custom/playerbot/*.txt`

Safe subset:

- separate demo/controller files can be split by owner

Unsafe subset:

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`

These two are shared script foundations and should stay single-owner during a
slice.

## Recommended Parallel Slice Bundles

Use these bundles when running multiple Codex instances or engineers at once.

### Bundle A: Mainline Foundation

- one owner on runtime or scheduler hotspot work
- one owner on docs/slice-log updates
- one owner on OpenKore regression updates

### Bundle B: Persistence Push

- one owner on SQL/schema
- one owner on provisioning/docs
- one owner on NPC demo updates that only consume a frozen interface

### Bundle C: Interaction Push

- one owner on party/runtime semantics
- one owner on party-state schema/docs
- one owner on follow/assist controller scripts and smoke tests

## Validation Rule

Every non-trivial slice must leave behind:

- repo-local documentation
- SQL artifacts if persistence changes
- CLI validation first
- desktop-client validation for visual or interaction-heavy slices

Minimum validation matrix:

1. `map-server` / `char-server` restart cleanly
2. OpenKore smoke test covers the new slice
3. slice log records:
   - goal
   - files touched
   - runtime changes
   - validation
   - deferrals

## Defaults And Assumptions

- `headless_pc` remains the runtime primitive layer.
- Controllers remain script-first until a slice proves source promotion is
  necessary.
- Persistent bot identity is never deleted as part of normal parking/offline
  behavior.
- Scheduler and pool hardening is the next blocking foundation phase.
- Another Codex instance is acceptable if it stays within a disjoint work lane.
