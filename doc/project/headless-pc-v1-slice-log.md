# Headless PC V1 Slice Log

This file records how each `headless_pc_v1` slice is implemented.

Subsystem naming:

- technical/runtime subsystem: `headless_pc`
- broader future feature lane: `playerbot`

## Entry Format

For every slice, record:

- goal
- files touched
- runtime path changes
- validation
- deferrals

## Slice 1: Inert Headless BL_PC Bring-Up

### Goal

Prove one socketless, `BL_PC`-backed actor can be loaded from an existing
`char_id`, become world-visible, and be cleanly removed through a dev-only
harness.

### Files Touched

- `src/char/char_mapif.cpp`
- `src/char/char_mapif.hpp`
- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/clif.cpp`
- `src/map/clif.hpp`
- `src/map/pc.cpp`
- `src/map/pc.hpp`
- `src/map/script.cpp`
- `npc/scripts_custom.conf`
- `npc/custom/living_world/headless_pc_lab.txt`
- `npc/custom/living_world/headless_pc_smoketest.txt`

### Runtime Path Changes

- Added an explicit runtime marker on `map_session_data::state`:
  - `headless_bot`
- Added a new map-server to char-server packet path:
  - `0x2b30` request raw character load by `char_id`
  - `0x2b31` reply with success flag, `char_id`, and `mmo_charstatus`
- Added map-side pending spawn request tracking keyed by `char_id`
- Added a headless bring-up path that:
  - allocates `map_session_data`
  - calls `pc_setnewpc()`
  - marks the actor as headless
  - feeds a loaded `mmo_charstatus` into `pc_authok()`
- Kept char-server authoritative for loading the status row
- Added a world-only load completion path:
  - `clif_headless_pc_load()`
- Updated readiness callbacks so headless PCs finish loading when `pc_loaded`
  becomes true, without waiting for client `LoadEndAck`
- Added dev-only script buildins:
  - `headlesspc_spawn(char_id, map$, x, y)`
  - `headlesspc_remove(char_id)`
- Added a dev-only in-game harness:
  - `Headless PC Lab` in Prontera
- Added a fixed smoke harness:
  - `Headless Smoke` in Prontera
- Fixed the headless readiness path by registering the temporary headless `sd`
  in the player ID DB before async registry/state replies arrive
- Kept cleanup on failed auth by removing the temporary `sd` from the ID DB

### Validation

- full rebuild completed successfully
- `login-server`, `char-server`, and `map-server` restarted successfully
- `map-server` loaded the new lab NPC without parser/runtime startup errors
- OpenKore was able to trigger `Headless Smoke`
- headless `codexalt` completed:
  - raw char load
  - registry load
  - status-change load
  - world-only load completion
- OpenKore nearby player list confirmed `codexalt` became visible in Prontera at
  `160,186`

### Root Cause Fixed

The first version of the slice could create a headless runtime object but not
make it visible.

Root cause:

- async registry replies were routed through `chrif_auth_check(...)` or
  `map_id2sd(account_id)`
- the temporary headless `sd` was not yet discoverable there
- so `pc_reg_received()` never fired, which blocked `pc_scdata_received()`,
  `pc_loaded`, and `clif_headless_pc_load()`

Fix:

- insert the headless `sd` into the player ID DB before `pc_authok()` requests
  registry/state follow-up loads

### Deferrals

This slice does not implement:

- combat
- AI/controller logic
- party semantics
- merchant semantics
- persistence tables for bot metadata
- restart recovery
- client-packet owner initialization for headless PCs

This slice also intentionally rejects characters with active companion state:

- pet
- homunculus
- mercenary
- elemental

## Slice 2: Safe Remove And Lifecycle Status

### Goal

Harden the inert headless-PC lifecycle so remove operations only target
headless actors and the dev harness can report lifecycle state directly.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/custom/living_world/headless_pc_lab.txt`
- `npc/custom/living_world/headless_pc_smoketest.txt`

### Runtime Path Changes

- Added a small lifecycle status enum for `headless_pc`:
  - absent
  - pending spawn
  - active
  - pending remove/save
  - occupied by a non-headless live player
- Added `headlesspc_status(char_id)` as a dev-only script buildin.
- Added a map-side `headlesspc_logout_requests` set so pending remove/save state
  is visible before final save ACK returns.
- Updated `headlesspc_remove(char_id)` so it refuses to call `map_quit()` on a
  non-headless live player.
- Cleared pending remove/save state when `ST_LOGOUT` auth nodes are deleted.
- Extended both dev harness NPCs so the lifecycle state can be checked in-game.

### Validation

- source build completed successfully through the normal restart flow
- `map-server` loaded the updated dev harness scripts without parser errors
- OpenKore verified the fixed smoke harness end-to-end:
  - `Spawn codexalt`
  - `Status codexalt` -> `active`
  - nearby player list shows `codexalt`
  - `Remove codexalt`
  - `Status codexalt` -> `absent`
  - DB `char.online` returns to `0`

### Deferrals

This slice still does not implement:

- automated retry/recovery for stale logout state across restart
- generalized lifecycle assertions outside the dev harness
- party, merchant, combat, or controller behavior

## Slice 3: Remove/Save Completion Ack

### Goal

Expose a dedicated completion signal for headless remove/save so scripts can
tell the difference between:

- remove requested
- actor absent from the world
- final save ACK completed

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/custom/living_world/headless_pc_lab.txt`
- `npc/custom/living_world/headless_pc_smoketest.txt`

### Runtime Path Changes

- Added a monotonic per-character remove request sequence on the map side.
- Captured the final completed remove/save sequence when `chrif_save_ack()`
  returns from char-server.
- Added `headlesspc_ack(char_id)` as a script buildin.
- Extended the lab and smoke harnesses to show the last completed ack sequence.

### Validation

- full rebuild completed successfully
- server restart completed successfully
- OpenKore verified:
  - `Ack codexalt` returns `0` before removal
  - `Spawn codexalt` keeps ack at `0`
  - `Remove codexalt` triggers logout/save
  - `Ack codexalt` returns `1` after final save completion
  - DB `char.online` returns to `0`

### Deferrals

This slice still does not implement:

- a dedicated spawn completion ack
- ack/history persistence across restart
- generalized wait primitives beyond the dev harness

## Slice 4: Spawn-Ready Completion Ack

### Goal

Expose a dedicated completion signal for headless spawn so scripts can tell the
difference between:

- spawn requested
- actor loaded internally
- actor actually world-visible and ready

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/clif.cpp`
- `src/map/script.cpp`
- `npc/custom/living_world/headless_pc_lab.txt`
- `npc/custom/living_world/headless_pc_smoketest.txt`

### Runtime Path Changes

- Added a monotonic per-character spawn request sequence on the map side.
- Added a completed spawn-ready ack sequence.
- Marked spawn-ready completion from `clif_headless_pc_load()` after:
  - `map_addblock(sd)`
  - `clif_spawn(sd)`
- Added `headlesspc_spawnack(char_id)` as a script buildin.
- Extended the lab and smoke harnesses to show the last completed spawn-ready
  ack sequence.

### Validation

- full rebuild completed successfully
- server restart completed successfully
- OpenKore verified:
  - `Spawn Ack codexalt` returns `0` before spawn
  - `Spawn codexalt` queues the request
  - `Spawn Ack codexalt` returns `1` only after the actor is visible
  - nearby player list shows `codexalt`

### Deferrals

This slice still does not implement:

- persistence of ack/history across restart
- generalized wait primitives beyond the dev harness
- higher-level bot controller semantics

## Slice 5: Multi-Actor Smoke And Failed-Spawn Cleanup

### Goal

Harden the dev lifecycle surface around the three observability helpers by:

- clearing stale pending spawn state on early bring-up failures
- covering pair and trio spawn/remove flows
- documenting the weird-case matrix explicitly

### Files Touched

- `src/map/chrif.cpp`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added a small helper in `chrif.cpp` to clear pending spawn bookkeeping when a
  headless spawn fails before activation.
- Applied that cleanup on:
  - char-server reject
  - malformed reply size
  - already-online local conflict
  - unsupported companion state
  - invalid target map
  - `pc_authok()` failure
- Expanded `Headless Smoke` with:
  - pair spawn/remove
  - trio spawn/remove
  - aggregate status reporting
  - aggregate spawn/remove ack reporting
- Added a hidden timed trio autotest path in the smoke script, kept disabled by
  default after validation.

### Validation

- full rebuild completed successfully
- server restart completed successfully
- scripted trio autotest proved:
  - all three characters logged in as headless `BL_PC`s
  - statuses reached `active` for all three
  - spawn-ready acks incremented independently:
    - `assa=1`
    - `codex=2`
    - `codexalt=3`
  - all three removed cleanly
  - statuses returned to `absent`
  - remove/save acks incremented independently:
    - `assa=1`
    - `codex=2`
    - `codexalt=3`
- DB state after the autotest returned all three characters to `online = 0`
- saved positions were updated to the scripted trio coordinates, proving the
  save path completed for each actor

### Deferrals

This slice still does not implement:

- restart recovery or reconciliation for active headless PCs
- durable ack/history persistence
- multi-actor visibility verification with a separate fourth observer

## Slice 6: Targeted Reconcile For Stale Online State

### Goal

Add a non-restart recovery lane for the common stuck case where char-server
still believes a headless character is online even though no local runtime actor
exists anymore.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `src/char/char_mapif.cpp`
- `src/char/char_mapif.hpp`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added a targeted reconcile request packet:
  - `0x2b32` map -> char request by `char_id`
  - `0x2b33` char -> map result reply
- Added map-side reconcile tracking:
  - request sequence
  - completed ack sequence
  - last result code
- Added script buildins:
  - `headlesspc_reconcile(char_id)`
  - `headlesspc_reconcileack(char_id)`
  - `headlesspc_reconcileresult(char_id)`
- Guarded reconcile requests so they are refused when:
  - a local live actor already exists
  - a spawn is pending
  - a remove/save is pending
- Limited char-server reconciliation to online entries owned by:
  - the requesting map-server
  - or detached/offline-in-transition entries
- Expanded `Headless Smoke` with reconcile menu options and result views.

### Validation

- full rebuild completed successfully
- server restart completed successfully
- hidden smoke validation proved:
  - reconcile against an already-clear offline `char_id` succeeds as a request
  - reconcile ack increments
  - reconcile result returns `already clear`
  - spawning `codexalt` still works
  - reconcile against a local live headless actor is refused immediately
  - refusal result returns `refused: local live actor exists`
  - remove/save still completes and DB returns `online = 0`

### Deferrals

This slice still does not implement:

- automatic restart reconciliation
- durable lifecycle ledger across restart
- verified reproduction of a true stale-online entry from a map-server crash
- recovery of runtime actor state after reconciliation

## Slice 7: Automatic Reconcile-And-Retry On Spawn Reject

### Goal

Eliminate the manual two-step for the common stale-online bring-up failure:

- spawn rejected by char-server
- manual reconcile
- manual respawn

The runtime should keep the original spawn intent and retry automatically once
reconcile succeeds.

### Files Touched

- `src/map/chrif.cpp`
- `src/char/char_mapif.cpp` (temporary validation hook only, removed before commit)
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added internal packet helpers for:
  - headless spawn request
  - headless reconcile request
- When `0x2b31` returns a rejected headless load:
  - keep the original spawn request in memory
  - queue a reconcile request automatically if the actor is not locally present
    and no remove/save is pending
- When `0x2b33` returns:
  - if result is `reconciled` or `already clear`
  - and the original spawn request is still pending
  - retry the original spawn automatically
- If reconcile returns a hard refusal or invalid character result while a spawn
  request is pending, the pending spawn is cleared.

### Validation

- full rebuild completed successfully
- server restart completed successfully
- validated with a temporary one-shot forced reject for `codexalt`
- observed runtime sequence:
  - initial spawn request queued
  - forced char-server reject
  - automatic reconcile queued by map-server
  - reconcile result `already clear`
  - automatic spawn retry
  - `codexalt` became active and world-visible
  - spawn-ready ack incremented to `1`
- removed the temporary forced-reject validation hook before committing
- left the hidden smoke controller disabled after validation

### Deferrals

This slice still does not implement:

- multi-retry backoff logic
- durable retry intent across restart
- automatic respawn after restart loss
- recovery of runtime actor state that was already live at crash time

