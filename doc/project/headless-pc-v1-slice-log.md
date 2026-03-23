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
