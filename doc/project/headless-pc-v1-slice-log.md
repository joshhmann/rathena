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

## Slice 60: Playerbot Guild Creation Helper And Economy Signals

### Goal

Close the empty-guild validation gap with a real dev guild-creation helper, and
extend controller demand beyond merchant presence into merchant stock depth.

### Files Touched

- `src/map/script.cpp`
- `npc/custom/playerbot/headless_pc_config.txt`
- `npc/custom/playerbot/playerbot_provisioner.txt`
- `npc/custom/playerbot/playerbot_guild_lab.txt`
- `npc/custom/living_world/_common.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_economy_signals.sql`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added `playerbot_guildcreate(name$)` in `script.cpp`.
- The helper mirrors the `@guild` dev path:
  - attached-player only
  - temporarily bypasses Emperium requirement
  - calls the normal `guild_create(...)` runtime
- Added `guild.prontera.open` as a first open-invite guild-capable template.
- Extended the provisioner with a matching quick/manual guild-open option.
- Extended `Playerbot Guild Lab` with a full guild selftest lane:
  - create guild if needed
  - provision/open a guild-capable bot
  - spawn it
  - invite it through the guild runtime
  - verify guild ids
- Added a richer demand signal family:
  - `merchant_stock_map`
- Controller demand can now react to merchant stock depth, not only:
  - merchant-open counts
  - live merchanting counts

### Validation

- rebuilt `map-server`
- applied `upgrade_20260326_playerbot_economy_signals.sql`
- restarted the full stack cleanly after the changes
- verified SQL demand rows for:
  - `social.alberta`
  - `merchant.alberta`
  now include `merchant_stock_map`
- verified from a live OpenKore login that `playerbot_guildcreate(...)` works:
  - the attached `codex` test character received `Guild create successful.`
  - the client also reported `You are a guildmaster.`
- verified in SQL that the new guild row exists:
  - `guild_id 1`
  - `name PBG150001`
  - `master codex`
- kept the guild selftest harness in place, but did not claim a full end-to-end
  bot invite/join proof for this slice because the dormant autorun/manual path
  still needs a cleaner repeatable trigger in CLI

### Deferrals

This slice does not yet add:

- a fully repeatable CLI-proven guild bot invite/join selftest result
- guild-aware scheduler demand from real live guild roster/activity
- richer economy pressure from sales, trades, or zeny flow

## Slice 61: Merchant Activity Runtime Signals

### Goal

Move economy demand beyond configured merchant stock depth by recording real
browse/sale activity from the playerbot merchant lane, and harden the dev proof
path around manual selftests instead of noisy startup autoruns.

### Files Touched

- `src/map/guild.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `npc/custom/playerbot/playerbot_guild_lab.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_merchant_activity.sql`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added `bot_merchant_runtime` to persist live merchant activity:
  - `last_browse_at`
  - `last_sale_at`
  - `total_browse_count`
  - `total_sale_count`
  - `total_items_sold`
- Expanded controller demand signals with:
  - `merchant_browse_map`
  - `merchant_sale_map`
- Added shared SQL-backed helpers:
  - `F_PB_DB_RecordMerchantBrowse`
  - `F_PB_DB_RecordMerchantSale`
- The Alberta merchant proxy now records:
  - browse activity when a player opens the shop
  - sale activity from `OnBuyItem`
- The merchant selftest is now an explicit manual harness action from
  `Playerbot Merchant Lab` and verifies:
  - merchant bootstrap
  - proxy/shop visibility
  - browse/sale activity row creation
  - control-plane reload
- Added guild-state synchronization on active headless guild join in
  `guild.cpp`, and tightened the guild lab into a manual selftest harness.

### Validation

- applied `upgrade_20260326_playerbot_merchant_activity.sql`
- restarted the full stack cleanly
- ran `Playerbot Merchant Lab -> Run merchant selftest` from a live OpenKore
  session in Alberta
- verified the final map-server selftest line:
  - `playerbot_merchant_selftest ... base_ok=1 spawn_ok=1 bootstrap_ok=1 shop_ok=1 activity_ok=1 park_ok=1 reload_ok=1 result=1`
- verified `bot_merchant_runtime` persisted live activity for bot `12`:
  - browse count `2`
  - sale count `2`
  - items sold `6`
- verified the guild lab manual selftest now fires and logs honestly, but still
  does not pass cleanly because the current dev restart path can leave a stale
  duplicate map-server ownership lane that causes reused guild-bot spawns to be
  rejected at char-server

### Deferrals

This slice does not yet add:

- a clean repeatable end-to-end guild invite/join selftest result
- real purchase-driven stock depletion or zeny-flow accounting
- guild-aware demand from live guild roster activity

## Slice 62: Dev Restart Ownership Cleanup

### Goal

Make the local dev restart path collapse orphan rAthena server processes and
stray tmux debug sessions so playerbot lifecycle tests stop failing because
char-server sees duplicate map-server owners.

### Files Touched

- `/root/setup_dev.sh`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added `cleanup_server_processes()` to `/root/setup_dev.sh`.
- `start`/`stop`/`restart` now clean up:
  - orphan `map-server`, `char-server`, and `login-server` processes running
    from `/root/dev/rathena`
  - stray tmux sessions whose pane start command is launching those same repo
    binaries, such as one-off debug sessions
- This removes the stale multi-owner failure mode where char-server would show:
  - `Map-Server 0 connected`
  - `Map-Server 1 connected`
  for the same local repo stack

### Validation

- reproduced the bad state with an extra tmux debug session:
  - `pb-map-debug`
- confirmed char-server showed duplicate owners before cleanup:
  - `Map-Server 0 connected`
  - `Map-Server 1 connected`
  - `claims to have ... online`
- ran `bash /root/setup_dev.sh restart`
- verified restart output now explicitly kills:
  - orphan `map-server` processes
  - orphan tmux session `pb-map-debug`
- verified post-fix char-server startup shows only:
  - `Map-Server 0 connected`
- verified the normal dev tmux set remains:
  - `rathena-dev-login-server`
  - `rathena-dev-char-server`
  - `rathena-dev-map-server`

### Deferrals

This slice does not yet add:

- an always-on guild selftest proof path through OpenKore
- automatic detection/reporting of bad third-party debug sessions before they
  are cleaned

## Slice 63: Repo-Tracked Restart Cleanup And Guild Smoke Proof

### Goal

Move the local restart-ownership cleanup into a tracked repo tool and use that
clean baseline to finish a repeatable end-to-end guild invite proof.

### Files Touched

- `AGENTS.md`
- `npc/custom/playerbot/playerbot_guild_lab.txt`
- `tools/dev/playerbot-dev.sh`
- `tools/ci/playerbot-guild-smoke.sh`
- `doc/project/openkore-test-harness.md`
- `doc/project/openkore-smoke-scenarios.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added a tracked repo-local dev tool:
  - `tools/dev/playerbot-dev.sh`
- It now owns the canonical local playerbot restart path for this repo:
  - stop/cleanup/start/restart/status
- The cleanup logic now kills:
  - orphan repo-owned `login-server`, `char-server`, and `map-server` processes
  - stray tmux lanes launching those same repo binaries
- Updated `PlayerbotGuildSelftest` so it can be armed for the next test-account
  login through:
  - `$PBGST_AUTORUN_AID`
- Added a tracked guild smoke helper:
  - `tools/ci/playerbot-guild-smoke.sh`
  - `arm` writes the mapreg trigger and restarts from the repo-local tool
  - `check` reads the recent guild selftest result from the map-server tmux pane
- Fixed the guild selftest script so it re-attaches the inviter RID before the
  post-spawn guild invite step.

### Validation

- ran `bash tools/dev/playerbot-dev.sh restart`
- verified char-server startup returned to a single clean owner lane:
  - `Map-Server 0 connected`
- verified only the normal repo tmux server sessions remained
- ran `bash tools/ci/playerbot-guild-smoke.sh arm`
- logged in with the `codex` OpenKore profile
- verified the map-server guild selftest result:
  - `playerbot_guild_selftest: spawn=1 invite=1 inviter_gid=1 bot_gid=1 status=2 result=1`
- verified the live OpenKore client saw the normal guild acceptance feedback:
  - `Guild join request: Target has accepted.`

### Deferrals

This slice does not yet add:

- guild chat/storage/event behavior
- guild-aware scheduler demand from live guild roster activity
- a fully automated no-manual-login guild smoke launcher

## Slice 64: Real Guild Roster Demand Signals

### Goal

Promote guild-aware scheduler demand from metadata-only candidate checks into
real guild participation signals backed by actual `guild` / `guild_member`
rows and live online state.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_guild_signals.sql`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added two new SQL-backed scheduler signal families:
  - `guild_roster_name`
  - `guild_live_name`
- `guild_roster_name` counts real recurring bot identities linked into a live
  `guild` roster through:
  - `guild`
  - `guild_member`
  - `bot_identity_link`
  - `bot_profile`
- `guild_live_name` counts those same linked guild members when their
  underlying `char.online` state is currently live.
- Updated Prontera policy seeds so scheduler demand can react to the actual dev
  guild:
  - `social.prontera`
  - `patrol.prontera`
  - guild key `PBG150001`

### Validation

- applied `upgrade_20260326_playerbot_guild_signals.sql`
- restarted from the repo-local control path:
  - `bash tools/dev/playerbot-dev.sh restart`
- verified SQL demand rows now include:
  - `social.prontera -> guild_roster_name / PBG150001`
  - `social.prontera -> guild_live_name / PBG150001`
  - `patrol.prontera -> guild_roster_name / PBG150001`
- re-ran the repeatable guild smoke path:
  - `bash tools/ci/playerbot-guild-smoke.sh arm`
  - OpenKore `codex` login
- verified the guild runtime still passes end-to-end:
  - `playerbot_guild_selftest: spawn=1 invite=1 inviter_gid=1 bot_gid=1 status=2 result=1`
- verified the real guild roster signal is non-zero in SQL after the proof path:
  - roster count for `PBG150001` > `0`

### Deferrals

This slice does not yet add:

- guild chat/storage/event behavior
- guild-aware scheduler demand from chat traffic, castle ownership, or guild
  storage usage
- a sticky guild smoke path that leaves the invited bot online long enough to
  sample `guild_live_name` over time without a fast selftest cleanup

## Slice 65: Guild Storage Demand Signals

### Goal

Extend the guild-aware scheduler foundation so Prontera controllers can react
to real guild storage depth and recent guild storage activity, not only roster
membership.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_guild_storage_signals.sql`
- `tools/ci/playerbot-guild-storage-smoke.sh`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added two new SQL-backed scheduler signal families:
  - `guild_storage_name`
  - `guild_storage_log_name`
- `guild_storage_name` counts current rows in `guild_storage` for a live guild.
- `guild_storage_log_name` counts recent `guild_storage_log` rows in the last
  15 minutes for that guild.
- Updated Prontera scheduler policy seeds so:
  - `social.prontera`
  - `patrol.prontera`
  can react to storage-backed guild activity for `PBG150001`.
- Added a non-destructive dev helper:
  - `tools/ci/playerbot-guild-storage-smoke.sh`
  - uses a fixed sentinel `unique_id` probe row for seed/clear validation

### Validation

- applied `upgrade_20260326_playerbot_guild_storage_signals.sql`
- restarted from the repo-local control path:
  - `bash tools/dev/playerbot-dev.sh restart`
- ran the storage smoke helper:
  - `bash tools/ci/playerbot-guild-storage-smoke.sh clear`
  - `bash tools/ci/playerbot-guild-storage-smoke.sh seed`
  - `bash tools/ci/playerbot-guild-storage-smoke.sh check`