## Slice 8: Active-Only Restart Durability

### Goal

Persist the set of spawn-ready active headless actors and restore them
automatically after map/char readiness, without making pending spawn/remove
durable.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260322.sql`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added a minimal SQL runtime ledger table:
  - `headless_pc_runtime`
  - keyed by `char_id`
  - stores runtime `map_name`, `x`, `y`, and `state`
- Added internal helpers in `chrif.cpp` to:
  - upsert a runtime row when a headless actor reaches spawn-ready
  - delete a runtime row when removal is accepted or logout/save completes
  - replay the persisted active set through the existing headless spawn path
- Wired automatic restore into `chrif_on_ready()`, so restore runs after:
  - initial startup
  - later char-server reconnect
- Kept restore active-only by design:
  - pending spawn never writes a runtime row
  - remove deletes the runtime row immediately, before `map_quit()`
- Added a dev-only buildin:
  - `headlesspc_restoreall()`
- Extended `Headless Smoke` with a manual “Restore persisted active set” path
  that uses the same restore helper as automatic startup restore.

### Validation

- full rebuild completed successfully
- database upgrade applied cleanly for the new runtime ledger table
- server restart completed successfully
- validated with OpenKore and the smoke harness:
  - spawned active headless actors and confirmed runtime rows were written
  - removed a headless actor and confirmed the runtime row was cleared before
    final save ACK
  - restarted map-server and confirmed persisted active actors were re-queued
    automatically from `chrif_on_ready()`
  - confirmed stale online state during restore still flows through the
    existing reconcile-and-retry lane
  - confirmed manual `headlesspc_restoreall()` reuses the same replay logic and
    does not duplicate already-active actors
- additional finding:
  - restored headless PCs came back server-side and were logged in again
  - a later-joining OpenKore observer did not enumerate them in `pl`
  - treat that as a separate late-viewer visibility bug, not a restore-ledger
    failure

### Deferrals

This slice still does not implement:

- durable persistence for pending spawn/remove
- durable spawn/remove/reconcile ack history
- player-facing restore/reset ownership rules
- full bot provisioning or controller persistence above the runtime ledger
- late-join observer visibility after restore

## Slice 9: Late-Observer Visibility After Restore

### Goal

Fix the remaining visibility bug where restored headless PCs were active
server-side but not enumerated for a client that logged in later.

### Files Touched

- `src/map/clif.cpp`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added a single-target spawn helper in `clif.cpp` so the spawn packet can be
  sent to one observer instead of only through the normal area broadcast path.
- Updated `clif_getareachar_unit()` so standing headless PCs use the targeted
  spawn packet path when they are introduced to a late observer.
- Kept walking actors on the existing walking packet path.
- Left ordinary live PCs and non-PC units on the existing idle path.

### Validation

- rebuilt `map-server` successfully
- restarted the server stack
- let the durable runtime set restore active headless actors:
  - `assa` at `prontera 156 184`
  - `codexalt` at `prontera 160 186`
- logged in OpenKore later as `codex`
- `pl` enumerated all expected nearby actors:
  - `assa`
  - `codexalt`
  - `Road Tester`

### Deferrals

This slice still does not implement:

- movement-specific late-viewer fixes beyond the existing walking path
- client-specific visual validation beyond OpenKore and prior desktop checks
- any broader refactor of the PC area-char enumeration pipeline

## Slice 10: Durable Lifecycle Ack History

### Goal

Make completed lifecycle history survive restart so the headless smoke surface
can still answer:

- last spawn-ready ack
- last remove/save ack
- last reconcile ack
- last reconcile result

even after in-memory runtime maps have been wiped.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260323.sql`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added a new SQL table:
  - `headless_pc_lifecycle`
- Persisted lifecycle completions there:
  - spawn-ready ack from `chrif_headlesspc_mark_spawn_ready()`
  - remove/save ack from `chrif_save_ack()`
  - reconcile ack/result from `chrif_headlesspc_reconcile_reply()`
- Added DB fallback reads in the public query helpers:
  - `headlesspc_spawnack(char_id)`
  - `headlesspc_ack(char_id)`
  - `headlesspc_reconcileack(char_id)`
  - `headlesspc_reconcileresult(char_id)`
- Bootstrapped the next request sequence counters from the persisted ack maxima
  during `chrif_on_ready()` so post-restart sequence numbers do not restart from
  `1`.

### Validation

- rebuilt `map-server` successfully
- applied [upgrade_20260323.sql](/root/dev/rathena/sql-files/upgrades/upgrade_20260323.sql)
- removed and reconciled `codexalt`, then confirmed SQL state:
  - spawn ack `2`
  - remove ack `1`
  - reconcile ack `1`
  - reconcile result `already clear`
- restarted the full stack
- logged back in with OpenKore and confirmed `Headless Smoke` still reported:
  - `codexalt spawn-ready ack seq: 2`
  - `codexalt remove/save ack seq: 1`
  - `codexalt reconcile ack seq: 1`
  - `codexalt reconcile result: already clear`

### Deferrals

This slice still does not implement:

- durable pending-request journaling
- restart restoration of in-flight request intent
- operator-facing lifecycle history beyond the dev harness

## Slice 11: First Headless Control Primitive

### Goal

Add the first real runtime control primitive on top of inert `headless_pc`
without opening the full behavior/AI scope.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added:
  - `chrif_headlesspc_setpos(char_id, map, x, y)`
  - script buildin `headlesspc_setpos(char_id, map$, x, y)`
- Implementation rules:
  - only active local headless PCs can be repositioned
  - absent actors are refused
  - non-headless live players are refused
  - pending spawn/remove actors are refused
- The primitive reuses `pc_setpos(...)` and updates the active runtime ledger
  row immediately after a successful move.

### Validation

- restored `codexalt` as an active headless actor
- used `Headless Smoke -> Move codexalt east`
- the smoke NPC returned `codexalt moved to 165,186`
- SQL confirmed the active runtime ledger row updated to:
  - `prontera 165 186`
- the observer no longer saw `codexalt` in the original nearby list, which is
  consistent with the actor having been repositioned away from the observer's
  starting pocket

### Deferrals

This slice still does not implement:

- movement/pathing
- follow/assist behavior
- scheduler/controller ownership
- any autonomous behavior on top of `setpos`

## Slice 12: First Headless Walk Primitive

### Goal

Add the first real on-map movement primitive for `headless_pc` while keeping
controller complexity out of scope.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260323.sql`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added:
  - `chrif_headlesspc_walkto(char_id, x, y)`
  - script buildin `headlesspc_walkto(char_id, x, y)`
  - script buildin `headlesspc_walkack(char_id)`
- Added map-side walk request tracking:
  - pending target coordinates
  - pending request sequence
  - completed walk ack sequence
- Added a small poll timer in `chrif.cpp`:
  - watches an active headless actor after `unit_walktoxy(...)`
  - updates `headless_pc_runtime` while movement is in progress
  - marks walk completion only when the actor reaches the requested tile and is
    no longer walking
- Persisted completed walk ack history in:
  - `headless_pc_lifecycle`
- Extended the smoke harness with:
  - `Walk codexalt east`
  - `Walk codexalt center`
  - `Walk Ack codexalt`
  - `Walk Ack all`
- Renamed the older teleport controls in the smoke harness to explicit
  `Setpos` labels.

### Validation

- rebuilt `map-server` successfully
- reapplied [upgrade_20260323.sql](/root/dev/rathena/sql-files/upgrades/upgrade_20260323.sql) to add `walk_ack_seq`
- OpenKore validated the live movement path:
  - `Spawn codexalt`
  - `Walk Ack codexalt` -> `0`
  - `Walk codexalt east`
  - nearby player list later showed `codexalt` at `163,186`
  - `Walk Ack codexalt` -> `1`
- SQL confirmed:
  - `headless_pc_runtime` updated to `prontera 163 186`
  - `headless_pc_lifecycle.walk_ack_seq` updated to `1`
- restarted the full stack
- OpenKore confirmed after restart:
  - `codexalt` restored at `163,186`
  - `Walk Ack codexalt` still returned `1`

### Deferrals

This slice still does not implement:

- a durable pending-walk journal
- explicit walk-failure result codes
- waypoint queues or route following
- any ownership/controller logic above the primitive

## Slice 13: In-Memory Route Queue On Top Of Walk

### Goal

Add a lightweight waypoint queue for active headless PCs so one actor can patrol
multiple points without a script reissuing every individual `walkto`.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added in-memory route state in `chrif.cpp`:
  - waypoint vector
  - next waypoint index
  - loop flag
  - running flag
- Added:
  - `chrif_headlesspc_routeclear(char_id)`
  - `chrif_headlesspc_routeadd(char_id, x, y)`
  - `chrif_headlesspc_routestart(char_id, loop)`
  - `chrif_headlesspc_routestop(char_id)`
  - `chrif_headlesspc_routestatus(char_id)`
- Added script buildins mirroring the same route API.
- Extended the existing walk poll timer so a completed walk automatically starts
  the next waypoint when a route is running.
- Route state is cleared when:
  - the actor is removed
  - final save/remove ack completes
  - `setpos` is used
  - `routeclear` is called explicitly
- `routestop` halts the route and current movement, then persists the current
  runtime position back into `headless_pc_runtime`.

### Validation

- rebuilt `map-server`, `char-server`, and `login-server`
- restarted the stack cleanly
- OpenKore validated the route loop:
  - `codexalt` already active in Prontera
  - `Route status codexalt` -> `empty`
  - `Route codexalt patrol`
  - nearby player list showed `codexalt` move through:
    - `163,186`
    - `160,189`
    - `163,189`
  - `Route status codexalt` -> `running`
- OpenKore validated route stop:
  - `Route stop codexalt`
  - nearby player list showed `codexalt` hold at `163,186` across repeated polls

### Deferrals

This slice still does not implement:

- durable route persistence across restart
- per-route completion or failure ack history
- route editing while already running beyond the simple append semantics
- higher-level controller ownership or scheduling

## Slice 14: First Ownership And Controller Demo

### Goal

Add the first lightweight ownership layer so a named controller can claim a
headless actor, then prove that controller-driven patrol behavior works without
using the smoke harness directly.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/scripts_custom.conf`
- `npc/custom/living_world/headless_pc_controller_demo.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added an in-memory owner label registry in `chrif.cpp`.
- Added:
  - `chrif_headlesspc_claim(char_id, owner$)`
  - `chrif_headlesspc_release(char_id, owner$)`
  - `chrif_headlesspc_owner(char_id)`
- Added matching script buildins:
  - `headlesspc_claim(char_id, owner$)`
  - `headlesspc_release(char_id, owner$)`
  - `headlesspc_owner(char_id)`
- Owner labels are cleared when a headless actor is removed or reaches final
  save/remove ack.
- Added a dev-only demo controller at:
  - `npc/custom/living_world/headless_pc_controller_demo.txt`
- The demo controller:
  - spawns `codexalt` if absent
  - claims ownership as `HeadlessPatrolController`
  - starts the existing Prontera patrol route if not already running
  - releases the actor on stop

### Validation

- rebuilt and restarted the full stack
- OpenKore validated the demo controller path through `Headless Patrol`:
  - `Status` initially showed:
    - `Enabled: no`
    - `Owner: <none>`
    - `Status: 2. Route: 0`
  - `Start codexalt patrol`
  - nearby player list showed `codexalt` move under controller control
  - `Status` then showed:
    - `Enabled: yes`
    - `Owner: HeadlessPatrolController`
    - `Status: 2. Route: 2`
  - `Stop codexalt patrol` disabled the controller cleanly

### Deferrals

This slice still does not implement:

- owner enforcement on every admin/operator buildin
- owner persistence across restart
- multi-controller arbitration beyond simple first-claim wins
- scheduling or behavior trees above the demo patrol loop

## Slice 15: Owner-Aware Mutation Policy

### Goal

Make ownership meaningful by separating normal controller mutation APIs from
explicit admin/operator override APIs.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/custom/living_world/headless_pc_controller_demo.txt`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added owner-checked runtime helpers:
  - `chrif_headlesspc_owned_remove(...)`
  - `chrif_headlesspc_owned_setpos(...)`
  - `chrif_headlesspc_owned_walkto(...)`
  - `chrif_headlesspc_owned_routeclear(...)`
  - `chrif_headlesspc_owned_routeadd(...)`
  - `chrif_headlesspc_owned_routestart(...)`
  - `chrif_headlesspc_owned_routestop(...)`
