# Headless PC Edge Cases

This document tracks the current weird-case matrix for `headless_pc`.

## Current Model

- headless PCs are runtime-only `BL_PC` actors loaded from existing `char_id`
- lifecycle state is map-server in-memory
- completed spawn/remove/reconcile ack history now persists in
  `headless_pc_lifecycle`
- spawn-ready active actors now also persist a minimal runtime ledger row keyed
  by `char_id`
- restore policy is active-only:
  - spawn-ready active actors restore automatically
  - pending spawn/remove remains intentionally lossy across restart
- dev harnesses are:
  - `Headless Smoke`
  - `Headless PC Lab`
- controller policy is now split:
  - owner-checked `headlesspc_owned_*` mutators for normal controllers
  - unowned `headlesspc_*` mutators as explicit admin/operator override tools
- OpenKore is the primary CLI observer
- upcoming scheduler work should assume map-demand gating with a short despawn
  grace period rather than instant hard despawn

## Known Weird Cases

### 1. Character already online on char-server

Symptom:

- spawn request is rejected

Current handling:

- char-server refuses the load
- map-server now auto-queues targeted reconcile and retries the stored spawn
  once when the reject looks like stale online state
- targeted recovery also exists explicitly:
  - `headlesspc_reconcile(char_id)`
  - `headlesspc_reconcileack(char_id)`
  - `headlesspc_reconcileresult(char_id)`

Current limits:

- it only clears state owned by the current map-server or already-detached
  entries
- the automatic lane only covers the pre-spawn reject path
- restart loss still needs explicit reprovision/respawn

### 2. Character already online on map-server

Symptom:

- spawn request reaches map-server for a character already present locally

Current handling:

- request is rejected
- pending spawn state is cleared
- char-server online state is pushed back offline for the rejected headless load
- local reconciliation requests are refused explicitly

### 3. Unsupported companion state

Blocked for now:

- pet
- homunculus
- mercenary
- elemental

Current handling:

- spawn rejected
- pending spawn state cleared

### 4. Pending remove/save window

Symptom:

- actor is no longer visible but final save ACK has not returned yet

Current handling:

- `headlesspc_status(char_id)` returns pending remove/save
- `headlesspc_ack(char_id)` does not increment until final save ACK returns

### 5. Restart during active headless runtime

Symptom:

- map-server and/or char-server restarts while headless PCs are active

Current handling:

- spawn-ready active actors persist one row in `headless_pc_runtime`
- restore runs automatically from `chrif_on_ready()`
- restore uses persisted runtime `map/x/y`
- stale online state during restore reuses the existing reconcile-and-retry lane
- a dev-only manual replay surface also exists:
  - `headlesspc_restoreall()`

Current limits:

- restore is active-only; pending lifecycle is still intentionally lossy
- ack/history is still in-memory and resets on restart
- this is runtime presence durability, not full bot persistence

### 6. Restart during pending remove/save

Symptom:

- remove requested, but final save ACK not observed before restart

Current handling:

- remove deletes the durable runtime row immediately when accepted
- restart before final save ACK will not resurrect the actor
- in-memory pending/ack tracking is still lost

Current limit:

- remove/save ack history still resets on restart

### 7. Spawn-ready path fails before visibility

Examples:

- `map_addblock(sd)` failure
- other world-load failure after raw load but before ready state

Current handling:

- spawn-ready ack does not increment
- actor may exist in a partial failed state and requires manual investigation

Required future work:

- explicit spawn-failure completion path
- cleanup/reconciliation for partial bring-up

### 8. Duplicate spawn requests

Current handling:

- blocked while pending spawn exists
- blocked while live actor exists

### 9. Remove request against non-headless live player

Current handling:

- refused explicitly
- warning emitted

This is intentional and should remain a hard guard.

### 10. Ack/history persistence

Current handling:

- completed spawn/remove/reconcile ack sequences persist in
  `headless_pc_lifecycle`
- reconcile result persists there as well
- script surfaces now fall back to the persisted lifecycle row after restart:
  - `headlesspc_spawnack(char_id)`
  - `headlesspc_ack(char_id)`
  - `headlesspc_reconcileack(char_id)`
  - `headlesspc_reconcileresult(char_id)`

Current limits:

- pending request state is still in-memory only
- request sequence counters are bootstrapped from persisted ack maxima on ready,
  but no per-request journal exists yet

### 12. First control primitive

Current handling:

- one minimal control primitive exists:
  - `headlesspc_setpos(char_id, map$, x, y)`
- it only succeeds for an active local headless actor
- it refuses absent, pending, or non-headless live actors
- successful reposition updates the active runtime ledger row immediately

Current limits:

- this is a teleport/reposition primitive, not movement AI
- no waypointing, follow logic, or autonomous behavior is attached to it

### 13. First walk primitive

Current handling:

- one minimal walking primitive exists:
  - `headlesspc_walkto(char_id, x, y)`
- it is same-map only and only succeeds for an active local headless actor
- completion is tracked with:
  - `headlesspc_walkack(char_id)`
- runtime position is polled during the walk and written back into
  `headless_pc_runtime`
- completed walk ack history persists in `headless_pc_lifecycle`

Current limits:

- no path planner/controller owns the primitive yet
- timeout/failure clears the pending walk, but there is no separate walk-failure
  result API yet
- this is still operator/script driven movement, not autonomous behavior

### 14. Map empties while controller-owned actors are active

Preferred upcoming handling:

- do not despawn immediately when the last player leaves the map
- use a short grace window so actors can finish a visible beat and avoid harsh
  world popping
- after grace expires, release or park actors cleanly through the scheduler
- do not treat grace expiry as identity deletion

Why:

- instant despawn is technically simple but visually cheap
- a grace window is a better fit for low-pop atmosphere

### 15. Persistent daily-routine actors

Preferred upcoming handling:

- keep a stable provisioned pool of recurring identities
- let only a subset be active at once
- tie recurring presence to schedule/timezone windows where useful
- reuse the same named actors for town, route, and merchant-style routines so
  the server develops familiar faces
- later party/progression systems should reuse those same recurring identities

Current limit:

- current demos are controller-defined and runtime-oriented
- there is not yet a scheduler or routine ledger deciding which recurring actors
  should be active at a given time

### 16. Pooled parked-bot assignment collisions

Symptoms:

- a pooled controller could previously show active slots with misleading owner
  state
- one occupied or reserved pool identity could be silently reused across
  multiple controller slots because every slot shared the same controller owner
  label

Current handling:

- pooled slots now resolve through a slot-level assigned actor id
- pool status display falls back to the pool reservation ledger when runtime
  owner labels are not yet populated
- pool claim is occupancy-aware and only claims currently absent/offline
  identities
- one already-owned pooled identity is no longer reused for multiple slots

Current limits:

- pool ownership is still script-only and resets from config on restart
- scheduler weighting still uses configured actor demand, not live pool supply

### 11. Late observer after restore

Symptom:

- active headless PCs restore successfully after restart
- a client already on-map before restore sees them
- a client that logs in later may not enumerate them correctly

Current handling:

- fixed
- server-side restore replays durable rows correctly
- newly joined observers now enumerate restored headless PCs through the
  nearby-player path

Root cause:

- `clif_getareachar_unit()` advertised standing headless PCs through the idle
  packet path
- late observers needed the spawn-style packet path for socketless `BL_PC`

Fix:

- added a single-target spawn helper in `clif.cpp`
- headless PCs in the late-viewer area-char path now use the spawn packet when
  they are standing still

### 12. In-memory route queue

Current support:

- one lightweight route queue exists on top of `headlesspc_walkto(...)`
- scripts can:
  - clear a route
  - add waypoints
  - start a route with optional looping
  - stop a route
  - query route status
- the route queue is advanced by the existing walk completion poll timer

Current limits:

- routes are in-memory only and do not survive restart
- there is no route-complete summary surface above per-walk event/result
- `setpos` and remove/save clear route state intentionally
- stopping a route halts the current movement and keeps the actor at its last
  reached runtime coordinate

### 13. In-memory ownership layer

Current support:

- active local headless PCs can be claimed by a named controller
- scripts can:
  - claim
  - release
  - query current owner label
- a simple demo controller now uses this layer to keep `codexalt` patrolling
  without manual smoke-menu route setup

Current limits:

- ownership is in-memory only and does not survive restart
- admin/operator override buildins are intentionally not owner-gated
- arbitration is intentionally simple:
  - unowned actor => first claim wins
  - same owner => re-claim succeeds
  - different owner => claim fails
- owner labels are cleared on remove/final save, not persisted in SQL

### 14. Owner-aware mutation policy

Current support:

- normal controller-facing mutation APIs now exist as owner-checked buildins:
  - `headlesspc_owned_remove`
  - `headlesspc_owned_setpos`
  - `headlesspc_owned_walkto`
  - `headlesspc_owned_routeclear`
  - `headlesspc_owned_routeadd`
  - `headlesspc_owned_routestart`
  - `headlesspc_owned_routestop`
- these require the actor to already be claimed by the same owner label

Policy:

- controller scripts should use `headlesspc_claim(...)` and the
  `headlesspc_owned_*` mutators
- GM/dev/operator harnesses may keep using the unowned `headlesspc_*` mutators
  as explicit override tools

Current limits:

- override usage is by convention, not permission system
- there is still no SQL-persisted owner state
- the smoke harness still uses admin/operator override calls intentionally

### 15. Script-side controller framework helpers

Current support:

- shared helper functions now exist for common headless controller patterns:
  - start
  - stop
  - ensure active or spawn
  - prime an owned patrol route from waypoint pairs
- the patrol demo now uses those helpers instead of duplicating the controller
  glue inline

Current limits:

- helpers are still waypoint/patrol oriented
- there is no generic controller registry or template loader
- higher-level behavior policies still live in each controller script

### 16. Small multi-actor controller pattern

Current support:

- one controller can now manage a small fixed set of headless PCs
- shared group stop/release helper exists for owned actors
- the current demo pattern manages:
  - `assa`
  - `codexalt`
  under one controller owner label
- controller definitions can now be registered through shared helpers keyed by
  controller name

Current limits:

- actor data still lives in script `OnInit`, not external data files
- route types are still patrol-waypoint oriented
- the current registry is script-backed, not SQL- or file-backed
- there is no higher-level scheduler/controller directory above the definition
  helper layer

### 17. Escort-style staged movement

Current support:

- one non-patrol controller type now exists
- the escort demo drives a headless PC through one owned escort leg using:
  - `headlesspc_owned_walkto`
  - NPC timer-driven follow-up
- the controller resets the actor to a fixed escort start point before priming
  the run
- the controller releases ownership on the next controller tick after issuing
  the one-way leg

Current support now also includes:

- script-readable `headlesspc_map/x/y` state settles to the escort destination
- `headless_pc_runtime` settles to that same destination tile
- walk completion ack advances only after the movement state settles or is
  committed through the walk-timeout settle path

Current limits:

- the current escort pattern follows a fixed one-way handoff, not a live leader
- success/failure is exposed through walk event/result polling, not a pushed
  event bus
- there is no multi-leg escort choreography yet

### 18. Walk terminal-event surface

Current support:

- scripts can now distinguish success and failure outcomes for headless walks
- available surfaces are:
  - `headlesspc_walkack(char_id)` for success-only completion
  - `headlesspc_walkevent(char_id)` for any terminal walk outcome
  - `headlesspc_walkresult(char_id)` for the last terminal result code
- current result codes are:
  - `arrived`
  - `settled`
  - `start failed`
  - `settle failed`
  - `cancelled`

Current limits:

- walk event/result state is in-memory only and resets on restart
- there is no pushed script callback/event-bus surface yet
- route-level success/failure is still assembled by controllers from per-walk
  events

### 19. Live leader follower controller

Current support:

- one controller can now follow a live regular `BL_PC`, not just fixed patrol
  or escort coordinates
- the current demo:
  - reads leader position from:
    - `livepc_map(char_id)`
    - `livepc_x(char_id)`
    - `livepc_y(char_id)`
  - keeps `codexalt` on a fixed east-of-leader anchor relative to live `codex`
  - reacts to walk event/result completion before issuing another follow leg
  - tracks leader map changes through a visible `handoff_count`
  - uses owned `setpos(...)` as the current map-change handoff policy
  - waits for leader map-change coordinates to settle before computing the
    destination anchor
  - waits if no passable anchor exists yet on the destination map

Validated now:

- a full live leader warp from Prontera to Izlude through `Headless Follow`
- stable follower handoff after the leader's new-map coordinates settle
- passable-anchor selection on the destination map

Current limits:

- cross-map handoff is still a simple reposition, not a full follow transition
- anchor selection is ordered passable-tile fallback, not path-aware routing
- there is no multi-follower formation logic in this controller

### 20. Pair-formation controller

Current support:

- one controller can now maintain a small multi-follower formation around a
  live leader
- the current demo:
  - follows live `codex` (`150001`)
  - claims `codexalt` (`150002`) and `assa` (`150000`)
  - keeps them on two distinct anchors chosen from ordered fallback sets
  - tracks per-follower walk event/result state under one owner label
  - retries the second follower on an alternate fallback set if it collides
    with the first follower's chosen tile
  - uses the same handoff-settling gate as the follower controller

Validated now:

- distinct nearby anchors in an open Prontera patch
- distinct nearby anchors again in the tighter Prontera service patch around
  `153,186`, with:
  - `assa` at `154,187`
  - `codexalt` at `154,186`

Current limits:

- formation size is fixed in script
- blocked or crowded anchors can still exhaust the ordered fallback set
- there is no broader spacing or congestion policy yet
- there is no cross-map formation replay beyond simple owned reposition logic

### 21. Reusable controller kit

Current support:

- the shared script helper layer now supports reusable actor-definition driven
  controllers instead of only one-off demos
- the current reusable action modes are:
  - `hold`
  - `patrol`
  - `loiter`
- the definition layer now handles:
  - actor registration
  - owner-aware activation
  - hold-anchor positioning
  - route priming from waypoint lists
  - route priming from loiter anchor sets
  - shared status summary output

Current limits:

- controller definitions still live in script `OnInit`
- there is no higher-level scheduler yet
- follower and formation remain specialized controllers on top of the shared
  ownership/anchor helpers rather than pure definition-mode controllers

### 22. Alberta merchant/social proof

Current support:

- Alberta now has a dev-only headless social controller proof built on the
  reusable definition kit
- the current proof uses:
  - one anchored market regular in `hold` mode
  - one roaming market actor in `loiter` mode
- the scene is intentionally compact and uses the existing Alberta merchant
  pocket as the anchor area
- the current proof is enough to validate shared actor-definition startup and
  Alberta placement with the existing test-character pool

Current limits:

- this is still a controller-architecture proof, not a full population system
- no chatter/emote layer exists yet for headless actors
- the current proof uses the existing test-character pool, so actor variety is
  constrained by the available characters
- `loiter` now advances through its anchor set through shared walk-state
  tracking, but it is still ordered and deterministic

### 23. Shared loiter progression

Current support:

- `loiter` is now a real shared controller mode, not just a route placeholder
- shared helper state now tracks:
  - current anchor index
  - pending loiter walk
  - last observed walk event
- Alberta validated the current baseline:
  - `codexalt` spawned at the loiter start `44,243`
  - then advanced to `47,246` under the shared helper path

Current limits:

- loiter progression is ordered, not randomized
- there is no schedule- or crowd-aware anchor scoring yet
- chatter/emote output is still separate from controller movement state

## Multi-Actor Coverage

Current reusable manual pair test:

- `assa` (`150000`)
- `codexalt` (`150002`)

Current reusable trio test set:

- `assa` (`150000`)
- `codex` (`150001`)
- `codexalt` (`150002`)

Current fixed CLI observer:

- `codex` via OpenKore, when not used as a headless spawn target

Validated coverage:

- two concurrent headless PCs plus one live observer
- three concurrent headless PCs through the hidden scripted autotest

Current limitation:

- there is still no clean `3 headless + 1 separate live observer` setup using
  only the existing test characters

To test `3` headless PCs with a separate observer, provision at least one more
offline test character.

## Current Policy

- scripts stay procedural
- lifecycle complexity stays in source helpers and typed enums
- `headless_pc` is durable for active runtime presence only
- do not assume absence implies successful save; use ack helpers
- recurring presence should be represented by routine groups with explicit hour
  windows
- scheduler status should surface whether a controller is currently inside or
  outside its routine window

## Scheduler / Pool Observability

### 24. Pool pressure vs simple `<unassigned>`

Current support:

- controller status no longer stops at `<unassigned>`
- pooled controller status now distinguishes:
  - claimable supply
  - ownerless but busy identities
  - identities claimed by the same controller
  - identities claimed by other controllers
  - total pool size

Current limits:

- this remains script-level observability, not a persistent audit trail
- there is still no SQL-backed pool history or operator analytics table

### 25. Detailed status truncation

Current support:

- detailed controller and scheduler status moved into NPC-owned `.status$` vars
  rather than global mapreg-backed strings
- this avoids the old persistence-layer truncation that made richer scheduler
  status unreadable as soon as it grew beyond a short summary

Current limits:

- detailed status is intended for live operator inspection, not long-term
  persistence
- if future slices need durable diagnostics, that should be a separate runtime
  or SQL-backed observability lane

### 26. Scheduler decision reasons

Current support:

- the scheduler now records last-decision reasons such as:
  - selected start
  - selected top-up
  - selected steady
  - blocked by users
  - blocked by actor cap
  - blocked by map cap
  - stopped because not selected

Current limits:

- the decision ledger is still script-global and transient
- it is designed for current operator debugging, not historical reporting

### 27. Provisioning and login-db coupling

Current support:

- the first provisioning workflow inserts login/account and character records
  directly from the map-server side
- this is acceptable in the current dev stack because the login and map/char
  tables live in the same MariaDB database

Current limits:

- this is not yet a cross-database-safe provisioning lane
- if login/char DB separation becomes stricter later, provisioning should move
  behind an inter-server service boundary instead of direct SQL writes

### 28. Party-capable headless invite path

Current support:

- active local headless bots can now accept or decline party invites without a
  client dialog
- v1 policy is driven by:
  - `interaction_policy`
  - `party_policy`
- validated `open` flow joins the bot to the inviter's party through the normal
  runtime path

Current limits:

- only active local headless bots are handled
- `selective` is still treated as decline
- there is no post-join follow/assist/controller reassignment yet

### 29. Selftest timing vs durability

Current support:

- the hidden `PlayerbotSelftest` harness waits for spawn-ready before inviting
- the harness also treats an already-restored active bot as a valid spawn state

Current limits:

- restart durability means the selftest can hit an already-active bot and skip
  a fresh spawn
- this is acceptable for current validation, but future operator tooling should
  distinguish:
  - fresh provision
  - fresh spawn
  - restored active bot
