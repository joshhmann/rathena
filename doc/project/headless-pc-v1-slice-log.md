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
