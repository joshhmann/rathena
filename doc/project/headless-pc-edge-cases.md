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
- there is no separate route-complete ack or route-failure result code
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