- verified seeded counts for `PBG150001`:
  - `storage_rows = 1`
  - `recent_log_rows = 1`
- verified the new SQL demand rows exist:
  - `social.prontera -> guild_storage_name / PBG150001`
  - `social.prontera -> guild_storage_log_name / PBG150001`
  - `patrol.prontera -> guild_storage_name / PBG150001`
- cleared the sentinel probe rows after validation:
  - `storage_rows = 0`
  - `recent_log_rows = 0`

### Deferrals

This slice does not yet add:

- true guild-storage interaction by playerbots through the normal in-game
  storage UI/runtime
- guild chat, castle, tax, or event-backed demand signals
- a scheduler surface that explains storage-signal contribution in per-signal
  detail

## Slice 66: Guild Castle Demand Signals

### Goal

Extend guild-aware scheduler demand into castle ownership so Prontera
controllers can later react to WoE-style guild presence using the same
data-backed signal lane.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_guild_castle_signals.sql`
- `tools/ci/playerbot-guild-castle-smoke.sh`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime / Script Path Changes

- Added one new SQL-backed scheduler signal family:
  - `guild_castle_name`
- `guild_castle_name` counts current `guild_castle` ownership rows for a guild.
- Updated Prontera controller policy seeds so:
  - `social.prontera`
  - `patrol.prontera`
  can react to castle ownership for `PBG150001`.
- Added a safe dev smoke helper:
  - `tools/ci/playerbot-guild-castle-smoke.sh`
  - inserts a sentinel castle row when the dev DB has no castle rows
  - restores or deletes that sentinel row on cleanup

### Validation

- applied `upgrade_20260326_playerbot_guild_castle_signals.sql`
- restarted from the repo-local control path:
  - `bash tools/dev/playerbot-dev.sh restart`
- verified the new SQL demand rows exist:
  - `social.prontera -> guild_castle_name / PBG150001`
  - `patrol.prontera -> guild_castle_name / PBG150001`
- ran the castle smoke helper:
  - `bash tools/ci/playerbot-guild-castle-smoke.sh clear`
  - `bash tools/ci/playerbot-guild-castle-smoke.sh seed`
  - `bash tools/ci/playerbot-guild-castle-smoke.sh check`
- verified seeded castle ownership for `PBG150001`:
  - `owned_castles = 1`
- verified the helper created a sentinel castle row in the otherwise-empty dev
  DB:
  - `castle_id = 999`
  - `guild_id = 1`
- cleared the sentinel row again and verified `guild_castle` returned empty

### Deferrals

This slice does not yet add:

- real WoE/event controller behavior
- tax, defense, economy, or castle-activity demand signals
- scheduler drill-down that breaks out each guild signal as a separate
  contribution line
## Slice: Scheduler Demand Breakdown Visibility

Date: 2026-03-26

Summary:
- expanded scheduler and controller status so demand is no longer shown only as a compressed inline summary
- added a multiline demand breakdown that shows each weighted map-user and signal contribution separately
- kept the existing total weighted-demand calculation unchanged; this slice is observability-only

Changed:
- `npc/custom/living_world/_common.txt`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- checked clean `map-server` / `char-server` startup after the script change
- `bash -n tools/ci/openkore-smoke.sh`
- `bash tools/ci/openkore-smoke.sh --no-launch scheduler-status`

Notes:
- controller drill-down now includes the same demand breakdown used by scheduler status
- this makes guild/economy demand signals easier to audit before adding more behavior layers

## Slice: Guild Leader Demand Signals

Date: 2026-03-26

Summary:
- added guild leader presence signals to the scheduler demand layer
- Prontera social and patrol controllers can now react to whether a guild leader exists and whether that leader is currently online
- this stays in the foundation lane: demand/state only, not guild behavior AI yet

Changed:
- `npc/custom/living_world/_common.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_guild_leader_signals.sql`
- `doc/project/bot-state-schema.md`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_guild_leader_signals.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- verified SQL demand rows for:
  - `social.prontera -> guild_leader_name / guild_leader_live_name`
  - `patrol.prontera -> guild_leader_live_name`
- verified clean startup after the script + SQL change

Notes:
- this complements the earlier roster/live/storage/castle guild signals by adding leadership-aware demand pressure

## Slice: Guild Notice Demand Signals

Date: 2026-03-26

Summary:
- added guild notice presence as another scheduler demand signal
- Prontera social and patrol controllers can now react to whether a guild currently has a posted notice
- added a safe repo-local notice smoke helper so the signal can be seeded and cleared without hand-editing SQL

Changed:
- `npc/custom/living_world/_common.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_guild_notice_signals.sql`
- `tools/ci/playerbot-guild-notice-smoke.sh`
- `doc/project/bot-state-schema.md`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_guild_notice_signals.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- `bash -n tools/ci/playerbot-guild-notice-smoke.sh`
- `bash tools/ci/playerbot-guild-notice-smoke.sh clear`
- `bash tools/ci/playerbot-guild-notice-smoke.sh seed`
- `bash tools/ci/playerbot-guild-notice-smoke.sh check`
- `bash tools/ci/playerbot-guild-notice-smoke.sh clear`

Notes:
- this is still demand/state only; it does not yet add guild notice authoring or guild chat behavior

## Slice: Guild Activity Runtime Signals

Date: 2026-03-26

Summary:
- added a small runtime guild-activity ledger so scheduler demand can react to recent guild joins and recent guild notice changes
- updated the guild selftest to exercise both join and notice activity through the normal runtime path
- extended the guild smoke helper to show the activity ledger directly

Changed:
- `src/map/guild.cpp`
- `src/map/script.cpp`
- `npc/custom/playerbot/playerbot_guild_lab.txt`
- `tools/ci/playerbot-guild-smoke.sh`
- `npc/custom/living_world/_common.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_guild_activity_signals.sql`
- `doc/project/bot-state-schema.md`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_guild_activity_signals.sql`
- rebuilt `map-server`
- `bash tools/dev/playerbot-dev.sh restart`
- `bash tools/ci/playerbot-guild-smoke.sh arm`
- OpenKore login with the `codex` test profile
- `bash tools/ci/playerbot-guild-smoke.sh check`
- verified `bot_guild_runtime` recorded:
  - `last_member_join_at`
  - `last_notice_at`

Notes:
- this is the first guild activity slice driven by runtime hooks rather than static guild table state only

## Slice: Guild Runtime Operator Surface

Date: 2026-03-26

Summary:
- added a shared guild-runtime summary helper for script/operator surfaces
- updated the guild lab so guild-capable bot inspection now shows recent join and notice activity without dropping to SQL

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_guild_lab.txt`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- checked clean `map-server` startup after the script-only change
- confirmed the existing `bot_guild_runtime` row for `PBG150001` remains readable

Notes:
- this is an operator/inspection slice only; it does not change guild runtime semantics

## Slice: Prontera Guild Watch Controller

Date: 2026-03-26

Summary:
- added the first guild-activity behavior controller on top of the existing guild demand/runtime foundation
- `guild.watch.prontera` is SQL-backed and scheduler-eligible
- this controller uses the existing recurring Prontera social pool, but is driven by guild activity instead of general crowd presence

Changed:
- `npc/custom/playerbot/headless_pc_prontera_guild_demo.txt`
- `npc/scripts_custom.conf`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_behavior_controllers.sql`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_behavior_controllers.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- verified SQL policy / slot rows exist for `guild.watch.prontera`
- OpenKore on Prontera confirmed visible lab/controller NPC:
  - `Headless Prontera Guild`

Notes:
- this is a controller-behavior foundation slice, not a full guild AI system

## Slice: Alberta Trade Flow Controller

Date: 2026-03-26

Summary:
- added the first economy-flow behavior controller on top of the merchant demand/runtime foundation
- `market.flow.alberta` is SQL-backed and scheduler-eligible
- this controller uses the existing Alberta social pool and a dedicated SQL route set to react to trade pressure around the harbor market

Changed:
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `npc/scripts_custom.conf`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_behavior_controllers.sql`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_behavior_controllers.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- verified SQL policy / slot rows exist for `market.flow.alberta`
- verified SQL route rows exist for `market.flow.alberta.loop`
- confirmed clean map-server startup with no parser/runtime regressions after loading both new controller files

Notes:
- this is a behavior/controller slice, not a full merchant economy simulation

## Slice: Prontera Guild Quarter Controller

Date: 2026-03-26

Summary:
- added a second guild-driven controller lane so guild activity can shape a more stable quarter around Prontera instead of only one watch point
- `guild.square.prontera` is SQL-backed and scheduler-eligible
- this controller still uses the existing Prontera social pool while the stricter guild-only bot roster remains a later content step

Changed:
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/scripts_custom.conf`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_behavior_expansion.sql`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_behavior_expansion.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- verified SQL policy / slot rows exist for `guild.square.prontera`
- OpenKore on Prontera confirmed visible controller NPC:
  - `Headless Prontera Guild Quarter`

Notes:
- this is still a behavior/controller foundation slice, not a full guild-routine or guild-chat system

## Slice: Alberta Market Spill Controller

Date: 2026-03-26

Summary:
- added a second economy-driven controller lane so market pressure can spill beyond the static merchant stall and first trade-flow route
- `market.spill.alberta` is SQL-backed and scheduler-eligible
- this controller stays on the broader Alberta social pool for now because the current milestone is control-plane and demand-shape depth, not final merchant-only roster curation

Changed:
- `npc/custom/playerbot/headless_pc_alberta_market_spill_demo.txt`
- `npc/scripts_custom.conf`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_behavior_expansion.sql`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_behavior_expansion.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- verified SQL policy / slot rows exist for `market.spill.alberta`
- verified SQL route rows exist for `market.spill.alberta.loop`
- confirmed clean map-server startup after loading both new controller files

Notes:
- this deepens the economy behavior lane, but it is still not a full autonomous market simulation

## Slice: Guild And Trade Roster Specialization

Date: 2026-03-26

Summary:
- retargeted the guild controllers onto the dedicated guild recurring-bot pool instead of the broad Prontera social pool
- split Alberta into:
  - a smaller true ambient social pool
  - a dedicated trade-runner pool for direct market-flow behavior
- reduced the Alberta market-spill lane to a lighter one-actor spillover presence so the scheduler no longer has to overcommit the same small bot supply

Changed:
- `npc/custom/playerbot/headless_pc_config.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_roster_specialization.sql`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_roster_specialization.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- verified bot roster SQL now shows:
  - `botpc03`, `botpc05` -> `pool.trade.alberta` / `market.alberta.runner` / `market_runner`
  - guild watch and guild quarter slots -> `pool.guild.prontera`
- verified controller slot SQL now reflects the specialized pools

Notes:
- this is a foundation/roster-curation slice, not a new behavior family
- the goal is cleaner controller ownership and less pool contention

## Slice: Demand-Scaled Controller Slots

Date: 2026-03-26

Summary:
- added slot-level demand thresholds so controllers can scale individual actors in and out based on weighted demand instead of always trying to drive the full slot list
- the controller layer can now keep:
  - base actors always or almost always present
  - extra runners/couriers only when the relevant guild/economy pressure is high enough

