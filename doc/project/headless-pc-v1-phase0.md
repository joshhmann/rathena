# Headless PC V1 Phase 0

## Purpose

Define the first implementation target for a real PC-backed bot subsystem in the
live fork.

This is the design-freeze phase for `headless_pc_v1`. It is not the coding
phase for controller AI, party behavior, or merchant logic. The point is to
lock the minimum viable target and keep the next source pass narrow.

## Product Statement

The immediate target is:

- one inert, server-owned, PC-backed actor
- no real client socket
- visible on-map to real players
- safe to load, keep alive, and remove

This is intentionally smaller than "playerbots".

## Why This Comes Next

The living-world layer now has:

- fakeplayer-backed ambiance
- field traffic proofs
- a first bot-state schema
- pseudo-player architecture docs

That is enough atmosphere groundwork. The next real technical gate is whether
the server can host a true `BL_PC` bot without a live session.

## Non-Goals

Phase 0 does **not** include:

- combat AI
- party invites
- follow/assist behavior
- merchant logic
- autonomous travel
- chat/whisper semantics
- persistence beyond deciding the minimum schema boundary
- external AI integration

If a task does not directly help "spawn one inert headless PC safely", it is
out of scope for this phase.

## Core Decision

The project should target a **PC-backed headless model**, not a mob-backed
approximation, for the long-term playerbot lane.

That means:

- real runtime actor type should be `BL_PC`
- normal player state should stay in the normal rAthena player schema
- bot-specific policy/runtime data should live in separate subsystem records

## Main Blockers

The current research identifies three main blockers:

1. `pc_authok()` depends on `session[sd->fd]`
2. `chrif_authreq()` depends on `session[sd->fd]`
3. `clif_parse_LoadEndAck()` mixes world initialization with client packet work

The practical meaning is:

- the normal human login path cannot be reused unchanged
- the bot bring-up path needs a bot-safe load sequence

## Phase 0 Deliverables

Phase 0 is complete when these are written down and agreed in the repo:

1. runtime model
2. minimum schema boundary
3. first bring-up sequence
4. first source touch points
5. explicit non-goals

## Runtime Model

The first implementation target should be:

- one headless `map_session_data`
- one loaded `mmo_charstatus`
- one bot/headless marker
- one bot-specific bring-up path
- one bot-safe world-only load completion path

The model should avoid pretending a fake session is the final architecture.

Temporary fake-session work is acceptable only if needed for quick proofing, but
the intended direction is explicit headless support.

## Minimum Schema Boundary

Phase 0 should not build the full persistence layer yet.

It only needs enough schema design to answer:

- how do we identify that a character is a bot?
- where will bot subsystem metadata live?

Minimum agreed schema shape:

- normal character data remains in stock player tables
- bot identity/policy uses a dedicated subsystem record keyed by `char_id`
- no bot identity inference from names, groups, or account ranges

Recommended initial record:

- `char_id`
- `enabled`
- `controller_type`
- `spawn_policy`
- `owner_char_id` nullable
- `notes/debug flags`

This can stay as a design artifact in Phase 0 and does not need SQL
implementation yet.

## First Bring-Up Sequence

The agreed Phase 1 implementation target after this design freeze should be:

1. allocate `map_session_data`
2. mark it as headless/bot-owned
3. reuse `pc_setnewpc()` where safe
4. load character status without the normal socket-coupled auth flow
5. run a bot-safe subset of `pc_authok()`
6. request or inject secondary player-state loads
7. run a world-only equivalent of `LoadEndAck`

This is the first sequence the code should be shaped around.

## Phase 0 Outcome

Phase 0 is now implemented and proven at the baseline level.

Confirmed:

- one socketless `BL_PC` can be created from an existing `char_id`
- the actor can complete the load pipeline without a client socket
- the actor can become world-visible to another client
- the actor can be exercised from a dev-only in-game harness and from OpenKore

The key implementation fix beyond the initial bring-up was:

- the temporary headless `map_session_data` had to be inserted into the player ID
  DB early enough for async registry replies to find it

Without that early registration:

- `pc_reg_received()` never fired
- `pc_scdata_received()` never fired
- `pc_loaded` never flipped to true
- `clif_headless_pc_load()` never ran
- the actor existed server-side but never became visible in-world

That specific issue is now resolved.

## First Source Touch Points

The first implementation pass should expect changes around:

- `src/map/pc.cpp`
- `src/map/clif.cpp`
- `src/map/chrif.cpp`
- `src/map/map.cpp`

Likely new module area:

- `src/map/bot/`

Suggested first source responsibilities:

- `bot_service.*`
- `bot_types.*`
- `bot_runtime.*`

Do not start by building planner/controller modules first.

## Required Refactor Boundaries

The following split points should be treated as design requirements:

### 1. Player IP Resolution

`pc_authok()` and `chrif_authreq()` need a bot-safe way to resolve IP or a
bot-specific path that avoids live socket dependency.

### 2. World Load vs Client Load

The current load completion path needs a conceptual split between:

- world-visible actor initialization
- owner-client packet initialization

Headless PCs only need the world side.

### 3. Headless Marker

The runtime actor needs an explicit bot/headless marker. Do not rely on `fd`
sentinels alone as the only distinction.

## Acceptance Criteria

Phase 0 is successful when the project can state all of these clearly:

- the actor model is PC-backed
- the next coding target is one inert headless PC
- the first implementation path does not try to emulate full human login
- the schema boundary is defined
- the first refactor targets are named
- the non-goal list is explicit

## Phase 1 Preview

The next phase after this document should be:

- one inert PC-backed bot on-map
- no client socket required
- visible to nearby players
- clean save/remove path

That is the gate for every later playerbot feature.

## Implementation Log Rule

Each coding slice for `headless_pc_v1` should append to a repo-local running
log instead of leaving the implementation history implicit.

Canonical log:

- `doc/project/headless-pc-v1-slice-log.md`

Each entry should record:

- slice goal
- files touched
- runtime path changes
- validation performed
- explicit deferrals
