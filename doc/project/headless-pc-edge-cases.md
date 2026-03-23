# Headless PC Edge Cases

This document tracks the current weird-case matrix for `headless_pc`.

## Current Model

- headless PCs are runtime-only `BL_PC` actors loaded from existing `char_id`
- lifecycle state and ack tracking are map-server in-memory only
- no restart recovery exists yet
- dev harnesses are:
  - `Headless Smoke`
  - `Headless PC Lab`
- OpenKore is the primary CLI observer

## Known Weird Cases

### 1. Character already online on char-server

Symptom:

- spawn request is rejected

Current handling:

- char-server refuses the load
- map-side pending spawn state is cleared

Future hardening:

- distinguish "real player online" from "stale online state" more explicitly

### 2. Character already online on map-server

Symptom:

- spawn request reaches map-server for a character already present locally

Current handling:

- request is rejected
- pending spawn state is cleared
- char-server online state is pushed back offline for the rejected headless load

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

- no recovery path
- headless runtime actors are treated as ephemeral
- ack/history is lost on restart
- stale online state may require a restart or explicit cleanup

Required future work:

- explicit restart recovery policy
- bot reprovision/relogin layer above `headless_pc`

### 6. Restart during pending remove/save

Symptom:

- remove requested, but final save ACK not observed before restart

Current handling:

- no durable lifecycle ledger
- in-memory pending/ack tracking is lost

Required future work:

- durable handoff/reconciliation if we need restart-safe operation

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

- spawn/remove ack sequences are in-memory only
- they reset on restart

This is acceptable for current dev slices and not acceptable for long-term
controller/provisioning work.

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
- `headless_pc` remains ephemeral until restart recovery is intentionally built
- do not assume absence implies successful save; use ack helpers