Changed:
- `npc/custom/living_world/_common.txt`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_slot_demand_scaling.sql`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_slot_demand_scaling.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- verified SQL `min_demand_users` values for active controller slots
- confirmed clean map-server startup after the script helper and schema changes

Notes:
- this is a controller-logic foundation slice
- scheduler actor budgeting is still controller-level, but actor activation inside the controller is now demand-aware per slot

## Slice: Scheduler Budgeting For Demanded Slots

Date: 2026-03-26

Summary:
- carried the new slot-level demand thresholds upward into the scheduler layer
- scheduler status now distinguishes:
  - current demanded actors
  - maximum configured actor weight
- scheduler priming now loads controller defs before scheduling so slot-demand math is available earlier
- selection can now reject controllers with `no demanded slots` instead of treating every controller as if all of its slots are always needed

Changed:
- `npc/custom/living_world/_common.txt`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- verified clean map-server startup after the scheduler change
- verified the scheduler helper now contains:
  - controller priming on registry load
  - desired/max actor status formatting
  - `blocked: no demanded slots`

Notes:
- this is still a script-side scheduler refinement
- per-slot demand now affects both controller behavior and scheduler capacity reasoning, even though controller policy still keeps a maximum actor weight for coarse budgeting

## Slice: Activity Log Demand Signals And Lab Summaries

Date: 2026-03-26

Summary:
- added persistent recent-activity ledgers for merchant and guild systems
- extended scheduler demand so controllers can react to event volume, not only coarse
  latest-timestamp and presence signals
- exposed those same recent activity counts through the playerbot merchant and guild
  lab surfaces

Changed:
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_activity_logs.sql`
- `src/map/guild.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `npc/custom/playerbot/playerbot_guild_lab.txt`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-edge-cases.md`

Validation:
- applied `sql-files/upgrades/upgrade_20260326_playerbot_activity_logs.sql`
- rebuilt `map-server` with `cmake --build build --target map-server -j4`
- `bash tools/dev/playerbot-dev.sh restart`
- ran the repo-local guild smoke:
  - `bash tools/ci/playerbot-guild-smoke.sh arm`
  - OpenKore login with the `codex` profile
  - `bash tools/ci/playerbot-guild-smoke.sh check`
- verified guild selftest line:
  - `playerbot_guild_selftest: spawn=1 invite=1 notice=1 activity=1 inviter_gid=1 bot_gid=1 status=2 result=1`
- ran `Playerbot Merchant Lab -> Run merchant selftest` through OpenKore
- verified merchant selftest line:
  - `playerbot_merchant_selftest: bot_id=12 base_ok=1 spawn_ok=1 bootstrap_ok=1 shop_ok=1 activity_ok=1 park_ok=1 reload_ok=1 result=1`
- verified new recent activity rows in SQL:
  - `bot_guild_activity_log` for `PBG150001`
  - `bot_merchant_activity_log` for `quick_merc_alb`

Notes:
- the older runtime tables still own the cheap latest-state view:
  - `bot_guild_runtime`
  - `bot_merchant_runtime`
- the new activity-log tables now own recent event-volume signals used by scheduler
  demand and operator summaries

## Slice: Runtime-Reactive Guild And Market Controller Moods

Date: 2026-03-26

Summary:
- carried guild and economy signals upward from scheduler-only inputs into live
  controller posture
- guild and market controllers now change tick tempo and social pulse cadence based
  on current runtime pressure
- visible controller status now reports the current behavior/mood state so operator
  surfaces show how runtime signals are affecting active logic

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_market_spill_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `doc/project/headless-pc-edge-cases.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- OpenKore status check on `Headless Prontera Guild` showed:
  - `Behavior: alert watch (pressure 9)`
  - policy tick tightened to `1100ms`
- OpenKore status check on `Headless Prontera Social` showed:
  - `Behavior: guild-busy commons (pressure 11)`
  - policy tick tightened to `1300ms`
- OpenKore status check on `Headless Alberta Merchants` showed:
  - `Behavior: hot stall (pressure 14)`
  - policy tick tightened to `1200ms`
- confirmed clean map-server startup after the script-side controller changes

Notes:
- this slice still stays inside the logic/control-plane layer
- “behavior” here means posture, tempo, and presentation intensity, not bespoke AI
- the scheduler still decides whether controllers should be active, but active
  controllers now react to the same guild/economy pressure at runtime

## Slice: Runtime-Reactive Route And Anchor Selection

Date: 2026-03-26

Summary:
- pushed the reactive layer past tick/pulse posture and into actual movement choice
- specialized guild and market controllers can now swap anchor loops or patrol
  routes when runtime pressure changes
- this is the first deeper behavior pass built on the shared reactive controller
  layer rather than one-off script logic

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_market_spill_demo.txt`
- `doc/project/headless-pc-edge-cases.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after the movement-reconfiguration helpers
- OpenKore status check on `Headless Alberta Trade` showed:
  - `Behavior: steady trade (pressure 1)`
- OpenKore status check on the previously reactive guild/economy controllers still
  showed live behavior state without parser/runtime regressions

Notes:
- this slice does not introduce new schema; it deepens how active controllers use
  the existing guild/economy pressure layer
- route and anchor geometry is still script-defined for this phase, but now it is
  switchable at runtime instead of being frozen once the controller primes

## Slice: Runtime-Reactive Social And Merchant Geometry

Date: 2026-03-26

Summary:
- extended the runtime-reactive geometry layer from the specialized guild/trade
  controllers into the base Prontera social, Alberta social, and Alberta
  merchant controllers
- active commons, harbor, and merchant presence can now change where they stand
  or roam as guild/economy pressure rises or cools

Changed:
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- OpenKore status check on `Headless Prontera Guild` still showed live behavior
  state after the social/merchant geometry expansion
- OpenKore status check on `Headless Alberta Merchants` still showed the active
  merchant behavior line after the geometry expansion

Notes:
- this slice stays script-only and uses the same shared invalidation helpers
  introduced in the prior runtime-reactive route-selection slice
- the merchant controller still uses the proxy-shop model; this slice only moves
  the live merchant body within a small stall footprint

## Slice: Runtime-Reactive Guild And Market Flavor Sets

Date: 2026-03-26

Summary:
- deepened the reactive behavior layer so active guild and market controllers
  now swap lines and emotes from runtime pressure, not only route/anchor
  geometry and pulse tempo
- this keeps the system in a shared data-driven controller lane instead of
  jumping to bespoke AI scripts

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_market_spill_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after adding shared talk/emote clear helpers
- OpenKore still reached the merchant and guild controller surfaces cleanly
- no new parser/runtime errors from the runtime-reactive flavor path

Notes:
- flavor-set switching remains controller-local for this phase
- the shared helper layer now supports replacing movement geometry and pulse
  flavor together when a controller changes posture

## Slice: Runtime-Reactive Role Emphasis

Date: 2026-03-26

Summary:
- extended the reactive layer into demanded-slot emphasis
- active controllers can now raise or lower the demand threshold for secondary
  roles like runners, couriers, wanderers, and barkers based on live guild or
  market pressure
- this is the first step where runtime pressure changes which roles matter, not
  only how already-selected roles behave

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_market_spill_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after adding shared runtime min-demand
  override support
- OpenKore status surfaces remained readable after the slot-demand changes

Notes:
- slot definitions are still seeded from SQL, but active controllers can now
  override live min-demand thresholds in script
- this keeps role emphasis dynamic without forcing a schema rewrite in the same
  slice

## Slice: Signal-Directed Guild And Trade Focus

Date: 2026-03-26

Summary:
- pushed two active controllers past generic pressure and into signal-directed
  focus changes
- guild quarter now reacts differently to notice pressure versus storage
  activity
- Alberta trade flow now reacts differently to browse-heavy pressure versus
  sale-heavy pressure

Changed:
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after the signal-directed focus layer
- OpenKore operator surfaces remained reachable after the controller update

Notes:
- this is still lightweight scripted behavior selection, not a generalized AI
  planner
- focus selection is derived from existing runtime signals, not new schema

## Slice: Shared Signal-Directed Social And Merchant Focus

Date: 2026-03-26

Summary:
- extended signal-directed focus into the remaining active social and merchant
  controllers
- moved the focus-selection pattern into shared helpers so controllers stop
  re-deriving the same signal comparisons inline

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after the shared social/merchant focus
  helper layer
- OpenKore operator status remained reachable for:
  - `Headless Prontera Social`
  - `Headless Alberta Social`
  - `Headless Alberta Merchants`

Notes:
- focus derivation is shared now, but concrete anchors/lines still remain
  controller-local for this phase

## Slice: Lightweight Cross-Controller Focus Coordination

Date: 2026-03-26

Summary:
- added a lightweight coordination rule so related controllers on the same map
  can prefer distinct reactive focuses when a reasonable alternate exists
- this is the first cross-controller behavior layer above pure per-controller
  signal reaction

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after the coordination helper layer
- OpenKore operator surfaces remained reachable after the focus-state wiring

Notes:
- coordination is still soft and local; it only avoids duplicate focus when an
  alternate is available
- there is still no central planner or hard reservation system across
  controllers

## Slice: Shared Guild/Trade Focus Helpers

Date: 2026-03-26

Summary:
- moved the remaining guild and trade focus derivation into shared helper
  functions
- widened focus-state publication so more controllers participate in
  coordination and operator status

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_market_spill_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after the shared focus-helper pass
- OpenKore operator status remained reachable for the updated controller set

Notes:
- shared focus helpers now cover guild watch, guild quarter, trade flow, and
  market spill
- focus derivation is shared, but geometry/flavor application still remains
  controller-local

## Slice: Cross-Controller Posture Separation

Date: 2026-03-26

Summary:
- upgraded the shared focus-state layer into visible posture separation for the
  guild watch and Alberta market-spill controllers
- sibling controllers can now steer those lanes away from duplicating the
  obvious focus when a reasonable alternate exists

Changed:
- `npc/custom/playerbot/headless_pc_prontera_guild_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_market_spill_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after the posture-separation pass

Notes:
- this is still a heuristic coordination layer, not a hard planner
- the main gain is visible posture separation, not perfect map-wide behavior

## Slice: Shared Intensity Lanes

Date: 2026-03-26

Summary:
- added a shared `hot`, `warm`, and `cool` lane layer so same-map sibling
  controllers can spread out escalation posture instead of all intensifying at
  once
- tied those lanes into live demanded-slot thresholds

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_prontera_social_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_demo.txt`
- `npc/custom/playerbot/headless_pc_prontera_guild_quarter_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_social_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_trade_demo.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- confirmed clean map-server startup after the shared lane pass

Notes:
- lane choice is still heuristic and local
- the main gain is coordinated escalation and cleaner demanded-slot pressure

## Slice: Structured Trace Events V1

Date: 2026-03-26

Summary:
- added the first append-only structured playerbot trace ledger
- wired the first live trace events into the shared merchant reconcile and
  merchant activity paths
- added an in-game trace viewer surface for quick operator inspection

Changed:
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260326_playerbot_trace_events.sql`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/headless_pc_alberta_merchant_demo.txt`
- `npc/custom/playerbot/playerbot_trace_lab.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `mysql -uroot rathena < sql-files/upgrades/upgrade_20260326_playerbot_trace_events.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- `talknpc 148 135 c r8` from OpenKore to trigger the merchant selftest
- verified `bot_trace_event` rows for:
  - `reconcile.started`
  - `reconcile.fixed`
  - `interaction.completed`

Notes:
- this first observability slice is intentionally script-first
- the trace viewer is an operator/debug surface, not a replay system yet
- movement, scheduler, and controller trace points are scaffolded but still need
  broader runtime exercise and later expansion

## Slice: Shared Perception Facade V1

Date: 2026-03-27

Summary:
- added the first shared read-only playerbot perception/query facade
- exposed the minimum v1 query set through common helper functions instead of
  controller-local ad hoc reads
