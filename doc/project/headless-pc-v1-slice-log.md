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