- Added matching script buildins:
  - `headlesspc_owned_remove(...)`
  - `headlesspc_owned_setpos(...)`
  - `headlesspc_owned_walkto(...)`
  - `headlesspc_owned_routeclear(...)`
  - `headlesspc_owned_routeadd(...)`
  - `headlesspc_owned_routestart(...)`
  - `headlesspc_owned_routestop(...)`
- Existing unowned `headlesspc_*` mutators remain available as explicit
  admin/operator override tools.
- Updated the demo controller to use the owner-checked route APIs instead of the
  override path.

### Validation

- rebuilt and restarted the full stack
- OpenKore validated the controller demo still works after the API split:
  - `Headless Patrol -> Start codexalt patrol`
  - later `Status` showed:
    - `Enabled: yes`
    - `Owner: HeadlessPatrolController`
    - `Status: 2. Route: 2`
  - `Headless Patrol -> Stop codexalt patrol` stopped the route cleanly
- this confirmed the demo controller was able to mutate route state through the
  owner-checked API surface rather than relying on override calls

### Deferrals

This slice still does not implement:

- hard permissioning around who may use the override APIs
- owner persistence across restart
- owner-aware guards for every possible future headless mutation surface

## Slice 16: Script-Side Controller Framework Helpers

### Goal

Stop repeating the same start/stop/spawn/claim/route glue in every controller
script and move that pattern into shared script helpers.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_controller_demo.txt`

### Runtime Path Changes

- Added shared script helpers:
  - `F_LW_HPC_ControllerStart(controller$)`
  - `F_LW_HPC_ControllerStop(controller$, char_id, owner$)`
  - `F_LW_HPC_PrimeOwnedRoute(char_id, owner$, loop, x1, y1, ...)`
  - `F_LW_HPC_EnsureActive(char_id, map$, x, y)`
- Migrated the demo patrol controller onto those helpers:
  - visible NPC now uses shared start/stop helpers
  - hidden controller now uses shared active/spawn and route-priming helpers

### Validation

- restarted the stack cleanly
- OpenKore validated the migrated patrol controller still works:
  - `Headless Patrol -> Start codexalt patrol`
  - later `Status` showed:
    - `Enabled: yes`
    - `Owner: HeadlessPatrolController`
    - `Status: 2. Route: 2`

### Deferrals

This slice still does not implement:

- a generalized multi-actor controller registry
- shared schedule helpers specific to headless controllers
- reusable escort/merchant/event controller templates

## Slice 17: Multi-Actor Controller Pattern

### Goal

Prove one controller can own and maintain a small set of headless PCs cleanly,
not just a single actor.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_group_controller_demo.txt`
- `npc/scripts_custom.conf`

### Runtime Path Changes

- Added shared helper:
  - `F_LW_HPC_ControllerStopGroup(controller$, owner$, char_id...)`
- Added a dev-only multi-actor demo controller:
  - `Headless Pair Patrol`
  - hidden controller `HeadlessPairController`
- The group demo manages:
  - `assa` (`150000`)
  - `codexalt` (`150002`)
- Each actor is:
  - ensured active or spawned
  - claimed by the same owner label
  - assigned an independent owned patrol route

### Validation

- restarted the stack cleanly
- OpenKore validated the pair controller:
  - `Headless Pair Patrol -> Start pair patrol`
  - both `assa` and `codexalt` remained active under one controller owner
  - status reported owner/status/route for both actors

### Deferrals

This slice still does not implement:

- dynamic actor lists loaded from data
- per-actor scheduling within one group controller
- generalized group metrics or health reporting

## Slice 18: Data-Driven Group Controller Shape

### Goal

Move group-controller membership and route definitions into controller data so
future multi-actor controllers stop duplicating per-actor tick blocks.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_group_controller_demo.txt`

### Runtime Path Changes

- Added shared helper:
  - `F_LW_HPC_ControllerReleaseOwned(char_id, owner$)`
- Refactored the pair demo so the hidden controller now defines:
  - actor count
  - actor labels
  - actor `char_id`s
  - spawn map/coordinates
  - route loop flags
  - flattened route arrays with offsets/counts
- Replaced the old per-actor `OnTick` blocks with:
  - one indexed actor tick subroutine
  - one indexed route-prime subroutine
  - one controller-built status summary string for the visible NPC

### Validation

- restarted the stack cleanly
- OpenKore validated:
  - `Headless Pair Patrol -> Start pair patrol`
  - `assa` and `codexalt` both became active and patrolled under the same owner
  - `Status` now reports controller-defined actors through the summary builder
  - `Stop pair patrol` released both actors cleanly

### Deferrals

This slice still does not implement:

- loading actor membership from external data
- a generic registry of controller definitions
- per-actor schedule windows or behavior policies beyond patrol routes

## Slice 19: Generic Controller Definition Registry

### Goal

Create one reusable script-side definition pattern for headless controllers so
future group controllers can load actor membership and route points through
shared helpers instead of inventing their own storage shape.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_group_controller_demo.txt`

### Runtime Path Changes

- Added shared definition helpers backed by dynamic script variables keyed by
  controller name:
  - `F_LW_HPC_DefReset`
  - `F_LW_HPC_DefSetActor`
  - `F_LW_HPC_DefAddRoutePoint`
  - `F_LW_HPC_DefActorCount`
  - `F_LW_HPC_DefBuildStatus`
  - `F_LW_HPC_DefStop`
  - `F_LW_HPC_DefTickActor`
- Refactored `HeadlessPairController` to:
  - register actor definitions on `OnInit`
  - tick actors through the shared definition helper
  - stop/release actors through the shared definition helper
  - build visible status text from the shared definition registry

### Validation

- restarted the stack cleanly
- OpenKore validated:
  - `Headless Pair Patrol -> Start pair patrol`
  - both registered actors became active and patrolled under one owner
  - `Status` still reported both actors correctly through the shared registry
  - `Stop pair patrol` released both actors cleanly

### Deferrals

This slice still does not implement:

- external data-file loading for controller definitions
- a generic scheduler/controller registry above the definition layer
- behavior types beyond patrol-style route ownership

## Slice 20: Escort-Style Controller Demo

### Goal

Prove the controller layer can drive a non-patrol behavior type with a simple
owned escort leg instead of a looping patrol route.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/custom/living_world/headless_pc_escort_demo.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added script-readable position helpers:
  - `headlesspc_map(char_id)`
  - `headlesspc_x(char_id)`
  - `headlesspc_y(char_id)`
- Added a dev-only escort controller:
  - visible NPC `Headless Escort`
  - hidden controller `HeadlessEscortController`
- The escort demo drives `codexalt` through one escort leg:
  - reset to a fixed escort start point on `Start`
  - issue one `headlesspc_owned_walkto(...)`
  - release ownership and disable itself on the next controller tick
- Replaced the hidden-controller follow-up scheduling with an NPC timer instead
  of player-bound `addtimer`
- Added controller-local status reporting for:
  - enabled flag
  - owner
  - actor status
  - walk ack
  - current script-visible map/x/y
  - started state

### Validation

- rebuilt `map-server` successfully
- restarted the stack cleanly
- OpenKore validated:
  - the new `Headless Escort` NPC loads in Prontera
  - starting the escort claims `codexalt`
  - observer-side player list shows `codexalt` on the destination side at
    `166,186`
  - later `Status` reports:
    - `Enabled: no`
    - `Owner: <none>`
    - `Started: no`
  - stopping the escort releases ownership cleanly

### Residual Gap

- the current script-visible `headlesspc_map/x/y` values and runtime ledger
  still report the escort start tile after the observer-side move is visible
- this slice is accepted as a controller-pattern proof, not yet as
  authoritative movement-state proof

### Deferrals

This slice still does not implement:

- following a live leader actor in real time
- multi-leg escort choreography
- escort failure/success events beyond final controller disable

## Slice 21: Walk-State Settling And Escort Telemetry Fix

### Goal

Make script-visible headless-PC position state settle to the same tile that
observers see after `walkto(...)` and escort-leg movement.

### Files Touched

- `src/map/chrif.cpp`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added internal helpers in `chrif.cpp` to read the current headless-PC
  position from `unit_data` exact walk state, falling back to `sd->x/y` when no
  walk state exists.
- Updated headless runtime position readers to use those helpers for:
  - script-visible `headlesspc_x(...)`
  - script-visible `headlesspc_y(...)`
  - spawn-ready runtime upsert
  - `setpos(...)` runtime upsert
  - `routestop(...)` runtime upsert
  - walk poll ledger updates
- Reworked walk completion polling so it no longer depends only on a fixed poll
  count.
- `headlesspc_walkto(...)` now stores a due tick based on
  `unit_get_walkpath_time(...)`.
- If the exact walk state still has not settled by that due tick, the poll path
  commits the final destination tile with `unit_movepos(...)`, then advances the
  walk ack and any queued route state.

### Validation

- rebuilt `map-server` successfully
- restarted the stack cleanly
- OpenKore validated:
  - `Headless Smoke -> Setpos codexalt center`
  - `Headless Escort -> Start codexalt escort`
  - observer-side player list shows `codexalt` at `166,186`
  - later `Headless Escort -> Status` reports:
    - `Current: prontera (166,186)`
    - `Walk Ack: 2626`
- SQL validated:
  - `headless_pc_runtime` row for `150002` settled to `prontera 166 186`
  - `headless_pc_lifecycle.walk_ack_seq` advanced to `2626`

### Deferrals

This slice still does not implement:

- walk-failure result codes beyond timeout settle
- multi-leg escort choreography
- live leader-follow behavior
- evented arrival callbacks beyond existing controller-local logic

## Slice 22: Walk Terminal Events And Live Follower Demo

### Goal

Add explicit walk terminal results for scripts and prove a controller can follow
a live leader instead of only driving fixed patrol or escort legs.

### Files Touched

- `src/map/chrif.cpp`
- `src/map/chrif.hpp`
- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `npc/custom/living_world/headless_pc_follower_demo.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Path Changes

- Added a headless walk terminal-event surface:
  - `headlesspc_walkevent(char_id)`
  - `headlesspc_walkresult(char_id)`
- Added walk result codes in `chrif.hpp`:
  - `arrived`
  - `settled`
  - `start failed`
  - `settle failed`
  - `cancelled`
- Walk terminal events now advance for:
  - exact arrival
  - timeout settle
  - start failure
  - settle failure
  - cancellation from controller/operator interruption
- Kept `headlesspc_walkack(...)` as the success-only sequence while
  `headlesspc_walkevent(...)` represents any terminal outcome.
- Added live regular-PC position readers for script controllers:
  - `livepc_map(char_id)`
  - `livepc_x(char_id)`
  - `livepc_y(char_id)`
- Added a dev-only live-follower controller:
  - visible NPC `Headless Follow`
  - hidden controller `HeadlessFollowerController`
- The follower demo:
  - tracks live leader `codex` (`150001`)
  - claims headless follower `codexalt` (`150002`)
  - keeps the follower on a simple east-of-leader anchor
  - reacts to walk terminal events instead of assuming success

### Validation

- rebuilt `map-server` successfully
- restarted the stack cleanly
- OpenKore validated the new walk event surface:
  - `Headless Smoke -> Setpos codexalt center`
  - `Headless Smoke -> Walk codexalt east`
  - `Walk Event codexalt` advanced
  - `Walk Result codexalt` reported `settled`
- OpenKore validated the live follower controller:
  - `Headless Follow -> Start codexalt follow codex`
  - `codexalt` moved onto the live leader anchor at `156,177`
  - after moving live `codex` to `158,177`, `codexalt` reacquired and moved to
    `159,177`
  - `Headless Follow -> Status` reported:
    - `Leader: prontera (158,177)`
    - `Follower: prontera (159,177)`
    - `Walk Event: 3`
    - `Result: settled`

### Deferrals

This slice still does not implement:

- persistent walk-event history across restart
- formation logic for more than one follower
- path-aware anchor selection beyond a fixed offset

## Slice 23: Leader-Handoff Policy And Pair Formation Demo

### Goal

Make the live-follower controller explicit about leader map handoffs and prove
that one controller can keep more than one claimed headless follower in a small
formation around a live leader.

### Files Touched

- `npc/custom/living_world/headless_pc_follower_demo.txt`
- `npc/custom/living_world/headless_pc_formation_demo.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Extended `HeadlessFollowerController` with explicit leader-handoff tracking:
  - stores `last_leader_map$`
  - increments `handoff_count` when the live leader changes maps
  - surfaces handoff count in `Status`
  - uses the existing owned `setpos(...)` path as the controller handoff policy
    when follower and leader maps differ