- added an Alberta lab NPC so operators can inspect live perception results
  through OpenKore or a normal client

Changed:
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_perception_lab.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `bash tools/dev/playerbot-dev.sh restart`
- `talknpc 151 135` from OpenKore to open `Playerbot Perception Lab`
- `talk resp 0` from OpenKore to run the quick merchant probe
- verified live perception output for:
  - self state
  - nearby players / bots / NPCs / shops
  - local heat
  - recent social contacts
  - party / guild context
  - anchor state
  - route viability
  - interaction target state

Notes:
- perception is read-only in this slice
- freshness and confidence are now part of the shared query surface
- anchor occupancy/reservation are still deferred until the reservation model
  lands

## Slice: Reservation Primitives V1

Date: 2026-03-27

Summary:
- added the first authority-backed playerbot reservation ledger
- implemented shared lease / hard-lock primitives for:
  - anchors
  - dialog targets
  - social targets
  - merchant spots
  - party roles
- added an Alberta reservation lab to exercise contention and inspection from a
  live operator path

Changed:
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260327_playerbot_reservations.sql`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_reservation_lab.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `mysql -uroot rathena < sql-files/upgrades/upgrade_20260327_playerbot_reservations.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- OpenKore login in Alberta
- `talknpc 154 135` then:
  - `talk resp 0` for quick anchor contention
  - `talk resp 1` for quick NPC lock contention
- verified live outcomes:
  - primary holder acquires
  - secondary holder is denied
  - resource summary shows active holder, mode, ttl, epoch, and priority
- verified SQL rows in:
  - `bot_reservation`
  - `bot_trace_event` for `reservation.acquired`, `reservation.denied`, and
    `reservation.released`

Notes:
- reservations are now a platform surface instead of controller-local ad hoc
  state
- current stale-holder cleanup only reaps expired rows or truly missing bot
  identities
- controllers are not yet migrated to use these primitives automatically

## Slice: Shared Memory And State Inspector V1

Date: 2026-03-27

Summary:
- added the first shared world/social memory ledger for playerbot runtime state
- exposed the four-layer state model through a live operator inspector
- added recovery-authority summaries so partial-failure ownership rules are
  inspectable from in game

Changed:
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260327_playerbot_shared_memory.sql`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_state_lab.txt`
- `npc/scripts_custom.conf`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `mysql -uroot rathena < sql-files/upgrades/upgrade_20260327_playerbot_shared_memory.sql`
- `bash tools/dev/playerbot-dev.sh restart`
- OpenKore login in Alberta
- `talknpc 157 135 c r0` for quick merchant state
- `talknpc 157 135 c r1` for quick party state
- `talknpc 157 135 c r5` to write a 30s shared-memory probe marker
- `talknpc 157 135 c r4 r2` for the stale-reservation authority summary
- verified SQL rows in:
  - `bot_shared_memory`
  - live lab marker `social / alberta.lab_probe / state.lab`
- verified controller-derived shared-memory rows are being published by the
  guild and merchant focus helpers
- verified the live recovery audit on `quick_merc_alb` reports:
  - world `<offline>`
  - runtime `offline/parked@alberta(52,242)`
  - reservations `0`
  - `Issue: none`

Notes:
- shared memory is medium-lived and intentionally expires; the lab marker is the
  stable validation path for the first slice
- this slice makes shared world/social memory and state boundaries real and
  inspectable, but does not yet migrate every controller-local transient value
  into the ledger
- the state lab now includes a real per-bot recovery audit, not only static
  authority text

## Slice: Transactional Item Layer V1

Date: 2026-03-27

Summary:
- added the first bot-safe transactional item mutation layer on top of the real
  rAthena `inventory` and `storage` tables
- added authoritative live item-count reads for online headless bots
- added a repeatable hidden item selftest and repo-local smoke helper

Changed:
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260327_playerbot_item_audit.sql`
- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_item_lab.txt`
- `npc/scripts_custom.conf`
- `tools/ci/playerbot-item-smoke.sh`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `mysql -uroot rathena < sql-files/upgrades/upgrade_20260327_playerbot_item_audit.sql`
- `cmake --build build --target map-server -j4`
- `bash tools/ci/playerbot-item-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-item-smoke.sh check`
- verified final selftest line:
  - `playerbot_item_selftest: provision_ok=1 spawn_ok=1 ... result=1`
- verified final persisted item state for `quick_item_open`:
  - inventory: Knife `1201 x1` equipped, Red Potion `501 x2`
  - storage: Red Potion `501 x1`
- verified audit rows in `bot_item_audit` for:
  - `inventory_add`
  - `inventory_remove`
  - `equip`
  - `unequip`
  - `storage_deposit`
  - `storage_withdraw`

Notes:
- the item layer intentionally reuses normal rAthena item semantics instead of
  inventing a parallel bot-only inventory store
- authoritative item reads now distinguish online live inventory/equipment from
  offline persisted SQL counts
- the hidden selftest path is the stable validation lane; the visible item lab
  remains for operator inspection and manual verbs

## Slice: Participation Hooks V1

Date: 2026-03-27

Summary:
- added the first direct NPC/dialog, storage-session, and trade start/cancel
  participation hooks for live playerbots
- added structured interaction traces for those mechanic paths
- added a repeatable hidden participation selftest and repo-local smoke helper

Changed:
- `src/map/script.cpp`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `npc/scripts_custom.conf`
- `tools/ci/playerbot-participation-smoke.sh`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `cmake --build build --target map-server -j4`
- `bash tools/ci/playerbot-participation-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-participation-smoke.sh check`
- verified final selftest line:
  - `playerbot_participation_selftest: spawn_ok=1 dialog_ok=1 storage_basic_ok=1 storage_recover_ok=1 trade_ok=1 park_ok=1 trace_ok=1 result=1`
- verified recent interaction traces in `bot_trace_event` for:
  - `npc`
  - `npc_menu`
  - `npc_close`
  - `storage`
  - `trade`

Notes:
- the dialog probe was intentionally made multi-step so the selftest proves the
  full `start -> next -> menu -> close` path instead of relying on immediate
  script auto-close
- storage recovery in this slice is still validated as session ownership reset
  across despawn/respawn, not broader transactional storage rollback
- trade support in this slice is intentionally narrow: request/open state and
  cancel/clear integrity first, not full item exchange semantics

## Slice: Participation Hooks V2

Date: 2026-03-27

Summary:
- deepened the participation layer to cover numeric NPC input, explicit storage
  recovery, and full trade accept/lock/commit integrity
- added char-id-targeted trade helpers so the validation lane no longer depends
  on attached-player NPC ownership
- extended the hidden participation selftest into a full end-to-end mechanic
  proof for dialog, storage recovery, and trade completion

Changed:
- `src/map/script.cpp`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `cmake --build build --target map-server -j4`
- `bash tools/ci/playerbot-participation-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-participation-smoke.sh check`
- verified final selftest line:
  - `playerbot_participation_selftest: spawn_ok=1 dialog_ok=1 storage_basic_ok=1 storage_manual_ok=1 storage_recover_ok=1 trade_ok=1 park_ok=1 trace_ok=1 result=1.`
- verified live trade completion in the OpenKore client:
  - `Engaged Deal with QuickPartOpen`
  - `Deal Complete`
- verified recent interaction traces for:
  - `npc_input`
  - `trade_item`
  - `trade_ok`
  - `trade_commit`

Notes:
- native rAthena trade request and trade accept paths reject a target that is
  still attached to an NPC script (`npc_id != 0`)
- the selftest now avoids that invalid harness state by running the player-side
  trade accept/lock/commit path through char-id-targeted helpers instead of
  attached-player NPC calls
- `playerbot_tradecommit` now treats `deal_locked >= 2` as local commit success
  even before the peer-side commit clears the trade, while the selftest still
  separately proves final trade clearance

## Slice: Participation Hooks V3

Date: 2026-03-27

Summary:
- deepened the participation lane again with richer dialog input/branching,
  storage mutation recovery, and trade rollback after staged negotiation
- added string NPC input and char-targeted trade staging helpers so the same
  repo-local selftest can prove more realistic multi-step mechanic flows

Changed:
- `src/map/script.cpp`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `cmake --build build --target map-server -j4`
- `bash tools/ci/playerbot-participation-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-participation-smoke.sh check`
- verified final selftest line:
  - `playerbot_participation_selftest: spawn_ok=1 dialog_ok=1 dialog_deep_ok=1 storage_basic_ok=1 storage_manual_ok=1 storage_recover_ok=1 storage_mutation_ok=1 trade_ok=1 trade_recover_ok=1 park_ok=1 trace_ok=1 result=1.`
- verified live client outcomes:
  - clean trade completion
  - clean trade cancel after staged negotiation
- verified recent interaction traces for:
  - `npc_inputstr`
  - `trade_zeny`
  - `trade_item`
  - `trade_commit`

Notes:
- the deeper dialog probe now proves:
  - string input
  - nested branch selection
  - deterministic item hand-in path
- storage mutation recovery now proves that a deposit made during an open
  storage session persists cleanly across forced despawn/respawn while the
  reopened bot returns with no lingering storage ownership
- trade recovery now proves rollback after staged negotiation rather than only
  the clean completion path

## Slice: Participation Trace Bridge

Date: 2026-03-27

Summary:
- folded the transactional item/storage audit lane into the structured
  interaction trace timeline
- kept `bot_item_audit` as the authoritative per-mutation ledger while also
  emitting matching `bot_trace_event` rows for timeline/replay debugging

Changed:
- `src/map/script.cpp`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/headless-pc-v1-slice-log.md`

Validation:
- `cmake --build build --target map-server -j4`
- `bash tools/ci/playerbot-item-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-item-smoke.sh check`
- `bash tools/ci/playerbot-participation-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-participation-smoke.sh check`
- verified item selftest still passes:
  - `playerbot_item_selftest: ... result=1.`
- verified participation selftest still passes:
  - `playerbot_participation_selftest: ... result=1.`
- verified recent `bot_trace_event` rows now include item/storage mutation
  target types:
  - `inventory_add`
  - `inventory_remove`
  - `equip`
  - `unequip`
  - `storage_deposit`
  - `storage_withdraw`

Notes:
- this slice does not replace `bot_item_audit`; it makes the same mutations
  visible in the broader structured timeline used for controller and mechanic
  debugging
- item/storage mutation traces currently reuse the existing `interaction` phase
  because the trace schema is still on the first minimal event family set

## Participation Hooks V4

### Summary

Deepened the participation foundation in three adjacent areas:
- explicit trade recovery helpers for stale or interrupted trade state
- reservation-backed contested NPC dialog starts
- a multi-NPC quest-style participation proof that carries state across two NPCs

### Files Touched

- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### Runtime Additions

New script buildins:
- `playerbot_traderecover(bot_key$)`
- `playerbot_tradecharrecover(char_id)`

New shared script helpers:
- `F_PB_PART_NPCResourceKey$`
- `F_PB_PART_NPCStartReserved`
- `F_PB_PART_NPCCloseReserved`
- `F_PB_PART_NPCRecoverReserved`

### Behavior

- trade recovery now has an explicit bot-safe path that:
  - cancels a live trade if a partner still exists
  - force-clears stale local trade state if flags remain after cancel
  - emits interaction traces with `target_type = trade_recover`
- contested dialog starts can now reserve `dialog_target` resources before
  calling `playerbot_npcstart`
- participation now has a multi-NPC relay proof:
  - `Playerbot Quest Relay A`
  - `Playerbot Quest Relay B`
  - the proof covers:
    - cross-NPC state carry
    - string input
    - reserved dialog contention
    - recovery/cleanup between relay steps

### Validation

- rebuilt `map-server`
- restarted with `bash tools/dev/playerbot-dev.sh restart`
- armed and ran the repo-local participation smoke:
  - `bash tools/ci/playerbot-participation-smoke.sh arm`
  - OpenKore `codex` login
  - `bash tools/ci/playerbot-participation-smoke.sh check`
- final selftest line:
  - `playerbot_participation_selftest: spawn_ok=1 dialog_ok=1 dialog_deep_ok=1 dialog_quest_ok=1 storage_basic_ok=1 storage_manual_ok=1 storage_recover_ok=1 storage_mutation_ok=1 trade_ok=1 trade_recover_ok=1 trade_force_clear_ok=1 park_ok=1 trace_ok=1 result=1.`

### Notes

- the quest relay proof intentionally validates state handoff and participation
  legality, not quest-content complexity
- reservation-backed dialog starts are still opt-in through shared helpers; the
  generic `playerbot_npcstart` verb itself remains unchanged

## Prontera Ambient Filler Cleanup

### Summary

Replaced Prontera's ambient roaming filler actors with harmless low-level
mob-backed fillers so the town no longer surfaces Alarm actors during normal
play and GM/OpenKore mob inspection.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/living_world/prontera_ambient.txt`

