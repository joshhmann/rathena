# Playerbot Foundation Program

This document turns the remaining playerbot foundation work into one execution
program instead of a loose list of future tasks.

It is the implementation-facing companion to:

- `doc/project/playerbot-foundation-priorities.md`
- `doc/project/roadmap.md`
- `doc/project/backlog.md`

## Execution Shape

Use a `Primary + Parallel` model.

That means:

- one canonical implementation order
- one primary hotspot-owning lane at a time
- small safe side lanes only when they do not compete for the same runtime or
  script hotspots

The primary foundation order is:

1. observability and replayability
2. shared perception / world-query facade
3. reservation and contention primitives
4. explicit state-boundary and recovery contract
5. transactional inventory / equipment / storage foundation
6. broader player-system participation hooks

The next foundation frontier after that wave is defined in:

- `doc/project/playerbot-combat-frontier-contract.md`
- `doc/project/playerbot-mechanic-gap-audit.md`

It covers:

- combat participation contracts
- death / respawn recovery truth
- the remaining first-class mechanic participation matrix
- the unresolved mechanic-participation gaps after combat, loadout, and
  status continuity

## Phase 1: Observability And Replayability

Primary lane:

- implement one append-only structured event model
- emit only the approved first event families
- keep reason and result codes enum-like
- add enough query/view tooling to answer:
  - why a controller was assigned
  - why a bot spawned or parked
  - why a move or interaction failed
  - why a reconcile succeeded or failed

Required outputs:

- trace event schema
- reason/result enum set
- first trace read/query surface
- scenario/timeline-friendly trace trail

Safe side lanes:

- document state-boundary contract
- document failure-recovery authority tables
- improve trace-oriented operator notes

Do not parallelize:

- two lanes touching the same runtime trace hotspots
- trace schema work and replay/viewer work if the event shape is not yet frozen

## Phase 2: Shared Perception And Reservation

Primary lane:

- add one shared read-only perception facade
- move repeated controller-local context reads behind shared queries
- add reservation primitives with explicit lease/lock semantics

Perception v1 should cover:

- self state
- nearby players / bots / NPCs / shops
- anchor state
- local heat
- recent social contacts
- party context
- guild context
- route viability
- interaction target validity

Reservation v1 should cover:

- anchors
- NPC/dialog targets
- social targets
- merchant spots
- party roles

Safe side lanes:

- reservation inspector/operator UI
- perception-query docs and scenario fixtures

Do not parallelize:

- `_common.txt` controller-query migration and runtime reservation ownership work
- two lanes touching the same claim/lease semantics

## Phase 3: Recovery, Transaction Integrity, Participation Hooks

Primary lane:

- formalize partial-failure truth and reconciliation rules
- implement the smallest safe transactional item layer:
  - inventory add/remove
  - equip/unequip
  - storage deposit/withdraw
- add first-class participation hooks for:
  - NPC/dialog/menu flow
  - trade
  - storage
  - equip/use/consume
  - map change/respawn continuity
  - status/death/revive callbacks

Safe side lanes:

- scenario runner growth
- operator diagnostics for failures and stale reservations
- docs for participation contract and invariants

## Phase 4: Combat Participation And Continuity

Primary lane:

- define the first combat-capable playerbot participation boundary
- add bot-facing combat intent and combat-state reads
- add status continuity contract and cleanup rules
- make death / respawn clear stale combat and participation claims
- add trace and recovery audit coverage for combat lifecycle transitions

The implementation-facing contract for this frontier is:

- `doc/project/playerbot-combat-frontier-contract.md`

Safe side lanes:

- combat contract notes
- scenario coverage for combat/death/respawn recovery
- mechanic participation matrix updates
- docs-only gap audits for the next unresolved mechanic-participation work

Do not parallelize:

- combat runtime hotspots with any other active runtime lane
- new combat intent semantics with unrelated scheduler or participation schema changes

## Remaining Mechanic Participation Gaps

See `doc/project/playerbot-mechanic-gap-audit.md` for the next unresolved
mechanic-participation gaps after combat, loadout, and status continuity.
That audit is the authoritative list for the next non-runtime foundation slice.

## Acceptance Gate Before Behavior Expansion

Do not treat the foundation phase as complete until the following are true:

- meaningful controller actions are traceable end-to-end
- controllers share one stable perception facade for the first common queries
- contested anchors/targets/spots/roles use reservation semantics
- persistent/runtime/transient/shared-memory boundaries are documented and
  actually used
- core partial-failure cases have one explicit authority and a reconcile rule
- item/storage mutations are atomic for the first safe slice
- bots can legally participate in first-class player-system flows without
  bespoke one-off shims

## Parallel Work Guidance

Good side lanes while the primary lane is active:

- docs and contract drafting
- test scenario runners
- trace or reservation inspection tooling
- SQL-only schema prep when the interface is already frozen

Bad side lanes while the primary lane is active:

- another lane editing `_common.txt`
- another lane editing the same `src/map/*` bot/runtime files
- schema or interface work that changes the primary lane contract mid-slice