- Added a new dev-only pair-formation controller:
  - visible NPC `Headless Formation`
  - hidden controller `HeadlessFormationController`
- The formation controller:
  - follows live leader `codex` (`150001`)
  - claims `codexalt` (`150002`) and `assa` (`150000`)
  - keeps them on two distinct east-of-leader anchors
  - tracks per-follower walk event/result state
  - uses one owner label for both followers

### Validation

- restarted the stack cleanly
- OpenKore validated the pair-formation controller:
  - `Headless Formation -> Start pair follow codex`
  - in an open Prontera patch around `160,186`, the formation held:
    - `codexalt` at `161,186`
    - `assa` at `161,187`
  - returning to the controller area and checking `Status` later also showed
    the pair holding distinct anchors around the live leader:
    - leader `prontera (153,170)`
    - `codexalt` at `154,170`
    - `assa` at `154,171`
- OpenKore also validated the follower controller status surface now includes:
  - explicit `Handoffs`
  - current leader/follower positions
  - current walk terminal result

### Deferrals

This slice still does not implement:

- validated cross-map handoff through a full live leader warp sequence
- collision-aware or fallback anchor selection for blocked tiles
- dynamic formation resizing
- role-specific formations beyond fixed offsets

## Slice 24: Cross-Map Handoff Stabilization And Adaptive Anchors

### Goal

Harden the live follower and formation controllers so they do not reuse stale
leader coordinates after a map change, and make formation anchors adaptive when
the preferred tiles are blocked or crowded.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_follower_demo.txt`
- `npc/custom/living_world/headless_pc_formation_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added shared packed-position helpers:
  - `F_LW_HPC_PackPos`
  - `F_LW_HPC_UnpackX`
  - `F_LW_HPC_UnpackY`
- Added shared adaptive anchor helper:
  - `F_LW_HPC_FindPassableAnchor(map$, base_x, base_y, dx1, dy1, ...)`
- The adaptive anchor helper now:
  - checks candidate offsets with `checkcell(..., cell_chkpass)`
  - returns `0` when no candidate tile is passable
  - no longer falls back blindly to a non-passable base tile
- The follower controller now:
  - tracks the last stable leader `x/y` as well as map
  - treats a leader map change as incomplete until the new coordinates differ
    from the old-map coordinates
  - waits when no passable anchor exists on the destination map
  - exposes a visible `handoff_pending` state
- The formation controller now:
  - uses the same adaptive anchor helper for both followers
  - retries the second follower on a different fallback set if it collides with
    the first follower's chosen tile
  - uses the same handoff-settling gate as the follower controller

### Validation

- restarted the stack cleanly
- OpenKore validated true cross-map follower handoff:
  - `Headless Follow -> Start codexalt follow codex`
  - `Headless Follow -> Warp self to Izlude test`
  - after controller settle, `headless_pc_runtime` showed:
    - `codexalt` on `izlude 154 170`
  - moving the live leader onto that area and listing nearby players showed:
    - `codexalt []` at `155,169`
  - this replaced the previously broken non-walkable handoff onto
    `izlude 156,173`
- OpenKore validated adaptive formation anchors in a tighter Prontera patch:
  - `Headless Formation -> Start pair follow codex`
  - moved live `codex` into the `prontera 153,186` service area
  - nearby player list showed both followers on distinct adjacent anchors:
    - `assa []` at `154,187`
    - `codexalt []` at `154,186`

### Deferrals

This slice still does not implement:

- durable persistence of route/controller state across restart
- richer obstacle avoidance than ordered passable-anchor fallback
- dynamic formation sizing or role-aware spacing

## Slice 25: Reusable Controller Kit And Alberta Social Proof

### Goal

Promote the current script-side controller helpers into a reusable
`headless_pc` controller kit, then prove that the kit can drive a merchant/social
scene in Alberta without writing another bespoke controller from scratch.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_controller_demo.txt`
- `npc/custom/living_world/headless_pc_alberta_social_demo.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Extended the shared actor-definition registry with explicit controller data:
  - actor mode via `F_LW_HPC_DefSetMode(...)`
  - anchor-set registration via `F_LW_HPC_DefAddAnchor(...)`
- The reusable definition layer now supports three controller shapes cleanly:
  - `hold`
  - `patrol`
  - `loiter`
- `F_LW_HPC_DefTickActor(...)` now:
  - enforces ownership
  - handles hold actors through anchored `setpos(...)`
  - primes patrol routes from route points
  - primes loiter loops from anchor sets
  - repositions actors back onto their controller map before restarting routes
- The original single patrol demo now runs through the shared definition kit
  instead of bespoke spawn/claim/route glue.
- Added a new Alberta proof controller:
  - visible NPC `Headless Alberta Social`
  - hidden controller `HeadlessAlbertaSocialController`
  - uses the shared definition kit rather than custom actor logic

### Validation

- rebuilt and restarted the stack cleanly
- existing patrol/follower/formation controllers still loaded without parser
  errors
- OpenKore validated the Alberta proof:
  - `Headless Alberta Social -> Start market traffic`
  - `assa` spawned into the Alberta merchant pocket anchor at `47,245`
  - `codexalt` spawned into the Alberta loiter set start at `44,243`
  - nearby player list showed both actors in Alberta under controller control
  - `Status` reported the shared-mode summary for both actors
- OpenKore also revalidated the single patrol demo after the refactor:
  - `Headless Patrol -> Start codexalt patrol`
  - actor stayed active under the shared registry-based route path

### Deferrals

This slice still does not implement:

- a world/map scheduler above the controller kit
- social chatter/emote policy for headless actors
- data-driven controller definitions outside script `OnInit`
- loiter-state progression beyond the current shared route-priming baseline

## Slice 26: Shared Loiter State Progression

### Goal

Give the reusable controller kit a real `loiter` movement mode so social actors
can advance through anchor sets under shared helper control instead of behaving
like dormant patrol routes.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Extended the shared actor-definition registry with loiter state:
  - current anchor index
  - pending walk flag
  - last observed walk event
- `F_LW_HPC_DefTickActor(...)` now treats `loiter` as its own mode:
  - claims the actor
  - resets loiter state on map mismatch
  - spawns/repositions onto the first anchor when needed
  - waits for walk completion through the existing walk-event surface
  - advances to the next anchor once the actor reaches the current loiter tile
  - queues the next owned `walkto(...)` leg directly instead of relying on
    route status
- Added a stale-route safety check so non-hold actors stop old route state when
  moving back onto the controller's map

### Validation

- rebuilt and restarted the stack cleanly
- OpenKore validated the Alberta social proof after clearing the old runtime set:
  - `Headless Smoke -> Remove pair`
  - `Headless Alberta Social -> Start market traffic`
  - `assa` held the market anchor at `47,245`
  - `codexalt` spawned at the loiter start `44,243`
  - after controller settle, `codexalt` advanced to `47,246`
  - `Status` reported:
    - `assa owner/status/route: HeadlessAlbertaSocialController / 2 / 0 (hold)`
    - `codexalt owner/status/route: HeadlessAlbertaSocialController / 2 / 0 (loiter)`

### Deferrals

This slice still does not implement:

- randomized or schedule-aware loiter decisions
- chatter/emote behavior tied to loiter state
- congestion-aware anchor skipping beyond the current ordered progression

## Slice 27: Seeded Headless PC Provisioning Set

### Goal

Create a fast, repeatable provisioning baseline for multi-actor smoke tests by
seeding ten deterministic bot identities that the current `headless_pc` runtime
can load by `char_id`.

### Files Touched

- `sql-files/upgrades/upgrade_20260323_headless_pc_seed_bots.sql`
- `npc/custom/living_world/headless_pc_smoketest.txt`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added a checked-in dev SQL artifact that seeds ten normal account+character
  pairs:
  - accounts `2000010-2000019`
  - characters `150010-150019`
  - names `BotPc01-BotPc10`
- Kept the seeded characters intentionally simple:
  - novice class
  - level `1/1`
  - offline by default
  - saved in `prontera`
- Documented the current provisioning rule by implementation:
  - `headless_pc` still loads real `char` rows via char-server
  - therefore the quick safe scaffold is real account+character pairs, not raw
    orphan `char` rows
- Extended `Headless Smoke` with batch options for the seeded set:
  - spawn all ten
  - view status/ack state for all ten
  - remove all ten

### Validation

- the SQL seed is idempotent through `INSERT IGNORE`
- the seeded IDs do not overlap the current hand-created test identities
- the smoke harness now has one-click coverage for a ten-PC spawn/remove pass

### Deferrals

This slice still does not implement:

- autonomous bot provisioning from in-game or source APIs
- accountless bot identities
- controller-aware batch provisioning
- richer seeded loadouts beyond the novice baseline

## Slice 28: Shared Social Pulse Hooks

### Goal

Add lightweight social chatter/emote support to the reusable `headless_pc`
controller kit so `hold` and `loiter` actors can feel alive without introducing
combat, schedule logic, or a separate behavior scheduler.

### Files Touched

- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_alberta_social_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added direct script buildins for live headless actors:
  - `headlesspc_talk(char_id, message$)`
  - `headlesspc_emote(char_id, emotion)`
- Extended the shared controller kit with social pools:
  - `F_LW_HPC_DefAddTalk`
  - `F_LW_HPC_DefAddEmote`
  - `F_LW_HPC_DefPulseActor`
- Limited the pulse path to stable social modes only:
  - `hold`
  - `loiter`
- Added low-frequency pulse throttling per actor through a stored next-pulse
  timestamp so controllers do not spam overhead lines or emotions every tick.
- Refactored the Alberta social proof onto the seeded bot identities:
  - `BotPc01`
  - `BotPc02`
  - `BotPc03`
  - `BotPc04`
  - `BotPc05`
- Expanded the Alberta proof from a two-actor setup to:
  - two anchored market regulars
  - three roaming loiter actors

### Validation

- `map-server` rebuilt cleanly with the new buildins
- a real `restart` reload came up cleanly on the updated binary and scripts
- OpenKore validated the refreshed Alberta proof after clearing the old
  hand-created runtime actors:
  - `Headless Smoke -> Remove pair`
  - `Headless Alberta Social -> Start market traffic`
  - nearby player list in Alberta showed:
    - `BotPc01`
    - `BotPc02`
    - `BotPc03`
    - `BotPc04`
    - `BotPc05`
- the visible proof is now running against the seeded provisioning set rather
  than the original `assa/codexalt` pair

### Deferrals

This slice still does not fully prove:

- visual confirmation of overhead chatter/emote pulses in the desktop client
- randomized or schedule-aware social decisions
- congestion-aware social fallback beyond the current ordered anchors
- a second merchant/social controller on top of the same pulse helpers

## Slice 29: Scheduled Social Pulse And Second Social Controller

### Goal

Extend the shared social pulse from a fixed low-frequency hook into a more
useful reusable policy surface, then prove reuse with a second seeded
merchant/social controller on another map.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/headless_pc_prontera_social_demo.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added shared social-pulse definition helpers:
  - `F_LW_HPC_DefSetPulseWindow`
  - `F_LW_HPC_DefSetPulseTempo`
- `F_LW_HPC_DefPulseActor(...)` now supports:
  - optional hour-window gating
  - per-actor randomized min/max pulse tempo
  - per-actor talk-vs-emote weighting
- Kept the feature script-first:
  - no new C++ scheduler
  - no new SQL schema
  - no behavior moved out of the shared controller helper layer
- Added a second seeded controller proof:
  - visible NPC `Headless Prontera Social`
  - hidden controller `HeadlessPronteraSocialController`
  - actors `BotPc06-BotPc10`
  - two hold anchors
  - three loiter actors in the south-square commons

### Validation