### Behavior

- added `F_LW_SetAmbientMobActor(...)` as a shared ambient helper for harmless
  mob-backed fillers
- moved the Prontera ambient lane onto low-level mobs like:
  - `Poring`
  - `Fabre`
  - `Drops`
  - `Lunatic`
  - `Chonchon`
  - `Pupa`
- this keeps the existing Prontera ambient hotspot rotation and chatter, but
  removes the misleading Alarm mob presentation in town

### Validation

- restarted with `bash tools/dev/playerbot-dev.sh restart`
- logged in with the repo-local `testgm` OpenKore profile
- verified `@mobsearch Alarm` in Prontera returns no results after the change

## Slice 54: Playerbot Participation Recovery Audits

### Goal

Deepen the participation recovery lane so mixed NPC/storage/trade failures leave
an authoritative audit trail and can be cleared through explicit recovery verbs.

### Files Touched

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260327_playerbot_recovery_audit.sql` (new)
- `src/map/script.cpp`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- added `bot_recovery_audit` as an append-only recovery ledger
- added:
  - `playerbot_npcrecover(bot_key$)`
  - `playerbot_participationrecover(bot_key$)`
- participation recovery now clears:
  - active NPC/dialog state
  - open storage state
  - stale trade state
- when the recovering bot is one endpoint of a trade, the recovery pass also
  force-clears the live peer if stale trade flags remain on that side
- extended `Playerbot Participation Lab` to inspect the latest recovery audit
  row and to prove:
  - explicit NPC recovery
  - composite participation recovery under mixed NPC/storage/trade pressure

### Validation

- applied `upgrade_20260327_playerbot_recovery_audit.sql`
- rebuilt `map-server`
- restarted with `bash tools/dev/playerbot-dev.sh restart`
- armed and ran the repo-local participation smoke:
  - `bash tools/ci/playerbot-participation-smoke.sh arm`
  - OpenKore login with the `codex` profile
  - `bash tools/ci/playerbot-participation-smoke.sh check`
- final selftest result:
  - `playerbot_participation_selftest: ... npc_recover_ok=1 ... participation_recover_ok=1 ... recovery_audit_ok=1 result=1.`
- verified `bot_recovery_audit` rows for:
  - `npc / recover / ok / npc.cleared`
  - `participation / recover / ok / participation.cleared`

### Notes

- the composite participation proof intentionally does not require trade accept
  to complete while the bot is simultaneously inside NPC/storage state
- the proof only requires:
  - mixed-state setup
  - successful authoritative recovery
  - both bot and live peer trade state ending clear


## Slice 55: Storage And Trade Recovery Audit Expansion

### Goal

Push the recovery contract deeper so storage and trade recovery are audited as
first-class recovery scopes, not only as part of the broader participation
wrapper.

### Files Touched

- `src/map/script.cpp`
- `npc/custom/playerbot/playerbot_state_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- `playerbot_storagerecover(bot_key$)` now writes authoritative recovery audit
  rows for scope `storage`
- `playerbot_traderecover(bot_key$)` now writes authoritative recovery audit
  rows for scope `trade`
- trade recovery now also force-clears the live peer when stale trade flags
  remain on that side
- `Playerbot State Lab` can now inspect:
  - latest recovery audit for `quick_merc_alb`
  - latest recovery audit for `quick_party_open`
  - latest recent storage/trade/participation audits across bots

### Validation

- rebuilt `map-server`
- restarted with `bash tools/dev/playerbot-dev.sh restart`
- re-ran the repo-local participation smoke:
  - `bash tools/ci/playerbot-participation-smoke.sh arm`
  - OpenKore login with the `codex` profile
  - `bash tools/ci/playerbot-participation-smoke.sh check`
- final selftest result stayed green:
  - `playerbot_participation_selftest: ... result=1.`
- verified recent `bot_recovery_audit` rows for:
  - `storage / recover / ok / storage.cleared`
  - `trade / recover / ok / trade.cleared`
  - `trade / recover / noop / already.clear`
  - `participation / recover / ok / participation.cleared`


## Slice 56: Repo-Local Playerbot Trace Tooling

### Goal

Add a repo-local CLI tool for inspecting `bot_trace_event` so operators can
answer why bots were assigned, failed, parked, or reconciled without querying
SQL by hand.

### Files Touched

- `tools/ci/playerbot-trace.sh` (new)
- `doc/project/playerbot-trace-tooling.md` (new)
- `doc/project/headless-pc-v1-slice-log.md`

### What Changed

- added `tools/ci/playerbot-trace.sh`
- added `doc/project/playerbot-trace-tooling.md`
- the CLI supports:
  - `recent`
  - `failures`
  - `bot`
  - `controller`
  - `map`
  - `action`
  - `why-assigned`
  - `why-failed`
  - `why-parked`
  - `stats`
- aligned DB defaults with the repo-local dev config:
  - `rathena`
  - `rathena_secure_2024`
- hardened the tool for the integrated baseline:
  - fixed unset color handling
  - switched MySQL queries to batch/tab output
  - fixed `set -e` counter exits
  - stabilized empty-column parsing so controller/map/reason fields do not shift

### Validation

- `bash tools/ci/playerbot-trace.sh --help`
- `bash tools/ci/playerbot-trace.sh --no-color recent 5`
- `bash tools/ci/playerbot-trace.sh --no-color stats`
- `bash tools/ci/playerbot-trace.sh --no-color controller "MerchantRuntimeReconcile" 3`

### Notes

- this slice is intentionally repo-local CLI tooling only
- it does not change runtime/controller semantics
- replay and richer timeline reconstruction are still deferred


## Slice 57: Playerbot Reservation Inspector

### Goal

Build repo-local reservation inspection tooling around `bot_reservation` so
operators can answer:
- What leases/locks are currently active?
- Who holds them?
- What is stale or expired?
- Why is contention happening?
- Which resources are hot?

### Files Touched

- `tools/ci/playerbot-reservations.sh` (new)
- `doc/project/playerbot-reservation-inspector.md` (new)
- `doc/project/headless-pc-v1-slice-log.md`

### What Changed

- Added `tools/ci/playerbot-reservations.sh` CLI tool with commands:
  - `active` - Show currently active reservations
  - `recent` - Show recent reservation trace events
  - `expired` - Show expired reservations
  - `stale` - Show stale/orphan reservations
  - `holder <id>` - Show reservations by bot/controller
  - `resource <key>` - Show reservations for specific resource
  - `hot [N]` - Show most contested resources
  - `denied [N]` - Show recent reservation denials
  - `why-denied <key>` - Explain why a resource was denied
  - `stats` - Show reservation statistics

- Added `doc/project/playerbot-reservation-inspector.md` documentation

- Features:
  - Filter by resource type (`-t anchor|dialog_target|...`)
  - Filter by lock mode (`-m lease|hard_lock`)
  - Time window filtering (`--since MINUTES`)
  - Raw output for scripting (`--raw`)
  - Colorized output (disabled with `--no-color`)
  - DB defaults aligned with repo-local config

### Validation

- `bash tools/ci/playerbot-reservations.sh --help` - Help output works
- `bash tools/ci/playerbot-reservations.sh --no-color active 5` - Active reservations query works
- `bash tools/ci/playerbot-reservations.sh --no-color stats` - Statistics summary works
- `bash tools/ci/playerbot-reservations.sh --no-color holder "ReservationAuditTest" 5` - Holder query works
- `bash tools/ci/playerbot-reservations.sh --no-color hot 5` - Contention analysis works

### Deferrals

This slice does not add:

- In-game reservation inspector NPC (separate from existing labs)
- Real-time reservation monitoring
- Automatic stale reservation cleanup
- Reservation prediction or forecasting

## Slice 58: Playerbot Reservation Recovery Audits

### Goal

Push reservation cleanup into the same recovery-audit platform already used by
NPC, storage, trade, and mixed participation recovery so stale lease cleanup is
inspectable instead of only implicit.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_reservation_lab.txt`
- `npc/custom/playerbot/playerbot_state_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added shared recovery-audit write helper:
  - `F_PB_RECOVERY_Audit`
- Extended `F_PB_RES_ReapExpired` so both cleanup paths now emit
  `bot_recovery_audit` rows:
  - expired leases -> `reservation.expired`
  - stale holder identity -> `reservation.stale_holder`
- Added shared summary helper:
  - `F_PB_RECOVERY_BuildRecentAudit$`
- Extended `Playerbot Reservation Lab` to show recent reservation recovery
  audits.
- Extended `Playerbot State Lab` so operator recovery views can show the latest
  reservation-audit rows alongside storage/trade/participation audits.

### Validation

- `bash tools/dev/playerbot-dev.sh restart`
- seeded stale and expired reservation rows directly in `bot_reservation`
- ran the repo-local participation smoke path so a real reservation acquire
  forced `F_PB_RES_ReapExpired`
- verified seeded rows were removed from `bot_reservation`
- verified fresh `bot_recovery_audit` rows for:
  - `reservation / reap / ok / reservation.expired`
  - `reservation / reap / ok / reservation.stale_holder`

### Deferrals

This slice does not add:

- automatic recovery-audit emission on every manual reservation release
- reservation epoch conflict audits beyond stale/expired cleanup
- replay/timeline stitching between recovery audits and trace events

## Slice 59: Playerbot Ownership Recovery Audits

### Goal

Make controller-slot ownership drift explainable and recoverable so pooled actor
handoff conflicts stop looking like silent controller flakiness.