- real `restart` reload completed cleanly
- `map-server` loaded `3409` NPCs with the new Prontera controller present
- OpenKore confirmed the new visible controller NPC in Prontera:
  - `Headless Prontera Social` at `148,185`
- OpenKore started the controller and then confirmed the seeded Prontera set:
  - `BotPc06`
  - `BotPc07`
  - `BotPc08`
  - `BotPc09`
  - `BotPc10`
- the Alberta seeded social set remained restorable and active after restart:
  - `BotPc01-BotPc05`

### Deferrals

This slice still does not fully prove:

- desktop-client confirmation of the overhead chatter/emote pulse itself
- cross-controller map-wide scheduling
- more adaptive social routing under crowd pressure
- controller-family folder split for `playerbot` scripts

## Slice 30: Playerbot Script Folder Split

### Goal

Separate the `headless_pc` script lane from the broader `living_world` script
lane so future playerbot controllers have a clear home.

### Files Touched

- `npc/scripts_custom.conf`
- `npc/custom/playerbot/headless_pc_lab.txt`
- `npc/custom/playerbot/headless_pc_smoketest.txt`
- `npc/custom/playerbot/headless_pc_controller_demo.txt`
- `npc/custom/playerbot/headless_pc_group_controller_demo.txt`
- `npc/custom/playerbot/headless_pc_escort_demo.txt`
- `npc/custom/playerbot/headless_pc_follower_demo.txt`
- `npc/custom/playerbot/headless_pc_formation_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Moved the active `headless_pc` and playerbot-facing scripts from
  `npc/custom/living_world/` into `npc/custom/playerbot/`.
- Kept the shared helper surface in:
  - `npc/custom/living_world/_common.txt`
- Updated `npc/scripts_custom.conf` so the live loader now points at the
  `playerbot` folder for the harnesses, demos, and social controllers.
- Preserved the naming split:
  - technical subsystem remains `headless_pc`
  - broader script lane remains `playerbot`

### Validation

- `map-server` restart must load the moved files from
  `npc/custom/playerbot/` with no missing-path or parser failures.
- Existing visible NPC entry points should remain reachable after the move.

### Deferrals

This slice does not change:

- the shared helper location in `living_world/_common.txt`
- any C++ `headless_pc` runtime behavior
- the current OpenKore limitation around honestly observing the social pulse
  live

## Slice 31: Shared Controller Policy Layer

### Goal

Add a reusable script-first controller policy surface so social controllers can
share startup staggering, player-presence gating, and tick cadence.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added shared controller policy helpers:
  - `F_LW_HPC_DefSetTickMs`
  - `F_LW_HPC_DefSetMapGate`
  - `F_LW_HPC_DefSetStartStagger`
  - `F_LW_HPC_ControllerShouldRun`
  - `F_LW_HPC_ControllerScheduleNext`
- `F_LW_HPC_ControllerStart(...)` now respects optional stagger policy stored
  on the controller definition.
- Extended `F_LW_HPC_DefBuildStatus(...)` so controller status shows:
  - gate map and minimum user threshold
  - shared tick cadence
- Alberta and Prontera social controllers now:
  - define their own tick cadence
  - define a simple local player-presence gate
  - stand down owned actors cleanly when their gate map is empty
  - reuse the shared next-tick scheduler instead of hardcoded `addtimer` values

### Validation

- `map-server` must reload cleanly with the updated helper surface.
- Social controllers should still start normally when a player is present on
  the gated map.
- Controller `Status` should report the policy line as part of the summary.

### Deferrals

This slice does not yet add:

- global population caps across multiple controllers
- automatic controller enable/disable from a world-level registry
- per-controller budget arbitration

## Slice 32: Controller Grace Window Policy

### Goal

Replace hard despawn-on-empty behavior with a shared controller grace-period
policy so recurring bots feel parked or cooled down instead of instantly
deleted from the world.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/bot-state-schema.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/headless-pc-v1-phase0.md`
- `doc/project/roadmap.md`
- `doc/project/backlog.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added shared grace-policy definition helper:
  - `F_LW_HPC_DefSetGraceMs`
- Extended shared controller policy state with:
  - configured grace duration
  - active gate cooldown deadline
- `F_LW_HPC_ControllerShouldRun(...)` now behaves as:
  - immediate run when gate map demand is present
  - grace-period run after demand disappears
  - clean stand-down only after grace expires
- `F_LW_HPC_DefBuildStatus(...)` now reports:
  - grace duration
  - whether gate cooldown is currently active
- Alberta and Prontera social controllers now define non-zero grace windows
  instead of dropping bots immediately when their map empties.

### Validation

- `map-server` restart must load the updated helper layer cleanly.
- Social controllers should remain active for one grace window after demand on
  the gated map disappears.
- `Status` should show the new grace policy line.

### Deferrals

This slice does not yet add:

- a parked/offline ledger separate from current runtime presence
- global scheduler ownership of grace windows
- cross-controller grace arbitration

## Slice 33: World Scheduler Demo

### Goal

Add a first world-level scheduler that decides which social controllers should
be active, instead of leaving each controller to run as an isolated demo.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added shared scheduler helpers:
  - `F_LW_HPC_SchedReset`
  - `F_LW_HPC_SchedSetTickMs`
  - `F_LW_HPC_SchedSetCap`
  - `F_LW_HPC_SchedAdd`
  - `F_LW_HPC_SchedBuildStatus`
  - `F_LW_HPC_SchedRun`
  - `F_LW_HPC_SchedNext`
- Added visible scheduler NPC:
  - `Headless Scheduler` at `prontera 148 183`
- Added hidden `HeadlessWorldScheduler` proof controller:
  - tracks registered controllers
  - enforces a global active-controller cap
  - starts only the highest-priority demanded controllers
  - stops the rest
- First registered scheduler targets are:
  - `HeadlessPronteraSocialController`
  - `HeadlessAlbertaSocialController`

### Validation

- `map-server` must reload cleanly with the scheduler helper layer and new demo
  NPC present.
- CLI smoke test should confirm:
  - `Headless Scheduler` is reachable
  - `Status` reports registered controllers and cap/tick policy
  - `Start scheduler` works
  - when only Prontera has a player, Prontera is preferred and Alberta is not

### Deferrals

This slice does not yet add:

- per-map actor caps inside the scheduler
- parked/offline pool accounting
- demand arbitration across more than a tiny fixed controller set

## Slice 34: Scheduler Actor Budgets

### Goal

Make the world scheduler reason about active actor budgets, not only controller
count, so population policy starts mapping to "how many bots" instead of just
"which script is on."

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Extended shared scheduler helpers with actor-budget policy:
  - `F_LW_HPC_SchedSetActorCap`
  - `F_LW_HPC_SchedSetMapCap`
- `F_LW_HPC_SchedAdd(...)` now stores per-controller actor weight.
- `F_LW_HPC_SchedRun(...)` now enforces:
  - controller cap
  - global active-actor cap
  - per-map active-actor cap
- `F_LW_HPC_SchedBuildStatus(...)` now reports:
  - global actor cap
  - each controller's actor weight
  - each controller map's cap
- Updated demo scheduler policy:
  - controller cap `2`
  - global actor cap `5`
  - per-map caps `5`
  - both current social controllers have actor weight `5`

### Validation

- `map-server` must reload cleanly.
- CLI smoke test should confirm:
  - scheduler `Status` shows controller cap, actor cap, and map caps
  - with both Prontera and Alberta demanded, only the higher-priority controller
    remains active because of the actor budget

### Deferrals

This slice does not yet add:

- dynamic actor weights from live controller state
- pooled budgeting across more than one controller per map
- parked/offline pool accounting

## Slice 35: Parked Pool Accounting

### Goal

Make scheduler deactivation actually park recurring bots offline, then expose
active-versus-parked counts so the system starts behaving like a reusable bot
pool instead of leaving stopped actors spawned and ownerless.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added shared controller stop policy:
  - `F_LW_HPC_DefSetStopPolicy`
- `F_LW_HPC_DefStop(...)` now supports:
  - `release`
  - `park`
- Alberta and Prontera social controllers now use:
  - `stop policy = park`
- Added shared live-count helpers:
  - `F_LW_HPC_DefCountActive`
  - `F_LW_HPC_DefCountParked`
- Scheduler status now reports:
  - per-controller live active count
  - per-controller parked count
  - total live active/parked count across the registered scheduler set

### Validation

- `map-server` must reload cleanly.
- CLI smoke test should confirm:
  - scheduler `Status` shows live active/parked counts
  - after scheduler stop, social bots move into parked/offline state rather
    than lingering spawned and ownerless
  - when the scheduler restarts, parked bots respawn back into their controller
    set cleanly
- Scheduler-selected controllers now explicitly invoke `OnTick` for
  rehydration instead of relying only on controller-local start timers, which
  closes the parked-but-not-rehydrated restart gap found during CLI validation.

### Deferrals

This slice does not yet add:

- a dedicated parked/offline SQL ledger beyond current runtime/lifecycle data
- pool sharing across many more controller families
- progression-aware parking decisions

## Slice 36: Script Config Layer For Scheduler And Social Controllers

### Goal

Move scheduler and social-controller policy values out of hardcoded demo bodies
 and into a central script config registry so population caps, gate thresholds,
 grace windows, and pulse schedules can be tuned without rewriting each
 controller.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added shared config helpers:
  - `F_PB_CFG_SetInt`
  - `F_PB_CFG_GetInt`
  - `F_PB_CFG_SetStr`
  - `F_PB_CFG_GetStr`
  - `F_PB_CFG_SetPulseProfile`
  - `F_PB_CFG_ApplyPulseProfile`
- Added central config registry:
  - `npc/custom/playerbot/headless_pc_config.txt`
- Scheduler demo now reads:
  - tick cadence
  - controller cap
  - actor cap
  - per-map caps
  - controller gate/priority/actor-weight values
  from the config registry instead of hardcoded literals
- Alberta and Prontera social demos now read:
  - controller tick
  - gate threshold
  - stagger window
  - grace window
  - stop policy
  - named pulse profiles
  from the same config registry

### Validation

- `map-server` must reload cleanly with the new config script loaded.
- CLI smoke test should confirm:
  - scheduler status still reports the configured cap values
  - Prontera and Alberta controller status still reports the configured
    gate/tick/grace/stop policy values
  - parking and rehydration behavior still works through the scheduler
    after the refactor

### Deferrals

This slice does not yet add:

- SQL-backed scheduler/controller config
- operator-facing hot reload of config values
- data-driven route membership or actor provisioning

## Slice 37: Data-Driven Social Controller Definitions

### Goal

Move social-controller roster membership, anchors, talk/emote pools, and pulse
profile bindings into the central playerbot config layer so controller scripts
focus on runtime policy instead of hand-authoring fixed actor blocks.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added controller-definition config helpers:
  - `F_PB_CFG_DefReset`
  - `F_PB_CFG_DefSetActor`
  - `F_PB_CFG_DefAddAnchor`
  - `F_PB_CFG_DefAddRoutePoint`
  - `F_PB_CFG_DefAddTalk`
  - `F_PB_CFG_DefAddEmote`
  - `F_PB_CFG_ApplyControllerDef`
- Central config now defines:
  - `social.prontera`
  - `social.alberta`
- Alberta and Prontera social controllers now:
  - set runtime policy locally
  - load roster/member/anchor/pulse data from config through
    `F_PB_CFG_ApplyControllerDef(...)`

### Validation

- `map-server` must reload cleanly after the config-definition refactor.
- CLI smoke test should confirm:
  - scheduler status still shows the same actor-weighted population behavior
  - social controller status still shows the same actors and runtime policy
  - stop/park/start behavior is unchanged after the refactor

### Deferrals

This slice does not yet add:

- SQL-backed roster definitions
- role-based dynamic roster selection from a larger parked pool
- controller-local overrides layered on top of a shared base roster

## Slice 38: Script-Only Parked Pool Assignment Layer

### Goal

Let controllers fill social slots from named parked bot pools instead of
hard-binding one fixed `char_id` per controller slot, while keeping the first
pool-allocation layer script-only.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added pool-definition helpers:
  - `F_PB_POOL_Reset`
  - `F_PB_POOL_Add`
  - `F_PB_POOL_Owner`
  - `F_PB_POOL_Claim`
  - `F_PB_POOL_Release`
  - `F_PB_POOL_Available`
- Added config helper:
  - `F_PB_CFG_DefSetPoolActor`
- Added controller helpers:
  - `F_LW_HPC_DefSetPoolActor`
  - `F_LW_HPC_DefActorCharId`
  - `F_LW_HPC_DefResolveActor`
  - `F_LW_HPC_DefReleaseActor`
- Prontera and Alberta social definitions now use named pools:
  - `pool.social.prontera`
  - `pool.social.alberta`
- Controller status, active/parked counting, pulse dispatch, stop, and per-actor
  tick logic now resolve pooled actors through the slot-assignment helper
  instead of assuming every slot has a fixed `char_id`
- Pool allocation is now occupancy-aware:
  - it only claims currently absent/offline identities
  - it no longer reuses one already-owned pooled identity across multiple slots
  - pooled controller status falls back to the pool reservation ledger when the
    runtime owner label has not been set yet

### Validation

- `map-server` reloaded cleanly after the pool-manager changes.
- CLI smoke test with OpenKore confirmed:
  - pooled slots show `<unassigned>` when the controller is stopped
  - starting a pooled social controller assigns and activates available bots
  - pooled status now reports the controller owner correctly
  - if one pool identity is occupied by a normal live player, the controller no
    longer double-assigns or silently reuses that identity across all slots
  - controller status shows only the actually available subset as active, with
    the remainder left unassigned

### Deferrals

This slice still does not add:

- SQL-backed pool ownership or role selection
- scheduler decisions based on real-time pool supply instead of static actor
  weights
- progression-aware choice among many eligible parked identities

## Slice 39: Persistent Bot Identity Schema

### Goal

Commit the first SQL-backed persistent bot identity model so future provisioning
and progression work can build on stable bot records instead of hand-seeded
accounts alone.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260324_playerbot_schema.sql`
- `doc/project/bot-state-schema.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/playerbot-execution-plan.md`

### Runtime Path Changes

- None.
- This slice is schema and docs only.

### Validation

- SQL upgrade file syntax checked against the local dev database.
- Verified the committed schema creates the core bot tables:
  - `bot_profile`
  - `bot_identity_link`
  - `bot_appearance`
  - `bot_runtime_state`

### Deferrals

This slice still does not add:

- bot provisioning workflow
- bot behavior/config tables
- runtime adoption of the new tables
- party, merchant, or combat semantics

## Slice 40: Routine Presence Policy

### Goal

Let the world scheduler drive playerbot presence by routine group and hour
window instead of only by map demand.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/roadmap.md`
- `doc/project/headless-pc-v1-slice-log.md`

### Runtime / Script Path Changes

- Added routine metadata helpers:
  - `F_LW_HPC_DefSetRoutineGroup`
  - `F_LW_HPC_DefSetRoutineWindow`
- Controller readiness now respects routine windows in addition to map gate
  and grace policy.
- Scheduler status now reports each controller's routine group/window and whether
  the current hour is inside or outside that window.
- Prontera and Alberta controllers now read routine presence settings from the
  central config registry:
  - `ctrl.prontera.routine_group = day`
  - `ctrl.prontera.routine_start = 7`
  - `ctrl.prontera.routine_end = 23`
  - `ctrl.alberta.routine_group = night`
  - `ctrl.alberta.routine_start = 0`
  - `ctrl.alberta.routine_end = 6`

### Validation

- Rebuilt the branch worktree cleanly and restarted the tmux-backed dev stack
  from `/root/dev/rathena-routine`.
- OpenKore CLI verified:
  - `Headless Scheduler -> Status` shows Prontera in routine window at hour 22
    and Alberta out of routine window.
  - `Start scheduler` activates the Prontera social controller.
  - `pl` shows the Prontera pooled actors visible in-world.
  - the Alberta social controller remains idle because its routine window is
    closed at hour 22.

### Deferrals

This slice does not yet add:

- SQL-backed routine groups or schedule tables
- timezone conversion or region-aware per-bot scheduling
- persistence of routine windows beyond the script/config layer

## Slice 41: Provisioning, SQL Pools, And Party V1

### Goal

Move the playerbot lane past seeded demo identities by adding:

- a real dev-facing provisioning workflow
- SQL-backed pool loading
- the first narrow party-capable runtime response for active headless bots

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260325_playerbot_provisioning.sql`
- `src/map/script.cpp`
- `src/map/party.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/playerbot_provisioner.txt`
- `npc/custom/playerbot/playerbot_party_lab.txt`
- `npc/custom/playerbot/playerbot_selftest.txt`
- `npc/scripts_custom.conf`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- committed `bot_behavior_config` as the next persistent bot-state table
- added source buildins:
  - `playerbot_profile(bot_key$)`
  - `playerbot_provision(bot_key$, display_name$, template_key$)`
  - `playerbot_partyinvite(char_id)`
  - `playerbot_partyid(char_id)`
- provisioning now creates:
  - account row
  - character row
  - `bot_profile`
  - `bot_identity_link`
  - `bot_appearance`
  - `bot_runtime_state`
  - `bot_behavior_config`
- SQL-backed pool helpers now load eligible identities by `pool_key` instead of
  fixed `F_PB_POOL_Add(...)` rosters
- the first party-capable runtime path now intercepts invites for active local
  `headless_pc` actors and resolves accept/decline from
  `interaction_policy` + `party_policy`
- added dev harnesses:
  - `Playerbot Provisioner`
  - `Playerbot Party Lab`
  - hidden `PlayerbotSelftest`

### Validation

- applied `upgrade_20260325_playerbot_provisioning.sql` to the dev DB
- rebuilt `map-server`
- restarted the stack cleanly with `bash /root/setup_dev.sh restart`
- OpenKore confirmed the new harness NPCs load in Prontera:
  - `Playerbot Provisioner`
  - `Playerbot Party Lab`
- `PlayerbotSelftest` proved the full narrow path for `quick_party_open`:
  - provisioning created `bot_id 11`, `account_id 2000020`, `char_id 150020`
  - the provisioned bot linked into `pool.party.prontera`
  - the headless actor was active locally
  - the runtime party path placed `PBQParty01` into `codex`'s party
- final selftest log:
  - `spawn=0 active=1 invite=0 party_ok=1 bot_party=1 inviter_party=1 status=2 result=1`
  - this is acceptable because restart durability can restore the already-active
    bot before the next selftest cycle

### Deferrals

This slice does not yet add:

- operator-safe account password rotation or non-deterministic credentials
- party follow/assist semantics after join
- selective party policy beyond decline
- SQL-backed route/travel/controller definitions
- merchant or combat use of `bot_behavior_config`

## Slice 42: Role/Profile-Driven Pool Assignment

### Goal

Move pooled controller assignment off anonymous pool membership and onto
persistent bot metadata so controller slots request the kind of recurring bot
they want rather than a fixed seeded name.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/playerbot_provisioner.txt`
- `npc/custom/playerbot/playerbot_party_lab.txt`
- `sql-files/upgrades/upgrade_20260325_playerbot_role_profiles.sql`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- SQL-backed pools now load:
  - `bot_id`
  - `profile_key`
  - `role`
  alongside `char_id`
- pooled controller slots can now declare:
  - desired `profile_key`
  - desired `role`
- pool claim now filters by those desired fields before assigning an identity
- controller status now surfaces desired pool/profile/role for each pooled slot
- seeded recurring social bots were backfilled into more specific role/profile
  groupings:
  - Prontera:
    - `social.prontera.regular` / `square_regular`
    - `social.prontera.wanderer` / `square_wanderer`
  - Alberta:
    - `social.alberta.regular` / `dock_regular`
    - `social.alberta.browser` / `market_browser`
    - `social.alberta.harbor` / `harbor_wanderer`

### Validation

- applied `upgrade_20260325_playerbot_role_profiles.sql`
- restarted the stack cleanly
- verified the seeded recurring bot rows now carry the refined role/profile
  identities in SQL
- verified the hidden party selftest still passes after the allocator changes:
  - `result=1`
- verified the current provisioning assumption against the active dev config:
  - `conf/import/inter_conf.txt`
  - `login_server_db = rathena`
  - `char_server_db = rathena`
  - `map_server_db = rathena`

### Deferrals

This slice does not yet add:

- SQL-backed controller slot definitions
- scheduler selection by role/profile demand beyond current script-defined slots
- automatic migration off direct map-side login-table writes for split-DB setups

## Slice 43: Party Assist V1

### Goal

Add the first narrow post-join party assist behavior so an active party-capable
bot can snap onto a valid adjacent leader anchor after joining, without trying
to solve full continuous follow/assist AI yet.

### Files Touched

- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/playerbot_party_assist.txt`
- `npc/custom/playerbot/playerbot_selftest.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added `partyleadercharid(party_id)` as a script buildin.
- Added a visible dev harness:
  - `Playerbot Party Assist`
- Kept the assist semantics narrow and robust:
  - resolve the current party leader for the active bot
  - find a passable adjacent anchor near the leader
  - claim the bot if needed
  - reposition with `headlesspc_owned_setpos(...)`
- Moved the actual one-shot assist logic into the existing hidden
  `PlayerbotSelftest` harness so validation uses a proven event surface.
- Shortened the config pulse-profile suffix keys used by the playerbot config
  layer to avoid script variable-name overflow during `OnInit`.

### Validation

- restarted the stack cleanly
- verified the startup path no longer blocks on the assist harness
- OpenKore logged in as `codex` and saw the visible assist NPC in Prontera
- OpenKore triggered the visible assist harness
- verified the active party bot runtime row moved from:
  - `prontera 160,186`
  to:
  - `prontera 140,185`
- hidden selftest log proved the assist anchor path:
  - `playerbot_selftest_assist: leader=prontera (139,185) bot=prontera (140,185) target=(140,185) result=1.`

### Deferrals

This slice does not yet add:

- continuous follow loops after join
- assist role behavior in combat
- party-controller reassignment after join
- selective party acceptance beyond current decline behavior

## Slice 44: Merchant State V1

### Goal

Add the first persistent merchant-capable bot state so merchant bots can be
provisioned, inspected, and toggled as recurring identities without pretending
to implement full vending semantics yet.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260325_playerbot_merchant_state.sql`
- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/playerbot_provisioner.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `npc/scripts_custom.conf`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added persistent SQL table:
  - `bot_merchant_state`
- Extended template-driven provisioning with:
  - `merchant.alberta.stall`
- Provisioning now writes merchant metadata alongside:
  - profile
  - identity link
  - appearance
  - runtime state
  - behavior config
- Added SQL-backed merchant summary fields to `F_PB_DB_LoadBotSummary`
- Added SQL-backed merchant toggle helper:
  - `F_PB_DB_SetMerchantState`
- Added a visible dev harness:
  - `Playerbot Merchant Lab`

### Validation

- applied `upgrade_20260325_playerbot_merchant_state.sql`
- restarted the stack cleanly
- provisioned `quick_merc_alb` from `merchant.alberta.stall`
- verified the persistent merchant row in SQL and through the merchant lab
- verified merchant enable/open-state toggles write back through the SQL helper
- verified hidden selftest result:
  - `playerbot_merchant_selftest ... result=1`
- confirmed existing playerbot scripts still load and the party/assist slice did
  not regress

### Deferrals

This slice does not yet add:

- real vending session behavior
- NPC shop or barter attachment to merchant bots
- scheduler-driven merchant open/close automation
- merchant stock depletion or restock logic

## Slice 45: Continuous Party Follow / Assist V1

### Goal

Upgrade the first post-join party assist proof from a one-shot reposition into a
continuous claimed controller that keeps the active party bot near the current
party leader after the join succeeds.

### Files Touched