### Files Touched

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_state_lab.txt`
- `tools/ci/playerbot-state-smoke.sh` (new)
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Hardened `F_LW_HPC_DefResolveActor` so stale pooled-slot assignments now emit:
  - ownership recovery audits in `bot_recovery_audit`
  - `reconcile.fixed` traces with `claim.lost`
- Hardened `F_LW_HPC_DefReleaseActor` so release no longer blindly pretends a
  normal release happened when the pool owner already drifted.
- Added ownership recovery detail codes:
  - `owner.split`
  - `path.owner_split`
  - `slot.owner_missing`
  - plus existing profile/role drift handling during slot repair
- Extended `Playerbot State Lab`:
  - manual `Run ownership selftest`
  - latest ownership-audit inspection
- Added repeatable repo-local smoke helper:
  - `bash tools/ci/playerbot-state-smoke.sh arm`
  - `bash tools/ci/playerbot-state-smoke.sh check`

### Validation

- `bash -n tools/ci/playerbot-state-smoke.sh`
- `bash tools/ci/playerbot-state-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-state-smoke.sh check`
- final selftest passed on the live baseline:
  - `playerbot_state_selftest: claim_ok=1 drift_ok=1 audit_ok=1 trace_ok=1 release_ok=1 result=1.`
- verified fresh rows in:
  - `bot_recovery_audit` -> `ownership / repair / ok / owner.split`
  - `bot_trace_event` -> `reconcile.fixed / claim.lost / owner.split`

### Deferrals

This slice does not add:

- full epoch-token persistence outside the current controller/runtime layer
- automatic repair of every pool-owner drift case across every controller family
- broader contested handoff recovery across every controller family

## Slice 58: Unified Bot Timeline Surfaces

### Summary

This slice adds a unified per-bot observability timeline that merges
`bot_trace_event` and `bot_recovery_audit` into one operator-facing view. The
goal is to answer "what just happened to this bot?" without hopping between
trace and recovery menus.

### Files

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_trace_lab.txt`
- `npc/custom/playerbot/playerbot_state_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added shared helper:
  - `F_PB_OBS_BuildBotTimeline$`
- The new timeline builder:
  - resolves a bot key through the current bot summary path
  - reads both trace rows and recovery audits
  - sorts them into one descending timeline
  - surfaces:
    - trace or audit kind
    - scope/phase
    - action
    - result
    - controller or authority
    - reason / fallback / error / detail when present
- Extended `Playerbot Trace Lab` with:
  - `Bot timeline`
- Extended `Playerbot State Lab` with:
  - `Inspect bot timeline`

### Validation

- `bash tools/dev/playerbot-dev.sh restart`
- OpenKore login with the `codex` profile
- verified `Playerbot Trace Lab -> Bot timeline` works for:
  - `quick_merc_alb`
- verified `Playerbot State Lab -> Inspect bot timeline` works for:
  - `quick_merc_alb`
  - `quick_party_open`
- verified the timeline includes mixed rows from:
  - `bot_trace_event`
  - `bot_recovery_audit`

### Deferrals

This slice does not add:

- a dedicated CLI timeline joiner on top of the new lab view
- replay/snapshot semantics
- automatic correlation IDs between trace and recovery rows

## Slice 59: Contested Handoff Recovery Audits

### Summary

This slice broadens ownership/handoff recovery coverage for pooled controller
ticks. The goal is to stop treating live owner conflicts and failed claims as
silent scheduler churn.

### Files

- `npc/custom/living_world/_common.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added shared helper:
  - `F_PB_DB_BotIdByCharId`
- `F_LW_HPC_DefResolveActor` and `F_LW_HPC_DefReleaseActor` now use the shared
  bot-id lookup instead of ad hoc SQL arrays.
- `F_LW_HPC_DefTickActor` now audits and traces two contested handoff cases that
  previously returned `0` quietly:
  - live owner mismatch during tick:
    - detail `live.owner_split`
  - failed `headlesspc_claim(...)` during tick:
    - detail `claim.denied`
- For pooled actors, those failures now clear the local slot assignment so the
  controller can reacquire cleanly on a later tick instead of pretending the
  stale handoff is still valid.

### Validation

- `bash tools/dev/playerbot-dev.sh restart`
- `bash -n tools/ci/playerbot-state-smoke.sh`
- `bash tools/ci/playerbot-state-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-state-smoke.sh check`
- verified the ownership smoke still passes on the integrated baseline

### Deferrals

This slice does not add:

- a forced live `claim.denied` smoke harness yet
- epoch-token persistence outside the current controller/runtime layer
- automatic reservation cleanup for every contested live-owner mismatch

## Slice 60: Unified Failure Surfaces

### Summary

This slice adds one bot-focused failure surface that combines current
participation state, held reservations, recent failed traces, and recent
recovery audits. The goal is to shorten the operator path for answering "why is
this bot stuck or failing right now?"

### Files

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `npc/custom/playerbot/playerbot_trace_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added shared helper:
  - `F_PB_OBS_BuildFailureSurface$`
- The new failure surface includes:
  - current live participation flags:
    - headless status
    - NPC active
    - storage open
    - trade active
    - trade lock
    - trade partner
  - held reservations
  - recent failed or recovery-relevant trace rows
  - recent recovery audits across:
    - npc
    - storage
    - trade
    - participation
    - reservation
    - ownership
- Extended `Playerbot Participation Lab` with:
  - `Inspect failure surface`
- Extended `Playerbot Trace Lab` with:
  - `Bot failure surface`

### Validation

- `bash tools/dev/playerbot-dev.sh restart`
- `bash tools/ci/playerbot-participation-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-participation-smoke.sh check`
- verified the participation selftest still passes on the integrated baseline
- verified the new failure surface works for:
  - `quick_part_open`

### Deferrals

This slice does not add:

- a CLI failure-surface joiner
- correlation ids between trace rows and audit rows
- automatic grouping of related failures into one incident object

## Slice 63: Bot Incident Surfaces

### Summary

This slice consolidates the current recovery/debug primitives into one
operator-facing incident surface per bot. The goal is to answer "what is wrong
with this bot right now?" without jumping between separate state, failure,
timeline, and dialog-conflict views.

### Files

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_state_lab.txt`
- `npc/custom/playerbot/playerbot_trace_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added shared helper:
  - `F_PB_OBS_BuildIncidentSurface$`
- The new incident surface now combines:
  - current recovery authority summary
  - current failure surface
  - active dialog conflict surface when a dialog reservation is present
  - recent mixed trace/audit timeline rows
- Extended `Playerbot State Lab` with:
  - `Inspect incident surface`
- Extended `Playerbot Trace Lab` with:
  - `Bot incident surface`

### Validation

- `bash tools/dev/playerbot-dev.sh restart`
- `bash -n tools/ci/playerbot-state-smoke.sh`
- `bash tools/ci/playerbot-state-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-state-smoke.sh check`
- verified the integrated state smoke still passes:
  - `playerbot_state_selftest: ... result=1`

### Deferrals

This slice does not add:

- persistent incident records
- automatic correlation ids between incident surfaces and raw rows
- cross-bot incident clustering
- CLI incident inspection outside the in-game lab surfaces

## Slice 62: Dialog Drift Recovery

### Summary

This slice formalizes one more partial-failure authority rule: a
`dialog_target` reservation is stale if the holder no longer has an active NPC
session. The reaper now clears that drift automatically, audits it, and exposes
the conflict through the participation lab.

### Files

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Extended recovery authority summaries with:
  - `dialog_inactive_reservation`
- Extended bot recovery audit summaries so they now flag:
  - held dialog locks with no active NPC session
- Extended `F_PB_RES_ReapExpired` so it also reaps:
  - live `dialog_target` reservations whose holder bot is not inside an active
    NPC session
- That dialog-drift cleanup now writes:
  - `bot_recovery_audit` detail `reservation.dialog_inactive`
  - matching `reservation.released` trace rows with
    `reason_code=restart.recovery`
- Added shared operator helper:
  - `F_PB_OBS_BuildDialogConflictSurface$`
- Extended `Playerbot Participation Lab` with:
  - richer dialog conflict inspection
  - `Run dialog drift probe`
- Updated the participation selftest so it now proves:
  - reserved quest-relay dialog
  - raw dialog close without reserved release
  - one reaper pass clears the stale dialog lock

### Validation

- `bash tools/dev/playerbot-dev.sh restart`
- `bash tools/ci/playerbot-participation-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-participation-smoke.sh check`
- verified recovery audit rows for:
  - `reservation / reap / ok / reservation.dialog_inactive`
- verified matching trace rows for:
  - `reservation.released / dialog_target / npc:Playerbot Quest Relay A /
    restart.recovery`

### Deferrals

This slice does not add:

- generic inactive-lock cleanup for non-dialog reservation types
- cross-bot dialog arbitration beyond the existing reservation winner
- automatic incident grouping between dialog drift, ownership drift, and
  participation recover-all

## Slice 61: Participation Recover-All

### Summary

This slice widens participation recovery so overlapping interaction state and
bot-held dialog reservations recover together. The goal is to treat
participation cleanup as one incident instead of separate NPC/storage/trade and
reservation chores.

### Files

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added shared helper:
  - `F_PB_PART_RecoverAll`
- The new helper now:
  - runs `playerbot_participationrecover(...)`
  - releases all held reservations for the bot, optionally scoped by controller
  - writes reservation recovery audits
  - emits a matching interaction trace row for the reservation cleanup leg
- Extended `Playerbot Participation Lab` with:
  - `Run recover-all probe`
- Updated the participation selftest so the overlapping-recovery lane now proves:
  - active NPC state
  - held dialog reservation
  - storage open
  - trade request/ack
  - one recover-all pass clears the entire stack

### Validation

- `bash tools/dev/playerbot-dev.sh restart`
- `bash tools/ci/playerbot-participation-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-participation-smoke.sh check`
- verified the participation selftest still passes on the integrated baseline
- verified reservation cleanup is included in the overlapping recovery path

### Deferrals

This slice does not add:

- per-reservation correlation ids on recover-all traces
- automatic recovery of reservations held on behalf of other bots/controllers
- a dedicated CLI recover-all inspector

## Slice 60: Playerbot Pool Observability CLI Tool

### Summary

Added a repo-local CLI tool for inspecting pool state that accurately reflects
what can be queried from SQL config tables versus what requires live runtime
inspection.

### Files

- `tools/ci/playerbot-pool.sh` (new)
- `doc/project/headless-pc-v1-slice-log.md`

### What Changed

- Added `tools/ci/playerbot-pool.sh` with commands:
  - `status` - Pool inventory with configured thresholds
  - `pools [N]` - List all pools with supply counts  
  - `constrained` - Pools where parked supply < configured threshold
  - `supply` - Parked vs active bot supply breakdown
  - `controller <name>` - Pool bindings for a controller
  - `pool <name>` - Details for a specific pool
  - `stats` - Pool statistics summary

- Precise terminology:
  - "Configured threshold" = `min_demand_users` from `bot_controller_slot`
  - "Parked supply" = bots with `current_state='offline'`, `park_state='parked'`
  - "Active supply" = bots with `current_state != 'offline'`
  - Explicitly NOT labeled as "live demand" (which requires runtime scheduler state)

- Clear limitations documented:
  - Tool reads SQL config, NOT live scheduler runtime state
  - Configured threshold != live requested demand
  - For live truth, use in-game scheduler NPCs or trace inspection

### Validation

- `bash tools/ci/playerbot-pool.sh --help`
- `bash tools/ci/playerbot-pool.sh --no-color status`
- `bash tools/ci/playerbot-pool.sh --no-color pools 5`
- `bash tools/ci/playerbot-pool.sh --no-color constrained`
- `bash tools/ci/playerbot-pool.sh --no-color controller "social.prontera"`
- `bash tools/ci/playerbot-pool.sh --no-color stats`
- All commands exit 0 with clear labeling of what each value represents

### Deferrals

This slice does not add:

- Live scheduler runtime state queries (would need script/runtime surface)
- True "requested demand" visibility (runtime signal dependent)
- Automatic pool rebalancing or controller recommendations
- Pool shortage alerts or monitoring

## Slice 66: Playerbot Map-Change Mechanic Continuity

### Summary

Extended the combat/status frontier so headless bots now clear active
participation state and held reservations on real map changes, not only on
death and respawn.

### Files

- `src/map/pc.cpp`
- `src/map/script.cpp`
- `npc/custom/playerbot/playerbot_combat_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Refactored playerbot participation cleanup into a lifecycle-aware helper so
  cleanup traces can be emitted from more than one transition path.