- `npc/custom/playerbot/playerbot_party_assist.txt`
- `npc/custom/playerbot/playerbot_selftest.txt`
- `npc/custom/living_world/_common.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- `Playerbot Party Assist` now describes a continuous follow/assist lane.
- `PlayerbotSelftest` now runs a timer-driven assist controller instead of a
  one-shot `setpos(...)` path.
- The assist controller now:
  - resolves the current party leader continuously
  - claims the bot through the existing ownership surface
  - keeps the bot near a passable anchor beside the leader
  - uses `headlesspc_owned_walkto(...)` for same-map follow updates
  - uses `headlesspc_owned_setpos(...)` for cross-map/handoff reposition
- The hidden selftest now forces a leader move after join and verifies the bot
  against the expected assist anchor.
- Pool metadata storage now uses compact per-pool indexed prefixes in script so
  pooled profile/role metadata no longer depends on long pool-name variable
  suffixes.

### Validation

- restarted the stack cleanly
- confirmed the new assist-path errors are gone:
  - no `npc_event: event not found`
  - no `buildin_addtimer: fatal error ! player not attached!`
- OpenKore still logged into Prontera on the updated slice
- the hidden assist selftest forced the leader move from:
  - `prontera (139,185)`
  to:
  - `prontera (144,185)`
- map-server assist logs showed the bot tracking onto the assist anchor at:
  - `prontera (145,185)`

### Deferrals

This slice does not yet add:

- richer assist roles after join
- combat-aware support behavior
- party reassignment from the world scheduler
- cleanup of the remaining long config-key `set_reg` noise in the playerbot
  config registry

## Slice 46: Playerbot Config Key Cleanup

### Goal

Remove the remaining playerbot config-registry startup noise caused by long
script global variable names, while keeping the readable config structure in the
project files.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Shortened the live scheduler/controller config keys used by the script-side
  playerbot config registry:
  - world scheduler keys now use compact `sw.*` forms
  - Prontera controller keys now use compact `cp.*` forms
  - Alberta controller keys now use compact `ca.*` forms
- Updated the active controller and scheduler scripts to read the new compact
  keys.
- Kept provisioning template keys under `tp.*` unchanged so the source-backed
  provisioning path in `script.cpp` does not need a schema or runtime refactor.

### Validation

- restarted the stack cleanly
- confirmed the playerbot config startup noise is gone:
  - no `set_reg: Variable name length is too long` from `$PBCFG_*`
- confirmed the merchant selftest still runs at startup:
  - `playerbot_merchant_selftest ... result=1`

### Deferrals

This slice does not yet add:

- broader config normalization outside the scheduler/controller key families
- migration of all controller definitions into SQL-backed config

## Slice 47: SQL-Backed Controller Registry And Merchant Demo

### Goal

Move the active playerbot controller layer off script-owned controller
definitions and onto checked-in SQL-backed policy and slot rows, while adding
the first scheduler-visible merchant controller demo.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260325_playerbot_controller_registry.sql`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/headless_pc_controller_content.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `npc/custom/playerbot/playerbot_selftest.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added persistent controller registry tables:
  - `bot_controller_policy`
  - `bot_controller_slot`
- Seeded the active controller set through SQL:
  - `social.prontera`
  - `social.alberta`
  - `merchant.alberta`
- Moved scheduler membership, controller policy, and pooled slot definitions for
  those controllers out of `headless_pc_config.txt` and into SQL-backed rows.
- Split reusable talk/emote/anchor content into
  `headless_pc_controller_content.txt`, still keyed from script but referenced
  by SQL slot rows.
- Added SQL-backed script helpers for:
  - controller policy load
  - controller slot load
  - scheduler controller list load
  - merchant/runtime state updates by `char_id`
- Extended pooled runtime metadata to retain `bot_key` so controller-owned
  actors can update persistent merchant/runtime rows after assignment.
- Added the first SQL-registered merchant controller:
  - `HeadlessAlbertaMerchantController`
- Updated the merchant lab and merchant selftest to drive that controller
  instead of toggling merchant state only.
- Gated the merchant selftest behind explicit `.enabled` / `.autorun` flags so
  the test account no longer gets hijacked on normal login.
- Reworked the SQL-backed scheduler/controller tick path into guarded,
  single-shot timer scheduling so scheduler start/top-up cannot spawn duplicate
  long-lived `OnTick` runners.
- Hardened ambient fakeplayer refresh in the shared living-world helper:
  - existing ambient actors now relocate through passable-cell normalization and
    direct warp instead of stacking forced `unitwalk` requests during refresh

### Validation

- regenerated `npc/scripts_custom.conf`
- applied `upgrade_20260325_playerbot_controller_registry.sql` to the local
  `rathena` database
- verified seeded controller rows:
  - `merchant.alberta`
  - `social.alberta`
  - `social.prontera`
- verified seeded slot counts:
  - `merchant.alberta = 1`
  - `social.alberta = 5`
  - `social.prontera = 5`
- direct `./map-server` startup now loads the new playerbot controller files,
  reaches online state, restores persisted headless actors, and remains up
- canonical restart with `bash /root/setup_dev.sh restart` now keeps all three
  services online:
  - `6900` login-server
  - `6121` char-server
  - `5121` map-server
- the fresh-restart crash was traced through the ambient fakeplayer refresh
  path:
  - first to repeated forced `unitwalk` reuse warnings
  - then, after isolating that path, to `delete_timer` mismatch around ambient
    movement interruption
- ambient refresh is now stable under restart with the current helper hardening
- full OpenKore merchant-controller smoke is still pending in this slice

### Deferrals

This slice does not yet add:

- live vending sessions or NPC shop attachment for merchant bots
- merchant stock depletion or restock policy
- full OpenKore end-to-end verification of the merchant controller path

## Slice 48: Merchant Control-Plane Hardening

### Goal

Harden the merchant runtime lane so it no longer depends on untracked script
helpers or restart-only state refresh, and make SQL-backed controller/pool
changes reloadable without rebuilding the whole playerbot layer.

### Files Touched

- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added source-backed script buildins required by the merchant bootstrap lane:
  - `cartgetitem`
  - `clearcart`
- Added SQL-backed control-plane reload helpers in the shared living-world
  helper layer:
  - `F_PB_DB_ReloadControllers`
  - `F_PB_DB_ReconcileMerchantRuntime`
  - `F_PB_DB_ReloadControlPlane`
- Added `OnReload` support to the active DB-backed controllers so policy, slot,
  and pool changes can be re-primed cleanly without a full restart.
- Added scheduler reload support so the world scheduler can rebuild its
  controller list from SQL after a control-plane refresh.
- Updated the visible scheduler and merchant lab NPCs with a control-plane reload
  operator path.
- Added merchant runtime normalization on startup:
  - merchants that are disabled or outside their open window are now parked back
    down instead of lingering active through generic `headless_pc` restore

### Validation

- rebuilt `map-server` successfully after reintroducing the merchant cart
  buildins
- restarted the stack cleanly with `bash /root/setup_dev.sh restart`
- verified there are no fresh startup errors for:
  - unknown script commands
  - missing `cartgetitem` / `clearcart`
  - `buildin_addtimer: fatal error ! player not attached!`
- OpenKore still logs in cleanly and reaches Alberta on the updated runtime
- confirmed startup merchant normalization runs:
  - `playerbot_merchant_reconcile: touched=12`
- confirmed the previously stale merchant bot runtime row now settles back to:
  - `current_state = offline`
  - `park_state = parked`
  when the merchant is closed

### Deferrals

This slice does not yet add:

- real vending sessions or NPC shop attachment
- merchant stock depletion or restock policy
- a full scripted selftest that explicitly drives the visible reload menu path

## Slice 49: SQL-Driven Scheduler Control Surface

### Goal

Move more scheduler/operator behavior onto the SQL-backed controller registry so
the control plane is not hardcoded to a fixed controller list in script.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added SQL-backed controller registry loaders and summaries:
  - `F_PB_DB_LoadControllerRegistry`
  - `F_PB_DB_ControllerMenu$`
  - `F_PB_DB_SetControllerEnabled`
  - `F_PB_DB_BuildControllerSummary$`
- Updated the visible scheduler NPC to:
  - build its controller drill-down menu from SQL
  - toggle `controller_enabled` through the registry
  - reload the playerbot control plane after controller changes
- Added a hidden scheduler selftest that:
  - loads the controller registry
  - disables `merchant.alberta`
  - reloads the control plane
  - verifies the disabled state
  - re-enables `merchant.alberta`
  - reloads again
  - verifies the enabled state was restored
  - remains disabled by default after validation so startup stays clean

### Validation

- restarted the stack cleanly
- verified the map-server still reaches online state with the dynamic scheduler
  surface
- verified control-plane reload remains available and the scheduler still reads
  controller membership from SQL

### Deferrals

This slice does not yet add:

- a fully generic SQL-backed operator UI beyond the scheduler/merchant labs
- scheduler-side create/delete authoring for controller rows
- migration of all controller content blobs out of script-backed content files

## Slice 50: SQL-Backed Controller Content Sets

### Goal

Move the remaining active controller content blobs out of
`headless_pc_controller_content.txt` and into checked-in SQL data so active
playerbot controllers no longer depend on a script-owned talk/anchor/emote
registry.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_controller_content.sql`
- `npc/custom/living_world/_common.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added SQL-backed controller content tables:
  - `bot_controller_anchor_point`
  - `bot_controller_talk_line`
  - `bot_controller_emote_value`
- Seeded the current Prontera social, Alberta social, and Alberta merchant
  content sets into SQL.
- Added SQL-backed content loaders:
  - `F_PB_DB_ApplyAnchorSet`
  - `F_PB_DB_ApplyTalkSet`
  - `F_PB_DB_ApplyEmoteSet`
- Updated `F_PB_DB_LoadControllerDef` to source anchor/talk/emote sets from SQL
  instead of the script-backed content registry.
- Removed the now-obsolete `headless_pc_controller_content.txt` load from
  `npc/scripts_custom.conf`.

### Validation

- applied `upgrade_20260326_playerbot_controller_content.sql` to the local
  `rathena` database
- restarted the stack cleanly
- verified startup stayed clean after removing the old content script include
- verified content rows now exist in SQL:
  - `bot_controller_anchor_point = 20`
  - `bot_controller_talk_line = 22`
  - `bot_controller_emote_value = 22`
- OpenKore still logs in and sees the Alberta playerbot harness after the
  migration

### Deferrals

This slice does not yet add:

- SQL-backed route sets
- runtime/operator authoring for content sets
- migration of every historical/demo controller content blob beyond the active
  Prontera/Alberta/merchant set

## Slice 51: SQL-Backed Route Sets And Patrol Proof

### Goal

Finish the current control-plane migration lane by moving route sets into SQL
and proving them through a DB-backed patrol controller instead of only
script-owned route definitions.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_route_sets.sql`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_patrol_demo.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added SQL-backed route table:
  - `bot_controller_route_point`
- Added SQL-backed route loader:
  - `F_PB_DB_ApplyRouteSet`
- Extended `F_PB_DB_LoadControllerDef` to load `route_set_key` and materialize
  route points from SQL
- Added a new DB-backed patrol controller policy and slot:
  - `patrol.prontera`
  - controller NPC: `HeadlessPronteraPatrolController`
  - route set: `patrol.prontera.loop`
- Added visible dev harness:
  - `Headless Prontera Patrol`
- Updated scheduler stop behavior to stop all enabled controllers through the SQL
  registry instead of a hardcoded script list

### Validation

- applied `upgrade_20260326_playerbot_route_sets.sql`
- restarted the stack cleanly
- verified the new route set exists in SQL:
  - `patrol.prontera.loop = 4` points
- verified the new controller policy/slot rows exist:
  - `patrol.prontera`
  - `HeadlessPronteraPatrolController`
- verified no new parse/runtime errors were introduced by the route-set load
  path
- OpenKore login baseline still works after the migration

### Deferrals

This slice does not yet add:

- SQL-backed route authoring UI
- migration of older demo-only script patrol routes outside the new control
  plane proof
- scheduler activation of the patrol controller by default

## Slice 52: Merchant Runtime Shop Proxy

### Goal

Move the merchant lane past metadata/bootstrap only by giving the Alberta
merchant bot a real shop-facing runtime surface:

- SQL-backed merchant stock
- a live NPC shop proxy
- controller-driven open/close behavior

This stays within the approved project pattern of visible merchant actors plus
NPC shop interfaces, not fake vending-player emulation.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_merchant_runtime.sql`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added SQL-backed merchant stock table:
  - `bot_merchant_stock_item`
- Added shared merchant stock/shop helpers:
  - `F_PB_DB_LoadMerchantStockProfile`
  - `F_PB_DB_ApplyMerchantShop`
  - `F_PB_DB_ShowMerchantProxy`
  - `F_PB_DB_HideMerchantProxy`
- Extended the Alberta merchant controller so open merchants now:
  - bootstrap merchant/cart state
  - populate a real shop NPC from SQL stock rows
  - expose a visible clickable proxy at the live stall position
- Added the first live player-facing merchant proxy/shop pair:
  - `Harbor Curios Counter#pb`
  - `pb_merchant_alberta_shop`