- Added map-change cleanup in `pc_setpos(...)` for playerbot actors that are
  already live in the world:
  - stop attack intent
  - clear active NPC/dialog state
  - clear storage ownership
  - clear trade state on both sides
  - release held reservations
- Added a `mapchange / interrupt` recovery audit surface plus matching
  `reconcile.fixed` / `reservation.released` trace coverage with
  `reason_code = 'map.changed'`.
- Normalized status trace reason codes to fit the current enum-backed
  `bot_trace_event` schema while keeping status-specific details in
  `error_detail`.
- Expanded `Playerbot Combat Lab` so the combat selftest now proves warp-driven
  cleanup for:
  - NPC/dialog state
  - storage state
  - trade state
  - held reservations

### Validation

- `cmake --build build --target map-server -j4`
- `bash tools/ci/playerbot-foundation-smoke.sh run`
- aggregate result:
  - `playerbot_combat_selftest ... result=1`
  - full foundation pass green

### Deferrals

This slice does not add:

- map-change-specific planner logic
- cross-map reservation transfer
- richer event/instance cleanup beyond the current playerbot participation
  surfaces

## Slice 65: Playerbot Status Continuity Baseline

### Summary

Implemented the first runtime status continuity layer on top of the combat
frontier so status behavior is now proven across death, respawn, map change,
and participation recovery.

### Files

- `src/map/script.cpp`
- `src/map/pc.cpp`
- `npc/custom/playerbot/playerbot_combat_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added shared playerbot status-state helpers in `script.cpp`:
  - `playerbot_statuscount(bot_key$)`
  - `playerbot_statussummary(bot_key$)`
- Added runtime status-state helpers in `pc.cpp` so death/respawn cleanup can
  audit tracked status continuity for headless bots.
- Added status recovery audits:
  - `status / cleanup`
  - `status / reconcile`
- Expanded the combat selftest so it now proves:
  - direct status apply/clear
  - status persistence across map change
  - participation recovery does not mutate active status
  - buff/ailment cleanup on death
  - fresh status state after respawn
- Tightened the combat acceptance gate so the new status continuity checks are
  part of the real aggregate foundation pass.

### Validation

- `cmake --build build --target map-server -j4`
- `bash tools/ci/playerbot-foundation-smoke.sh run`

Integrated result:

- aggregate foundation smoke is green again
- combat selftest now proves:
  - `status_map_cont_ok=1`
  - `status_recover_ok=1`
  - `status_death_clear_ok=1`
  - `status_respawn_fresh_ok=1`
  - `status_trace_ok=1`
  - `status_audit_ok=1`
- recent recovery audits now include:
  - `status / cleanup / ok`
  - `status / reconcile / ok`

### Deferrals

This slice still does not add:

- skill-cast status logic
- broader map-change trace coverage outside the current selftest proof
- persistent status memory
- event-specific status continuity beyond the current combat/death/respawn lane

## Slice 64: Combat Trade-Interrupt Proof

### Summary

Closed the remaining combat harness gap so the combat selftest now proves trade
interrupt cleanup under death/respawn instead of only exposing it in the debug
line.

### Files

- `npc/custom/playerbot/playerbot_combat_lab.txt`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Fixed the combat selftest to capture the live inviter identity before running
  the trade-interrupt path:
  - `.inviter_char_id`
  - `.inviter_aid`
  - `.inviter_name$`
- Fixed the trade-interrupt setup position so the respawned combat bot is moved
  back into the same Alberta neighborhood already proven by the participation
  harness:
  - `headlesspc_setpos(.char_id, "alberta", 161, 136)`
- This removed the two harness-specific false failures that had kept the trade
  interrupt path from being a real acceptance proof:
  - missing inviter target identity
  - trade request from the wrong live position

### Validation

- `bash tools/ci/playerbot-combat-smoke.sh arm`
- OpenKore login with the `codex` profile
- `bash tools/ci/playerbot-combat-smoke.sh check`
- `bash tools/ci/playerbot-foundation-smoke.sh run`

Integrated result:

- `playerbot_combat_selftest ... result=1`
- combat selftest now proves:
  - `trade_interrupt_req_ok=1`
  - `trade_interrupt_ack_ok=1`
  - `trade_interrupt_active_ok=1`
  - `trade_interrupt_kill_ok=1`
  - `trade_interrupt_dead_ok=1`
  - `trade_interrupt_clear_ok=1`
  - `trade_interrupt_respawn_req_ok=1`
  - `trade_respawn_ok=1`
- recent aggregate smoke now includes:
  - `trade / interrupt / ok / combat.death.interrupt`
  - `combat.completed / trade / restart.recovery / ok`
- aggregate foundation smoke remains green end-to-end

### Deferrals

This slice still does not add:

- combat skill-cast hooks
- loot-routing behavior
- richer post-combat event logic
- broader status continuity beyond the current legal combat/death/respawn layer

## Slice 61: Combat-Pressure Mechanic Cleanup

### Summary

Extended the combat foundation so death and respawn now prove deterministic
interrupt cleanup for active NPC and storage state, with aggregate smoke timing
fixed to wait for the combat selftest line instead of racing the coordinator.

### Files

- `src/map/pc.cpp`
- `npc/custom/playerbot/playerbot_combat_lab.txt`
- `tools/ci/playerbot-combat-smoke.sh`
- `tools/ci/playerbot-foundation-smoke.sh`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Extended runtime combat cleanup in `pc.cpp`:
  - death/respawn participation cleanup now emits per-scope interrupt audits for:
    - `npc`
    - `storage`
    - `trade`
  - matching combat-phase traces now show scope-specific interrupt cleanup
- Deepened `Playerbot Combat Lab`:
  - selftest now proves:
    - combat pre-clear before attack intent
    - NPC-on-death interrupt cleanup
    - storage-on-death interrupt cleanup
  - trade-on-death remains observable in debug output but is not yet part of the
    slice acceptance gate
- Extended `playerbot-combat-smoke.sh` to show interrupt-scope audits alongside
  combat audits.
- Hardened `playerbot-foundation-smoke.sh`:
  - after `stage=done`, the runner now waits for the combat selftest line before
    checking results
  - this removes the earlier race where the coordinator finished before the
    combat selftest emitted its final result line

### Validation

- `cmake --build build --target map-server -j4`
- `git diff --check`
- `bash tools/ci/playerbot-combat-smoke.sh check`
- `bash tools/ci/playerbot-foundation-smoke.sh run`

Integrated result:

- `playerbot_combat_selftest ... result=1`
- aggregate foundation smoke remains green with:
  - `stage=state`
  - `stage=guild`
  - `stage=item`
  - `stage=merchant`
  - `stage=participation`
  - `stage=combat`
  - `stage=done`
- recent recovery/audit rows now include:
  - `npc / interrupt / ok / combat.death.interrupt`
  - `storage / interrupt / ok / combat.death.interrupt`

### Deferrals

This slice does not yet claim:

- stable trade-on-death interrupt participation as part of the acceptance gate
- broader mechanic cleanup beyond the current NPC/storage combat-pressure cases
- richer event or combat behavior on top of the legal cleanup hooks

## Slice 61: Playerbot Loadout Continuity Baseline

### Summary

Added the first persistent intended-equipment authority for bots and wired
legal re-equip reconciliation into spawn and respawn paths.

### Files

- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260328_playerbot_equipment_loadout.sql` (new)
- `src/map/pc.hpp`
- `src/map/pc.cpp`
- `src/map/script.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_item_lab.txt`
- `tools/ci/playerbot-scenario-catalog.sh`
- `doc/project/playerbot-foundation-smoke.md`
- `doc/project/playerbot-scenario-runner.md`
- `doc/project/bot-state-schema.md`

### What Changed

- Added the new persistent table:
  - `bot_equipment_loadout`
- Added runtime reconcile support in `pc.cpp`:
  - spawn-time intended loadout reconcile
  - respawn-time intended loadout reconcile
- Reconcile now emits:
  - `bot_item_audit` rows for equip apply/missing/denied outcomes
  - `bot_recovery_audit` rows with scope `loadout`
  - `bot_trace_event` rows under `phase='reconcile'`
- Added bot-facing loadout buildins:
  - `playerbot_loadoutset(bot_key$, item_id)`
  - `playerbot_loadoutclear(bot_key$[, item_id])`
  - `playerbot_loadoutreconcile(bot_key$)`
- Added shared loadout summary helper:
  - `F_PB_LOADOUT_BuildSummary$`
- Extended `Playerbot Item Lab` so the selftest now proves:
  - intended loadout write
  - spawn-time re-equip after despawn/respawn
  - respawn-time re-equip after death
  - recovery-audit coverage for loadout reconcile
- Promoted `item-loadout-continuity` in the scenario runner from skeleton to
  runbook-backed through:
  - `bash tools/ci/playerbot-item-smoke.sh arm`
  - one `codex` login
  - `bash tools/ci/playerbot-item-smoke.sh check`
- Folded loadout continuity into the aggregate foundation baseline docs and
  acceptance story.

### Validation

- `mysql -u rathena -prathena_secure_2024 rathena < sql-files/upgrades/upgrade_20260328_playerbot_equipment_loadout.sql`
- `cmake --build build --target map-server -j4`
- `bash tools/dev/playerbot-dev.sh restart`
- `bash -n tools/ci/playerbot-item-smoke.sh`
- `bash tools/ci/playerbot-item-smoke.sh arm`
- OpenKore login with the repo-local `codex` profile
- `bash tools/ci/playerbot-item-smoke.sh check`
- `bash tools/ci/playerbot-foundation-smoke.sh run`

Integrated result:

- `playerbot_item_selftest ... loadout_set_ok=1 ... loadout_spawn_ok=1 ... loadout_respawn_ok=1 ... loadout_audit_ok=1 result=1`
- aggregate foundation smoke stays green with:
  - `stage=state`
  - `stage=guild`
  - `stage=item`
  - `stage=merchant`
  - `stage=participation`
  - `stage=combat`
  - `stage=done`
- recent item-audit rows now include:
  - `loadout.spawn.apply`
  - `loadout.respawn.apply`

### Deferrals

This slice does not add:

- loadout planning or build optimization
- automatic gear acquisition
- skill/combat AI that reacts to equipment
- broader mechanic cleanup under combat pressure

## Slice 61: Stabilize Playerbot Foundation Smoke

### Summary

Closed the remaining blockers in the current sequenced foundation pass and
added a deterministic repo-local `run` path so the aggregate smoke no longer
depends on a fragile interactive OpenKore session surviving by luck.

### Files

- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_foundation_lab.txt`
- `npc/custom/playerbot/playerbot_guild_lab.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `src/map/guild.cpp`
- `src/map/script.cpp`
- `tools/ci/playerbot-foundation-smoke.sh`
- `doc/project/playerbot-foundation-smoke.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Hardened the aggregate coordinator:
  - tracks `$PBFNST_ACTIVE`
  - new `run` mode in `tools/ci/playerbot-foundation-smoke.sh`
  - waits for map-server readiness
  - launches the `codex` OpenKore profile in tmux session
    `playerbot-foundation-kore`
  - waits for `stage=done` before the final integrated check
- Fixed the merchant integrated blocker by stopping the merchant selftest from
  forcing a nested control-plane reload inside the aggregate run.
- Fixed the participation integrated blocker by aligning the quest/dialog probe
  with the current reservation contract:
  - stale dialog preclaims are allowed to be reaped
  - drift cleanup now uses authoritative NPC recovery
  - reserved-dialog helpers now recover live NPC state before releasing locks
- Added guild cleanup/repeatability support:
  - new buildin `playerbot_guildexpel(...)`
  - guild member withdrawal now syncs playerbot guild state even for offline
    headless members
  - guild selftest now prunes old temporary `PG150001_*` members before inviting
    a fresh bot
  - guild invite and activity checks now poll long enough to survive sequenced
    integrated load

### Validation

- `cmake --build build --target map-server -j4`
- `bash -n tools/ci/playerbot-foundation-smoke.sh`
- `bash tools/ci/playerbot-foundation-smoke.sh run`

Final integrated result:

- `playerbot_state_selftest ... result=1`
- `playerbot_guild_selftest ... result=1`
- `playerbot_item_selftest ... result=1`
- `playerbot_merchant_selftest ... result=1`
- `playerbot_participation_selftest ... result=1`
- `[playerbot-foundation-smoke] foundation pass ok.`

### Outcome

This closes the current integrated participation/recovery/observability
foundation wave on a deterministic repo-local smoke path.

### Deferrals

This slice still does not cover the next foundation frontier:

- combat participation hooks
- broader status/death/revive continuity
- deeper equipment/loadout continuity
- richer scenario-runner coverage beyond the current aggregate smoke

## Slice 61: Sequenced Foundation Smoke Runner

### Summary

Added a repo-local aggregate foundation smoke path that drives the current
playerbot foundation selftests in sequence instead of arming them all on one
login at once.

### Files

- `npc/custom/playerbot/playerbot_foundation_lab.txt` (new)
- `npc/custom/playerbot/playerbot_state_lab.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `npc/custom/playerbot/playerbot_participation_lab.txt`
- `npc/scripts_custom.conf`
- `tools/ci/playerbot-foundation-smoke.sh` (new)
- `doc/project/playerbot-foundation-smoke.md` (new)

### What Changed

- Added `PlayerbotFoundationSelftest` as the single sequencer for the current
  integrated foundation pass.
- The coordinator now dispatches these subsystem selftests in order:
  - state
  - guild
  - item
  - merchant
  - participation
- Added `Run foundation selftest` to `Playerbot State Lab`.
- Added a canonical repo-local runner:
  - `bash tools/ci/playerbot-foundation-smoke.sh arm`
  - log in once with the `codex` OpenKore profile
  - `bash tools/ci/playerbot-foundation-smoke.sh check`
- The aggregate `check` path now prints:
  - coordinator stage lines
  - subsystem result lines
  - compact recovery-audit summary
  - compact trace summary

### Validation

- `bash -n tools/ci/playerbot-foundation-smoke.sh`
- `bash tools/ci/playerbot-foundation-smoke.sh arm`
- OpenKore login with the repo-local `codex` profile
- `bash tools/ci/playerbot-foundation-smoke.sh check`

Current integrated result on `master`:

- coordinator sequencing now works and reaches:
  - `stage=state`
  - `stage=guild`
  - `stage=item`
  - `stage=merchant`
  - `stage=participation`
  - `stage=done`
- passing subsystem lines:
  - `playerbot_state_selftest ... result=1`
  - `playerbot_guild_selftest ... result=1`
  - `playerbot_item_selftest ... result=1`
- remaining blockers surfaced by the sequenced pass:
  - `PlayerbotMerchantSelftest` still hits `script:run_script_main: infinity loop !`
  - `PlayerbotParticipationSelftest` still fails its dialog-reservation subpath
    under integrated load:
    - `dialog_quest_ok=0`
    - `dialog_drift_ok=0`

### Deferrals

This slice intentionally does not claim a green all-foundation pass yet.

It establishes the canonical integrated runner and leaves two concrete runtime
defects as the next blockers:

- merchant selftest infinity-loop path
- participation dialog-reservation cleanup under integrated load

## Slice 62: Playerbot Scenario Runner Foundation

### Summary

Added a repo-local scenario runner foundation for the combat/status/death
/respawn frontier. The new runner started as tooling-only and now serves as the
canonical runbook layer for the first combat smoke path.

### Files

- `tools/ci/playerbot-scenario.sh` (new)
- `tools/ci/playerbot-scenario-catalog.sh` (new)
- `doc/project/playerbot-scenario-runner.md` (new)
- `doc/project/openkore-smoke-scenarios.md`
- `doc/project/openkore-test-harness.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added a CLI entrypoint with scenario catalog commands:
  - `list`
  - `show <scenario>`
  - `describe <scenario>`
  - `checklist <scenario>`
  - `template [name]`
  - `run <scenario>`
- Added a safe scenario catalog for:
  - `combat-baseline`
  - `status-continuity`
  - `death-respawn`
  - `item-loadout-continuity`
  - `mechanic-cleanup`
- Added a scenario definition flow via `tools/ci/playerbot-scenario-catalog.sh`
  so future scenarios can be extended without changing the CLI contract.
- The first three scenarios now expose the repo-local combat smoke helper as
  the concrete launcher/check surface:
  - `bash tools/ci/playerbot-combat-smoke.sh arm`
  - log in with `codex`
  - `bash tools/ci/playerbot-combat-smoke.sh check`
- Updated docs to point the combat frontier at the scenario runner plus the
  combat smoke helper instead of overloading the generic OpenKore smoke helper.

### Validation

- `bash tools/ci/playerbot-scenario.sh --help`
- `bash tools/ci/playerbot-scenario.sh list`
- `bash tools/ci/playerbot-scenario.sh show combat-baseline`
- `bash tools/ci/playerbot-scenario.sh checklist death-respawn`
- `bash tools/ci/playerbot-scenario.sh describe item-loadout-continuity`
- `bash tools/ci/playerbot-scenario.sh template mechanic-cleanup`
- `bash tools/ci/playerbot-scenario.sh run combat-baseline`

### Deferrals

This slice does not try to automate every scenario. Item/loadout continuity and
broader mechanic cleanup remain skeleton-only until those runtime hooks land.

## Slice 63: Playerbot Combat Participation Baseline

### Summary

Added the first legal combat/status/death/respawn playerbot participation slice
and folded it into the integrated foundation smoke baseline.

### Files

- `src/map/script.cpp`
- `src/map/pc.cpp`
- `src/map/pc.hpp`
- `sql-files/main.sql`
- `sql-files/upgrades/upgrade_20260328_playerbot_combat_trace_events.sql` (new)
- `npc/custom/playerbot/playerbot_combat_lab.txt` (new)
- `npc/custom/playerbot/playerbot_foundation_lab.txt`
- `npc/scripts_custom.conf`
- `tools/ci/playerbot-combat-smoke.sh` (new)
- `tools/ci/playerbot-foundation-smoke.sh`
- `tools/ci/playerbot-scenario.sh`
- `tools/ci/playerbot-scenario-catalog.sh`
- `doc/project/playerbot-combat-frontier-contract.md`
- `doc/project/playerbot-foundation-smoke.md`
- `doc/project/playerbot-scenario-runner.md`
- `doc/project/headless-pc-edge-cases.md`

### What Changed

- Added bot-facing combat buildins:
  - `playerbot_attack`
  - `playerbot_attackstop`
  - `playerbot_target`
  - `playerbot_targetvalid`
  - `playerbot_isdead`
  - `playerbot_isrespawning`
  - `playerbot_statusactive`
  - `playerbot_statusstart`
  - `playerbot_statusclear`
  - `playerbot_combatstate`
  - `playerbot_respawn`
  - `playerbot_kill`
- Extended structured traces with:
  - `phase='combat'`
  - combat/death/respawn actions
- Added combat recovery handling in the runtime:
  - death clears combat target, stale reservations, and invalid participation
    state
  - respawn reconciles combat and participation state before resuming
- Added the visible `Playerbot Combat Lab` and hidden
  `PlayerbotCombatSelftest`.
- Added the repo-local combat smoke helper:
  - `bash tools/ci/playerbot-combat-smoke.sh arm`
  - log in with `codex`
  - `bash tools/ci/playerbot-combat-smoke.sh check`
- Folded combat into the aggregate foundation coordinator and smoke path.
- Updated the scenario runner so:
  - `combat-baseline`
  - `status-continuity`
  - `death-respawn`
  now point at the combat smoke helper as the concrete runbook launcher.

### Validation

- `cmake --build build --target map-server -j4`
- `bash -n tools/ci/playerbot-combat-smoke.sh`
- `bash tools/ci/playerbot-combat-smoke.sh arm`
- OpenKore login with the repo-local `codex` profile
- `bash tools/ci/playerbot-combat-smoke.sh check`
- `bash tools/ci/playerbot-scenario.sh --no-color run combat-baseline`
- `bash tools/ci/playerbot-foundation-smoke.sh run`

Integrated result:

- `playerbot_combat_selftest ... result=1`
- aggregate sequenced stages now reach:
  - `stage=state`
  - `stage=guild`
  - `stage=item`
  - `stage=merchant`
  - `stage=participation`
  - `stage=combat`
  - `stage=done`
- aggregate foundation smoke now passes with combat included

### Deferrals

This slice intentionally does not add:

- skill-cast combat logic
- support/heal combat AI
- loot-routing behavior
- loadout continuity across death/respawn
- deeper mechanic cleanup beyond the current legal combat/death/respawn hooks

## Slice 60: Playerbot Pool Observability CLI Tool

### Summary

Added a repo-local CLI tool for inspecting pool state that accurately reflects
what can be queried from SQL config tables versus what requires live runtime
inspection.

### Files

- `tools/ci/playerbot-pool.sh` (new)
- `doc/project/headless-pc-v1-slice-log.md`

### What Changed

- Added `tools/ci/playerbot-pool.sh` with commands:
  - `status` - Pool inventory with configured thresholds
  - `pools [N]` - List all pools with supply counts  
  - `constrained` - Pools where parked supply < configured threshold
  - `supply` - Parked vs active bot supply breakdown
  - `controller <name>` - Pool bindings for a controller
  - `pool <name>` - Details for a specific pool
  - `stats` - Pool statistics summary

- Precise terminology:
  - "Configured threshold" = `min_demand_users` from `bot_controller_slot`
  - "Parked supply" = bots with `current_state='offline'`, `park_state='parked'`
  - "Active supply" = bots with `current_state != 'offline'`
  - Explicitly NOT labeled as "live demand" (which requires runtime scheduler state)

- Clear limitations documented:
  - Tool reads SQL config, NOT live scheduler runtime state
  - Configured threshold != live requested demand
  - For live truth, use in-game scheduler NPCs or trace inspection

### Validation

- `bash tools/ci/playerbot-pool.sh --help`
- `bash tools/ci/playerbot-pool.sh --no-color status`
- `bash tools/ci/playerbot-pool.sh --no-color pools 5`
- `bash tools/ci/playerbot-pool.sh --no-color constrained`
- `bash tools/ci/playerbot-pool.sh --no-color controller "social.prontera"`
- `bash tools/ci/playerbot-pool.sh --no-color stats`
- All commands exit 0 with clear labeling of what each value represents

### Deferrals

This slice does not add:

- Live scheduler runtime state queries (would need script/runtime surface)
- True "requested demand" visibility (runtime signal dependent)
- Automatic pool rebalancing or controller recommendations
- Pool shortage alerts or monitoring