- Extended the merchant selftest so it now validates shop materialization in
  addition to spawn/bootstrap/park/reload

### Validation

- applied `upgrade_20260326_playerbot_merchant_runtime.sql`
- restarted the stack cleanly
- verified the merchant stock rows exist in SQL:
  - `bot_merchant_stock_item` contains `alberta_curios`
- OpenKore still logs in and reaches Alberta after the slice
- merchant selftest now reports a full runtime pass:
  - `base_ok=1`
  - `spawn_ok=1`
  - `bootstrap_ok=1`
  - `shop_ok=1`
  - `park_ok=1`
  - `reload_ok=1`
  - `result=1`

### Deferrals

This slice does not yet add:

- true vending-player runtime
- merchant stock authoring UI
- price-profile logic beyond per-item SQL sell prices
- multi-stall merchant controller support beyond the first Alberta proof

## Slice 53: Scheduler Sticky Runtime And Cooldown Policy

### Goal

Harden the world scheduler so controllers do not thrash when demand changes:

- keep newly-started controllers alive for a minimum runtime
- prevent immediate restart after a stop
- keep this policy SQL-backed and visible in scheduler status

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_scheduler_automation.sql`
- `npc/custom/living_world/_common.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added SQL-backed scheduler automation fields to `bot_controller_policy`:
  - `min_active_ms`
  - `restart_cooldown_ms`
- Extended scheduler controller loading so those fields are materialized into
  the active scheduler state
- Added sticky controller retention for active controllers that are still inside
  their minimum runtime window
- Added restart cooldown blocking for inactive controllers that were stopped too
  recently
- Extended scheduler status to show:
  - sticky/cooldown policy
  - active uptime for running controllers
  - time-since-stop for idle controllers

### Validation

- applied `upgrade_20260326_playerbot_scheduler_automation.sql`
- verified the SQL policy values:
  - `merchant.alberta -> 90000 / 30000`
  - `patrol.prontera -> 30000 / 15000`
  - `social.alberta -> 60000 / 20000`
  - `social.prontera -> 45000 / 15000`
- restarted the stack cleanly
- verified no new parser/runtime errors were introduced by the scheduler
  changes
- OpenKore baseline still logs in and reaches Alberta after the slice

### Deferrals

This slice does not yet add:

- scheduler history persistence across restart
- weighted rotation between equally eligible controllers
- richer demand models beyond current map-user gating and routine windows

## Slice 54: Scheduler Fairness Rotation

### Goal

Stop the scheduler from favoring the same equal-priority controller forever by
adding a simple fairness policy for otherwise equally eligible choices.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added least-recently-selected tie-breaking inside the scheduler for
  equal-priority controller choices
- the scheduler now tracks per-controller last-picked time in memory
- scheduler status now reports:
  - last-picked age
- sticky minimum-runtime retention and restart cooldown still apply first; the
  new fairness lane only affects the remaining equal-priority candidates

### Validation

- restarted the stack cleanly
- verified no new scheduler parser/runtime errors were introduced
- OpenKore baseline still logs in and reaches Alberta after the fairness change

### Deferrals

This slice does not yet add:

- weighted randomized selection
- fairness history persistence across restart
- fairness at the individual bot-slot level inside a controller

## Slice 55: Scheduler Runtime Persistence And Demand Weighting

### Goal

Finish the remaining scheduler-foundation gap by:

- persisting scheduler selection history across restart
- replacing strict equal-priority LRU with weighted rotation
- adding demand-based effective priority on top of gate users

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_scheduler_runtime.sql`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_scheduler_demo.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added SQL-backed scheduler policy fields to `bot_controller_policy`:
  - `fair_weight`
  - `demand_users_step`
  - `demand_priority_step`
  - `demand_priority_cap`
- Added persistent scheduler history table:
  - `bot_controller_runtime`
- Scheduler controller loading now materializes:
  - controller key
  - fairness weight
  - demand-scaling policy
- Scheduler prime now loads persisted runtime history from SQL
- Scheduler selection now computes an effective priority as:
  - `base priority + demand bonus`
- Demand bonus now scales from surplus users beyond the gate threshold, bounded
  by the controller's configured cap
- Equal-effective-priority selection now uses weighted rotation instead of
  deterministic registry order
- Scheduler status now surfaces:
  - base priority
  - demand bonus
  - effective priority
  - fairness weight
  - demand step / priority bonus / cap
  - persisted last-picked / last-start / last-stop timing when present

### Validation

- applied `upgrade_20260326_playerbot_scheduler_runtime.sql`
- verified the new SQL scheduler policy values:
  - `merchant.alberta -> fair 2, demand 4 / 1 / 3`
  - `patrol.prontera -> fair 1, demand 3 / 1 / 4`
  - `social.alberta -> fair 3, demand 2 / 2 / 8`
  - `social.prontera -> fair 3, demand 2 / 2 / 8`
- restarted the stack cleanly after compacting persisted runtime keys
- confirmed the earlier variable-length startup errors are gone
- verified no fresh parser/runtime errors were introduced by the scheduler
  changes
- OpenKore baseline still logs in successfully after the slice
- confirmed `bot_controller_runtime` exists and loads cleanly at startup

### Deferrals

This slice does not yet add:

- richer demand signals beyond map users and routine windows
- persisted fairness at per-bot or per-slot granularity
- operator-facing scheduler history inspection beyond current status output and
  SQL

## Slice 56: SQL-Backed Demand Profiles And Pulse Profiles

### Goal

Reduce remaining script hardcoding in the controller layer and make scheduler
selection react to richer demand than a single gated map count.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_demand_profiles.sql`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added SQL-backed multi-map demand sources through:
  - `bot_controller_demand_map`
- Added SQL-backed pulse profiles through:
  - `bot_pulse_profile`
- Moved the live pulse profile definitions out of `headless_pc_config.txt` and
  into checked-in SQL seed data
- Controller pulse application now reads from SQL instead of the old script-only
  profile registry
- Controller policy application now stores the controller policy key on the live
  controller runtime state
- `F_LW_HPC_ControllerShouldRun(...)` now evaluates weighted demand users from
  SQL-backed demand-map sets instead of only checking the primary gate map
- Scheduler status now surfaces:
  - weighted demand users
  - demand-map composition
- Scheduler selection now computes demand pressure from SQL-backed demand maps,
  not only the controller's primary map

### Validation

- applied `upgrade_20260326_playerbot_demand_profiles.sql`
- verified demand-map rows exist for:
  - `social.prontera`
  - `patrol.prontera`
  - `social.alberta`
  - `merchant.alberta`
- verified pulse-profile rows exist for the active social/merchant controller
  profiles
- restarted the full stack cleanly
- confirmed no new parser/runtime errors were introduced by the demand/pulse
  migration
- OpenKore baseline still logs in and reaches Prontera after the slice

### Deferrals

This slice does not yet add:

- guild/economy-aware demand signals
- operator-authored demand-map editing surfaces
- richer market demand feedback from real shop activity

## Slice 57: Playerbot Guild State Foundation

### Goal

Add the persistent guild-facing metadata layer for recurring playerbots so
guild-capable identities can be provisioned, inspected, and pooled without
pretending guild mechanics are already complete.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_guild_state.sql`
- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/playerbot_provisioner.txt`
- `npc/custom/playerbot/playerbot_party_lab.txt`
- `npc/custom/playerbot/playerbot_guild_lab.txt`
- `npc/scripts_custom.conf`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added persistent guild metadata through:
  - `bot_guild_state`
- Extended provisioning so templates can create guild-capable recurring bots
  with:
  - `guild_policy`
  - `guild_name`
  - `guild_position`
  - `invite_policy`
  - `guild_member_state`
- Extended cleanup of failed bot provisioning so `bot_guild_state` is removed
  along with the other bot tables
- Extended `F_PB_DB_LoadBotSummary(...)` to surface guild metadata beside the
  existing party and merchant summaries
- Added a new provisioning template:
  - `guild.prontera.member`
- Added a visible dev harness:
  - `Playerbot Guild Lab`
- Updated the existing provisioner and party lab inspect paths to show guild
  metadata

### Validation

- applied `upgrade_20260326_playerbot_guild_state.sql`
- rebuilt `map-server`
- restarted the full stack cleanly
- verified `bot_guild_state` exists and backfilled persistent rows for the
  current recurring bot set
- verified the new guild-capable provision/inspect surfaces load cleanly in:
  - `Playerbot Provisioner`
  - `Playerbot Party Lab`
  - `Playerbot Guild Lab`
- OpenKore baseline still logs in and reaches Prontera after the slice

### Deferrals

This slice does not yet add:

- actual guild invite/join semantics
- guild membership synchronization with the base `guild` and `guild_member`
  tables
- guild-aware scheduler demand or event participation

## Slice 58: Guild And Economy-Aware Demand Signals

### Goal

Extend the scheduler demand model beyond raw map users so later guild and
economy participation can influence controller selection without hardcoded
script logic.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_demand_signals.sql`
- `npc/custom/living_world/_common.txt`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added SQL-backed participation signals through:
  - `bot_controller_demand_signal`
- Added signal-aware demand evaluation in:
  - `F_PB_DB_ControllerDemandUsers(...)`
  - `F_PB_DB_ControllerDemandSummary$(...)`
- Added the first supported signal families:
  - `merchant_open_map`
  - `merchant_live_map`
  - `guild_enabled_name`
  - `guild_candidate_map`
- Scheduler/controller demand now combines:
  - weighted map users from `bot_controller_demand_map`
  - weighted participation signals from `bot_controller_demand_signal`
- Seeded the current controller set with first-pass signal policies:
  - Alberta merchant demand favors open/live merchant presence
  - Prontera social/patrol can later favor guild-capable presence on the map

### Validation

- applied `upgrade_20260326_playerbot_demand_signals.sql`
- verified signal rows exist for:
  - `merchant.alberta`
  - `social.alberta`
  - `social.prontera`
  - `patrol.prontera`
- restarted the full stack cleanly
- confirmed no new parser/runtime errors were introduced by the signal-aware
  scheduler changes
- verified the current live dev signal counts:
  - Alberta scheduled/open merchants = `1`
  - Alberta live merchanting actors = `0`
  - Prontera enabled guild-capable candidates = `0`

### Deferrals

This slice does not yet add:

- real guild invite/join participation as a live scheduler signal
- trade-volume, zeny, or shop-sales demand feedback
- per-bot or per-guild demand overrides beyond the current controller-level
  signal rows

## Slice 59: Playerbot Guild Invite Foundation

### Goal

Let active headless playerbots participate in the normal guild invite path with a
very narrow accept/decline policy, without pretending broader guild behavior is
done.

### Files Touched

- `src/map/guild.cpp`
- `src/map/script.cpp`
- `npc/custom/playerbot/playerbot_guild_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added a narrow guild invite policy helper in `guild.cpp` for active
  headless/playerbot targets.
- Guild invites now special-case `state.headless_bot` before the normal
  disconnected-client rejection path, mirroring the earlier party-v1 pattern.
- The guild invite policy currently reads from:
  - `bot_guild_state.enabled`
  - `bot_guild_state.invite_policy`
- Added script buildins:
  - `playerbot_guildinvite(char_id)`
  - `playerbot_guildid(char_id)`
- Extended `Playerbot Guild Lab` with:
  - spawn by key
  - runtime guild invite by key
  - current guild_id inspection

### Validation

- rebuilt `map-server`
- restarted the full stack cleanly after the rebuild
- verified the guild lab is visible in Prontera after the clean restart
- verified the new guild buildins no longer cause parser errors after the
  post-build restart
- confirmed the current dev DB has no live guild rows to run a full invite/join
  acceptance path against, so this slice is validated as runtime plumbing plus
  in-game harness availability

### Deferrals

This slice does not yet add:

- guild creation or guild seeding helpers for selftests
- full live guild invite acceptance proof in the current empty-guild dev DB
- guild follow/assist, guild chat, or guild event semantics
