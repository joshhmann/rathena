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

### 15. Combat frontier scenario coverage

Current handling:

- scenario coverage for combat/status/death/respawn is now expressed as a
  repo-local runner in:
  - [playerbot-scenario-runner.md](/root/dev/rathena/doc/project/playerbot-scenario-runner.md)
  - `tools/ci/playerbot-scenario.sh`
  - `tools/ci/playerbot-combat-smoke.sh`

Preferred upcoming handling:

- expand the skeleton catalog into real runtime-backed scenarios as combat and
  status hooks land
- keep the current combat smoke helper aligned with the scenario runner entries
- keep the runner CLI stable while the scenario definitions grow
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

### 30. Provisioning DB coupling

Current support:

- the direct provisioning path has now been checked against the active dev
  config
- in this environment:
  - `login_server_db = rathena`
  - `char_server_db = rathena`
  - `map_server_db = rathena`
- direct map-side inserts into the login/account table are therefore valid for
  the current stack

Current limits:

- this is a tested environment fact, not a portable architecture guarantee
- if login/char/map DBs diverge later, provisioning should move behind a
  char/login-service boundary instead of direct SQL writes

### 31. Role/profile-backed pooled assignment

Current support:

- SQL-backed pools now carry:
  - `bot_id`
  - `profile_key`
  - `role`
- pooled controller slots can request a desired profile/role pair
- the allocator only claims identities that match that request

Current limits:

- controller slot definitions are still script-owned
- richer demand selection by profile/role is still controller-local, not a
  global scheduler policy

### 32. Post-join party assist

Current support:

- a continuous post-join assist controller now exists through the playerbot
  harness:
  - resolve party leader continuously
  - choose a passable adjacent anchor
  - walk toward that anchor on the same map
  - reposition across map handoff when needed
- validation uses:
  - `Playerbot Party Assist`
  - `PlayerbotSelftest`

Current limits:

- this is still a narrow follow/assist lane, not a full support AI
- no combat assist semantics exist yet
- no richer role selection or party-controller reassignment exists yet

### 33. Playerbot config key length

Current support:

- the playerbot config registry now uses compact live keys for the active
  scheduler/controller surfaces
- the pulse-profile config layer already used shortened suffix keys for the
  playerbot pulse profiles

Current limits:

- provisioning template keys under `tp.*` are still separate from the compact
  scheduler/controller key family
- future config growth should still keep variable-name limits in mind when
  adding new dynamic key families

### 34. Merchant-capable recurring bots

Current support:

- merchant-capable bots now have a persistent merchant row:
  - `bot_merchant_state`
- merchant templates can provision:
  - policy
  - shop name
  - market anchor
  - opening window
  - stock/price profile labels
  - stall style
  - open/closed state
- a dev harness exists:
  - `Playerbot Merchant Lab`

Current limits:

- this is merchant state only, not live vending behavior
- no stock depletion or restock logic exists yet
- no scheduler-driven opening/closing automation exists yet

### 35. SQL-backed controller registry

Current support:

- active playerbot controller policy and slot definitions now have persistent
  SQL homes:
  - `bot_controller_policy`
  - `bot_controller_slot`
- the currently active controller set is seeded through SQL:
  - `social.prontera`
  - `social.alberta`
  - `merchant.alberta`
- reusable talk/emote/anchor content remains script-defined, but controller slot
  rows now reference those content keys instead of embedding full controller
  definitions in `headless_pc_config.txt`

Current limits:

- only the active social and Alberta merchant demo controllers are migrated
- route-set use is still deferred
- a fresh bootstrap or upgrade now seeds the controller rows, but broader
  controller authoring is still a checked-in SQL workflow, not an operator UI

### 37. Merchant runtime normalization and reload

Current support:

- the merchant bootstrap lane now depends on source-backed script buildins for
  cart seeding:
  - `cartgetitem`
  - `clearcart`
- SQL-backed playerbot controllers can now be re-primed through a shared
  control-plane reload path
- the world scheduler can rebuild its active controller list after reload
- merchant runtime state is reconciled on startup so disabled or off-hours
  merchants are parked instead of surviving restart as stale active actors

Current limits:

- control-plane reload is currently exposed through dev/operator surfaces, not a
  user-facing workflow
- merchant normalization currently reasons from merchant policy and hour window,
  not live vending session state
- merchant reload/menu behavior still deserves one explicit end-to-end operator
  smoke pass beyond the startup/runtime checks

### 38. SQL-driven scheduler operator surface

Current support:

- scheduler drill-down now builds from `bot_controller_policy` instead of a
  hardcoded controller menu
- controller enable/disable can now be toggled through the SQL-backed registry
  and followed immediately by a control-plane reload
- a hidden scheduler selftest exists for registry-driven disable/re-enable of
  `merchant.alberta`, but it is disabled by default so startup stays clean

Current limits:

- the operator surface is still a dev harness, not a generalized admin console
- controller row authoring still happens through checked-in SQL, not runtime UI
- content sets like talks/emotes/anchors remain script-backed even though
  controller policy and slot membership are SQL-backed

### 39. SQL-backed controller content sets

Current support:

- active controller anchor sets, talk lines, and emotes now live in SQL:
  - `bot_controller_anchor_point`
  - `bot_controller_talk_line`
  - `bot_controller_emote_value`
- active controller load now resolves content sets from SQL instead of the old
  `headless_pc_controller_content.txt` script registry
- the Alberta/Prontera social controllers and Alberta merchant controller all
  survive startup with the script content file removed from the load path

Current limits:

- route-set data is still not migrated into SQL
- content authoring is still a checked-in SQL workflow, not an operator tool
- only the active controller set is migrated; older demo content paths remain
  historical script debt until explicitly moved

### 40. SQL-backed route sets

Current support:

- active controller definitions can now point at SQL-backed route sets through:
  - `bot_controller_route_point`
- controller load now materializes route points from SQL
- `patrol.prontera` exists as the first DB-backed patrol proof using:
  - `HeadlessPronteraPatrolController`
  - `patrol.prontera.loop`

Current limits:

- route authoring is still a checked-in SQL workflow
- the patrol proof is a dev/operator controller, not part of the default world
  scheduler set
- older demo-only patrol controllers still exist as historical script examples

### 41. Merchant runtime shop proxy

Current support:

- merchant-capable recurring bots can now expose a real NPC shop surface while
  active
- the Alberta merchant lane now uses SQL-backed stock rows through:
  - `bot_merchant_stock_item`
- the controller can materialize stock into a live shop NPC and show/hide a
  clickable proxy with the merchant's configured shop name
- the merchant selftest now validates:
  - spawn
  - merchant bootstrap
  - shop materialization
  - park
  - control-plane reload

Current limits:

- this is still the approved "merchant actor plus NPC shop interface" pattern,
  not true vending-player emulation
- stock authoring is SQL-backed but still checked in, not operator-authored
- price behavior is still simple per-item pricing, not a richer market model
- only the first Alberta merchant proof is wired; more merchant controllers
  still need migration onto the same runtime pattern

### 42. Scheduler stop/start thrash

Current support:

- the world scheduler now has SQL-backed stickiness and cooldown policy through:
  - `bot_controller_policy.min_active_ms`
  - `bot_controller_policy.restart_cooldown_ms`
- active controllers can remain selected while still inside their minimum
  runtime window
- recently stopped controllers can be blocked from immediate restart until
  their cooldown expires
- scheduler status now surfaces the policy plus live uptime / time-since-stop
  information

Current limits:

- the sticky/cooldown timers are in-memory runtime policy, not persisted
  scheduler history
- scheduler selection is still priority-first, not a richer weighted rotation
- controller cooldowns do not yet account for external operator intent beyond
  the current enabled/disabled policy rows

### 43. Equal-priority scheduler fairness

Current support:

- for equal-priority controllers that are otherwise eligible, the scheduler now
  prefers the least-recently-selected controller instead of always taking the
  first one in registry order
- scheduler status surfaces how long ago a controller was last picked
- sticky minimum-runtime and restart-cooldown policy still win before fairness
  is considered

Current limits:

- fairness history is still in-memory only
- selection is least-recently-picked, not weighted or randomized
- fairness currently operates at controller granularity, not per-slot or
  per-bot identity granularity

### 44. Restart-blind scheduler fairness and simple gate thresholds

Current support:

- scheduler history is now persisted in SQL through:
  - `bot_controller_runtime`
- controller policy now exposes:
  - `fair_weight`
  - `demand_users_step`
  - `demand_priority_step`
  - `demand_priority_cap`
- on scheduler prime, persisted last-start / last-stop / last-picked state is
  loaded back into the runtime scheduler view
- equal-effective-priority choices now use weighted rotation instead of fixed
  registry order
- controllers can gain a bounded demand bonus from surplus map users beyond
  their gate threshold
- scheduler status now surfaces:
  - base + demand = effective priority
  - fairness weight
  - demand scaling policy
  - persisted last-picked timing when available

Current limits:

- demand is still based only on map-user pressure plus routine windows
- persisted runtime history is scheduler-level, not per-bot or per-slot
- operator controls are still centered on the scheduler demo/status surface, not
  a richer dedicated admin UI

### 45. Single-map gating and script-only pulse defaults

Current support:

- controller demand sources are now SQL-backed through:
  - `bot_controller_demand_map`
- controllers can evaluate weighted demand from more than one map
- scheduler selection and controller run-gating now use the same SQL-backed
  weighted demand model
- active pulse profiles are now SQL-backed through:
  - `bot_pulse_profile`
- controller slot definitions still point at pulse-profile keys, but the live
  timing/chatter defaults are no longer owned only by script config
- controller and scheduler status now surface the weighted demand composition

Current limits:

- demand still measures map-user pressure only; it does not yet include guild,
  party, trade, or economic activity signals
- demand-map sets are checked-in SQL seed data, not yet a richer operator
  editing surface
- pulse profiles are global keyed profiles, not yet per-bot or per-role
  overrides

### 46. Guild-capable identities without guild semantics

Current support:

- recurring bots now have persistent guild-facing metadata through:
  - `bot_guild_state`
- provisioning templates can now define:
  - guild policy
  - guild name
  - guild position
  - guild invite policy
  - guild member state
- the inspect/provision harnesses now surface that metadata alongside the
  existing party and merchant summaries
- failed provisioning cleanup now removes guild metadata with the rest of the
  bot identity state

Current limits:

- guild-capable bots are not yet synchronized into live `guild` /
  `guild_member` membership
- invite policy is metadata only; it does not yet drive runtime guild invite
  responses
- scheduler demand still does not account for guild activity, guild events, or
  guild roster pressure

### 47. Map-user-only demand without participation signals

Current support:

- controller demand now has a second SQL-backed input lane through:
  - `bot_controller_demand_signal`
- supported signal families are:
  - `merchant_open_map`
  - `merchant_live_map`
  - `guild_enabled_name`
  - `guild_candidate_map`
- scheduler and controller run-gating now combine:
  - weighted map-user demand
  - weighted participation-signal units
- demand summaries now expose both map demand and signal demand in the same
  controller status path

Current limits:

- signal units are still coarse counts, not richer economic metrics like sales,
  purchases, or zeny flow
- guild signals still read bot metadata, not real live guild membership or guild
  event load
- operator editing is still SQL-driven; there is not yet a richer admin UI for
  controller signal policy

### 48. Guild-capable bots without live invite handling

Current support:

- active headless/playerbot targets can now pass through the normal guild invite
  runtime with a narrow headless-bot policy hook
- the first guild invite policy reads from:
  - `bot_guild_state.enabled`
  - `bot_guild_state.invite_policy`
- script surfaces now expose:
  - `playerbot_guildinvite(char_id)`
  - `playerbot_guildid(char_id)`
- `Playerbot Guild Lab` now has spawn/invite/inspect controls for guild-capable
  bots

Current limits:

- the current dev DB still has no live guild rows, so the full accept/join lane
  is not yet proven end-to-end
- guild policy currently stops at invite accept/decline; it does not yet add
  guild routines, chat, storage, or event behavior
- guild creation/seeding for automated selftests is still missing

### 49. Guild creation was missing from the dev proof path

Current support:

- script runtime now has a dev-only `playerbot_guildcreate(name$)` helper
- it mirrors the `@guild` path and temporarily bypasses the Emperium
  requirement for the attached player
- the guild lab and provisioner now include a first open-invite guild template
  lane
- live validation now proves guild creation against the running server:
  - `Guild create successful.`
  - guild row `PBG150001` owned by `codex`

Current limits:

- full bot invite/join proof is still not claimed as a clean repeatable CLI
  selftest yet
- the current guild lab selftest path exists, but its trigger/automation still
  needs tightening before it becomes a trusted smoke path

### 50. Economy demand only tracked merchant presence, not stock depth

Current support:

- controller demand now supports a richer SQL-backed signal:
  - `merchant_stock_map`
- Alberta social/merchant demand can now react to:
  - open merchant presence
  - live merchanting presence
  - configured stock depth

Current limits:

- stock depth is still a coarse proxy based on configured merchant stock rows,
  not real purchases, sell-through, or zeny flow
- economy-aware demand is still controller-level, not per-bot or per-market
  segment

### 51. Merchant demand needed real activity, not only configured stock

Current support:

- merchant runtime now persists real activity in `bot_merchant_runtime`
- controller demand can now read:
  - `merchant_browse_map`
  - `merchant_sale_map`
- the Alberta merchant proxy records:
  - browse activity when the shop is opened
  - sale activity from `OnBuyItem`
- the manual merchant selftest now proves:
  - bootstrap
  - proxy/shop materialization
  - activity row updates
  - control-plane reload

Current limits:

- merchant activity currently measures shop interaction volume, not zeny flow,
  stock depletion, or broader market pressure
- the activity proof path is manual-on-demand, not a startup autorun

### 52. Guild selftests are still sensitive to stale dev-server ownership lanes

Current support:

- the guild lab now has a real manual selftest trigger that fires from a live
  attached player
- guild-capable playerbot metadata now syncs guild state on active join paths

Current limits:

- the current local restart path can leave char-server seeing duplicate
  map-server ownership lanes (`server 0` and `server 1`)
- when that happens, reused headless guild-bot identities can be rejected as
  already online on the wrong server, and the manual guild selftest reports
  `spawn-timeout`
- this is a dev-environment/runtime ownership issue, not evidence that the
  guild invite hook itself is absent

Update:

- the root cause was pinned down to orphan local repo server processes and a
  stray tmux debug session (`pb-map-debug`)
- `/root/setup_dev.sh restart` now cleans those orphan server processes and
  tmux lanes before bringing the normal dev stack back up
- after that cleanup, char-server returns to a single owner lane:
  - `Map-Server 0 connected`

Current remaining limit:

- the guild invite proof now has a repeatable armed-on-login smoke path through:
  - `tools/ci/playerbot-guild-smoke.sh`
- the guild runtime accept/join lane is now proven end-to-end on the clean
  restart baseline

Current remaining limits:

- the guild smoke path still expects a real `codex` login after arming; it is
  not yet a one-command launcher
- guild behavior still stops at invite/join participation, not guild chat,
  storage, territory, or event semantics

### 53. Guild demand can now read real roster state, but not richer guild activity

Current support:

- scheduler demand now supports real guild-backed signal families:
  - `guild_roster_name`
  - `guild_live_name`
- these read actual linked recurring bot membership from:
  - `guild`
  - `guild_member`
  - `bot_identity_link`
  - `bot_profile`
- Prontera scheduler policy can now react to:
  - guild-capable candidates on the map
  - real linked guild roster membership
  - real linked guild members currently online

Current limits:

- `guild_live_name` is still a coarse online-presence signal based on
  `char.online`, not richer guild activity like chat, storage use, or events
- the current guild smoke path cleans up quickly, so long-lived live-guild
  pressure is not yet sampled as a steady-state scenario

### 54. Guild demand now sees storage depth/activity, but not full guild-system behavior

Current support:

- scheduler demand now supports:
  - `guild_storage_name`
  - `guild_storage_log_name`
- these read real guild-system tables:
  - `guild_storage`
  - `guild_storage_log`
- the dev smoke helper:
  - `tools/ci/playerbot-guild-storage-smoke.sh`
  can seed and clear sentinel probe rows safely for validation

Current limits:

- the current proof is SQL-backed storage participation, not a full playerbot
  guild-storage interaction loop through the normal UI/runtime
- guild demand still does not account for chat, castle ownership, or event
  activity

### 55. Guild demand can now see castle ownership, but not castle activity

Current support:

- scheduler demand now supports:
  - `guild_castle_name`
- this reads real `guild_castle` ownership rows for a guild
- the dev smoke helper:
  - `tools/ci/playerbot-guild-castle-smoke.sh`
  can safely seed and clear a sentinel castle row even when the dev DB starts
  with no castle rows

Current limits:

- the current proof is ownership only, not WoE/event participation, defense
  pressure, tax, or castle economy behavior
- guild demand still does not account for chat/activity rhythm inside those
  owned castle systems

### 36. Fresh-restart ambient stability

Current support:

- the SQL-backed playerbot controller slice now uses guarded timer-driven
  scheduler/controller ticks, so start and top-up no longer create duplicate
  long-lived `OnTick` loops
- the merchant selftest is opt-in again and no longer mutates state on ordinary
  test-account login
- fresh `map-server` restarts now stay online in the local tmux workflow
- ambient fakeplayer refresh now repositions existing actors through
  passable-cell normalization plus direct warp instead of forced walk reuse

Current limits:

- a few ambient definitions still resolve to no valid nearby passable cell, so
  refresh can emit isolated `unit_warp` warnings for those actors until the
  source coordinates are cleaned up
- OpenKore merchant-controller smoke is still pending even though restart and
  startup validation are now green
## Scheduler Demand Visibility

- Scheduler demand can now include weighted map users plus weighted system signals like merchant and guild activity.
- A single inline total was too opaque once multiple signal families existed.
- Status output now prints per-source breakdown lines so operator review can answer:
  - which maps are contributing demand
  - which guild/economy signals are contributing demand
  - how much weighted pressure each source is adding
- This is an observability slice only; it does not change scheduler selection math.

## Guild Leadership Signals

- Guild demand is no longer only about total roster or storage depth.
- Scheduler policy can now distinguish:
  - a guild merely existing
  - the guild leader identity existing
  - the guild leader actually being online
- This is still a demand-layer slice only; it does not yet add leader-follow, guild-chat, or guild-event behavior.

## Guild Notice Signals

- Scheduler demand can now react to whether a guild currently has notice text posted.
- This is useful as a small social/activity signal without needing full guild-chat behavior yet.
- The repo-local smoke helper can seed and clear notice text safely for the current dev guild.

## Guild Activity Runtime

- Static guild state was not enough once scheduler demand needed “recent activity” rather than only current presence.
- A small `bot_guild_runtime` ledger now tracks:
  - recent member joins
  - recent notice changes
- Those timestamps are written from real runtime hooks, not from raw scheduler SQL.

## Guild Runtime Visibility

- Guild activity state is now visible from the in-game guild lab, not only from SQL or tmux logs.
- This reduces the need for manual DB inspection when validating guild participation slices.

## Guild Watch Behavior

- The first guild-driven controller layer now exists in Prontera.
- It still draws from the broader Prontera social pool for now.
- That is intentional at this stage:
  - controller behavior is being proven first
  - stricter guild-only pool ownership can come later once more recurring guild bots are provisioned

## Trade Flow Behavior

- The first economy-flow controller now exists in Alberta.
- It is demand-driven and SQL-backed, but still uses social identities rather than a dedicated merchant-only courier pool.
- That is acceptable for this phase because the goal is proving the behavior lane, not final world curation.

## Guild Quarter Behavior

- Prontera now has a second guild-driven behavior lane beyond the first watch controller.
- This helps separate:
  - guild watch / reaction presence
  - guild-quarter / neighborhood presence
- It still uses the wider Prontera social pool for now.
- That is acceptable in this phase because the scheduler/control plane is still being hardened before stricter guild-only curation.

## Market Spill Behavior

- Alberta now has a second economy-driven controller lane beyond the first trade-flow controller.
- This helps separate:
  - direct trade-flow movement near stalls
  - market spillover presence around the harbor-market seam
- It still uses the wider Alberta social pool for now.
- That is acceptable in this phase because the current goal is deeper scheduler/controller behavior, not final merchant-only identity assignment.

## Guild And Trade Roster Specialization

- The newer behavior controllers no longer need to keep borrowing from the broadest available pools.
- Current specialization:
  - `guild.watch.prontera` -> `pool.guild.prontera`
  - `guild.square.prontera` -> `pool.guild.prontera`
  - `market.flow.alberta` -> `pool.trade.alberta`
- Alberta ambient social presence was narrowed so it no longer competes as heavily with direct trade-flow behavior.
- `market.spill.alberta` remains a lighter spillover lane on the social side by design.

Why:

- cleaner role ownership
- less controller contention
- better long-term path toward stricter guild/economy curation

Current limits:

- `pool.trade.alberta` is still built from repurposed recurring Alberta identities, not a fully separate long-term merchant-courier roster
- `market.spill.alberta` still uses ambient/social identity rather than a dedicated economy-only pool

## Demand-Scaled Controller Slots

- Controllers no longer need to treat every slot as equally active at all times.
- Each slot can now define `min_demand_users`.
- That means a controller can keep:
  - a base anchor actor
  - plus extra runners/couriers only when weighted demand rises

Current support:

- slot demand thresholds are SQL-backed in `bot_controller_slot`
- controller tick logic releases or withholds pooled actors when slot demand is
  not satisfied
- status surfaces now show slot-level minimum demand when set

Current limits:

- scheduler actor budgeting is still controller-level rather than fully
  threshold-aware per slot
- this still improves real runtime behavior because the controller itself no
  longer forces every slot online when demand is weak

## Scheduler Budgeting For Demanded Slots

- The scheduler no longer has to treat every controller as if its full slot list
  is currently required.
- Controller defs are now primed before scheduling so slot-demand thresholds are
  visible earlier.
- Scheduler selection/status can now reason in:
  - desired actors now
  - maximum configured actors

Current support:

- status uses `desired/max` actor reporting
- a controller with zero currently demanded slots can now be skipped explicitly

Current limits:

- controller policy still carries a coarse max actor weight
- deeper per-slot persistence/history is still not modeled separately from the
  controller runtime record

## Activity Ledgers Vs Latest-State Tables

- Merchant and guild demand now uses two different runtime surfaces on purpose:
  - latest-state runtime tables
  - recent activity ledgers
- latest-state runtime tables are still:
  - `bot_guild_runtime`
  - `bot_merchant_runtime`
- recent activity ledgers are now:
  - `bot_guild_activity_log`
  - `bot_merchant_activity_log`

Why this split exists:

- latest-state tables answer:
  - did anything happen recently?
  - when was the last join / notice / browse / sale?
- activity ledgers answer:
  - how much happened recently?
  - how many joins, notice changes, browse events, or sold units occurred in the
    recent window?

Current support:

- scheduler demand can now react to recent event volume through:
  - `guild_join_events_name`
  - `guild_notice_events_name`
  - `merchant_browse_events_map`
  - `merchant_sale_units_map`
- in-game operator surfaces now expose those recent counts through:
  - `Playerbot Guild Lab`
  - `Playerbot Merchant Lab`

Current limits:

- activity ledgers are append-only and currently use a fixed recent window in the
  signal queries
- there is no pruning/rollup policy yet for older activity rows

## Runtime-Reactive Controller Moods

- Guild and economy controllers no longer use runtime signals only for scheduler
  activation.
- Active controllers can now also react to pressure by changing:
  - controller tick tempo
  - social pulse cadence
  - talk-vs-emote bias

Current support:

- guild-driven posture is applied to:
  - `HeadlessPronteraGuildWatchController`
  - `HeadlessPronteraGuildQuarterController`
  - `HeadlessPronteraSocialController`
- market-driven posture is applied to:
  - `HeadlessAlbertaMerchantController`
  - `HeadlessAlbertaSocialController`
  - `HeadlessAlbertaTradeFlowController`
  - `HeadlessAlbertaMarketSpillController`
- visible status menus now surface a `Behavior:` line so operator views show the
  live interpreted mood, not only raw demand numbers

Current limits:

- runtime-reactive posture is still controller-local and heuristic-driven
- it does not yet change deeper decision trees like:
  - destination selection
  - role reassignment
  - guild/event-specific actions
- this is still a foundation layer for later richer behavior scripting

## Runtime-Reactive Route And Anchor Selection

- Specialized guild and market controllers can now push the reactive layer past
  posture-only changes.
- Active controllers can swap:
  - loiter anchor sets
  - patrol route geometry
  - hold-vs-loiter mode for selected slots
- The active movement state is invalidated when geometry changes so the owned
  actor can stop the stale route and repick from the new definition on the next
  controller tick.

Current support:

- guild watch pressure can widen or tighten the runner's watch loop
- guild quarter pressure can widen or tighten the courier's quarter loop
- Alberta trade pressure can widen or shorten the runner patrol circuit
- Alberta market spill pressure can switch the barker between hold and loiter
  anchor sets

Current limits:

- route and anchor geometry is still script-defined for this phase
- switching is controller-local and heuristic-driven
- there is still no global path scoring, crowd scoring, or learned destination
  selection

## Runtime-Reactive Social And Merchant Geometry

- The reactive route/anchor layer now also reaches the base social and merchant
  controllers, not only the specialized guild-watch and trade-flow lanes.

Current support:

- Prontera social wanderers can widen or tighten their commons loops as guild
  pressure rises
- Alberta harbor social traffic can widen or tighten its loiter pocket as
  market pressure rises
- Alberta merchants can shift the live stall body within a small market
  footprint as pressure rises

Current limits:

- merchant runtime still uses a proxy shop NPC instead of full vending-player
  emulation
- social and merchant geometry changes are still local heuristics, not global
  crowd balancing

## Runtime-Reactive Guild And Market Flavor Sets

- Active guild and market controllers can now replace their talk/emote sets when
  runtime pressure changes.

Current support:

- guild watch and guild quarter controllers swap lines/emotes with calmer or
  busier guild pressure
- Alberta trade, spill, and merchant controllers swap lines/emotes with calmer
  or hotter market pressure

Current limits:

- flavor changes are still controller-local and hand-authored
- there is still no global dialogue planner, social memory, or learned
  interaction model

## Runtime-Reactive Role Emphasis

- Active controllers can now adjust slot demand thresholds at runtime.
- Pressure changes can now influence which secondary roles are worth filling,
  not just how active slots move or pulse.

Current support:

- guild watch and guild quarter can promote or suppress runner/courier roles
- Prontera social can promote or suppress extra wanderers
- Alberta social can promote or suppress the harbor wanderer
- Alberta trade and spill can promote or suppress the runner or barker lane
- Alberta merchant can make the stall body easier or harder to demand depending
  on live market pressure

Current limits:

- dynamic role emphasis still uses script-side min-demand overrides
- there is still no runtime role reassignment across controllers or pools

## Signal-Directed Guild And Trade Focus

- Some controllers now react to specific runtime signal families, not only the
  aggregate pressure score.

Current support:

- guild quarter can bias toward notice-running versus warehouse-running based on
  notice activity versus storage activity
- Alberta trade flow can bias toward front-market circulation versus supply-run
  circulation based on browse-heavy versus sale-heavy activity

Current limits:

- signal-directed focus is still controller-local and hand-authored
- there is still no generic planner that arbitrates among multiple competing
  goals across controllers

## Shared Signal-Directed Social And Merchant Focus

- The signal-directed focus pattern now extends into the remaining active social
  and merchant controllers.

Current support:

- Prontera social can bias toward notice buzz, recruit bustle, or roster
  commons
- Alberta social can bias toward buyer drift, browse pocket, or harbor drift
- Alberta merchant can bias toward sales heat, browse draw, or stock hold

Current limits:

- focus selection is shared, but the concrete routes, anchors, and lines remain
  controller-local
- there is still no single planner that coordinates focus changes across the
  whole map

## Lightweight Cross-Controller Focus Coordination

- Related controllers on the same map can now avoid duplicating the same focus
  if a reasonable alternate exists.

Current support:

- Prontera social can avoid mirroring the guild-quarter focus exactly
- Alberta social, trade, and merchant controllers can avoid collapsing onto the
  same market focus when alternatives are available

Current limits:

- coordination is soft and heuristic-driven
- there is still no hard global planner, reservation model, or map-wide posture
  solver

## Shared Guild/Trade Focus Helpers

- Guild and Alberta trade-focused controllers now derive their focus through
  shared helper functions instead of duplicating local signal reads.

Current support:

- guild watch publishes a shared focus state
- guild quarter focus is shared and coordination-aware
- Alberta trade flow uses a shared focus helper
- Alberta market spill now publishes a shared focus state

Current limits:

- focus derivation is shared, but geometry/flavor application still remains
  controller-local

## Cross-Controller Posture Separation

- Some sibling controllers now use shared focus-state to pick a visibly
  different posture when another controller already owns the obvious lane.

Current support:

- Prontera guild watch can yield from notice-watch into roster-watch
- Alberta market spill can yield from front-fringe into browse or harbor fringe

Current limits:

- posture separation is still local and heuristic
- there is still no map-wide solver that guarantees optimal or non-overlapping
  posture choices

## Shared Intensity Lanes

- Same-map sibling controllers can now spread out escalation posture using
  shared `hot`, `warm`, and `cool` lanes.

Current support:

- Prontera guild/social controllers now coordinate escalation lanes
- Alberta social/trade/merchant controllers now coordinate escalation lanes
- demanded-slot thresholds can react to the chosen lane

Current limits:

- lane choice is still heuristic rather than globally optimized
- coordination still depends on sibling controller runtime state rather than a
  central planner

## Structured Trace Events V1

- Playerbot observability now has a first append-only structured trace table:
  `bot_trace_event`.

Current support:

- merchant runtime reconcile emits:
  - `reconcile.started`
  - `reconcile.fixed`
  - `reconcile.failed`
- merchant activity emits:
  - `interaction.completed`
- a visible `Playerbot Trace Lab` NPC can show recent rows by:
  - all
  - failure-only
  - controller
  - bot key
  - map

Current limits:

- the current trace slice is still script-first rather than full engine-wide
- live scheduler/controller/move trace points exist in the shared helper layer,
  but current smoke coverage is still strongest on reconcile and merchant
  interaction paths
- there is not yet a replay tool, timeline compactor, or external trace viewer

## Shared Perception Facade V1

- Playerbot controllers and operator tools now have a first shared read-only
  world-query facade.

Current support:

- self state
- nearby players
- nearby bots
- nearby NPCs
- nearby shops
- local heat
- recent social contacts from trace history
- party context
- guild context
- route viability
- interaction target state
- anchor-set inspection
- each query now returns:
  - value
  - observed time
  - stale milliseconds
  - confidence

Current limits:

- perception is still script-first and not yet backed by a central cache or
  observer pipeline
- anchor occupancy and reservation are still deferred until reservation
  primitives land
- controllers are not yet migrated systematically to the shared facade; this
  slice establishes the interface and operator surface first

## Reservation Primitives V1

- Playerbot contention now has a first SQL-backed reservation ledger:
  `bot_reservation`.

Current support:

- reservation types:
  - `anchor`
  - `dialog_target`
  - `social_target`
  - `merchant_spot`
  - `party_role`
- lock modes:
  - `lease`
  - `hard_lock`
- shared helper surfaces now exist for:
  - acquire
  - release
  - release-by-holder
  - cleanup / reap
  - resource summary
  - holder summary
- reservation events now emit into the trace ledger:
  - `reservation.acquired`
  - `reservation.denied`
  - `reservation.released`
- a visible `Playerbot Reservation Lab` NPC can exercise contention and inspect
  active rows

Current limits:

- reservations are not yet wired into live controller movement / interaction
  ownership automatically
- anchor occupancy is still summary-level, not a fully synchronized live crowd
  model
- stale-holder cleanup currently treats expiry and missing bot identities as
  authoritative cleanup cases; controller-ownership-driven cleanup is still a
  later integration slice

## Shared Memory And State Inspector V1

- Playerbot state boundaries now have a first live shared-memory ledger:
  `bot_shared_memory`.

Current support:

- shared world/social memory rows with:
  - scope
  - key
  - integer value
  - text value
  - source tag
  - expiry
- shared helper surfaces now exist for:
  - remember / upsert
  - expiry reap
  - summary building
  - recovery-authority summaries
  - bot four-layer state summaries
  - per-bot recovery audits
- active guild and merchant focus helpers now publish medium-lived shared memory
  so operators can inspect current derived posture state
- a visible `Playerbot State Lab` NPC now shows:
  - quick merchant state
  - quick party state
  - bot-key inspection
  - shared-memory inspection
  - recovery-authority summaries
  - a probe marker write path

Current limits:

- shared memory is still a medium-lived ledger, not a full replay/history
  surface
- controller-local transient scratch state remains script-local in this slice
- the current stable validation path is the lab probe marker plus controller
  focus publication, not a full migration of every runtime variable
- recovery summaries are now partly live: the state lab compares world state,
  runtime ledger state, reservation counts, and merchant-open policy for a bot
  key before suggesting the recovery rule

## Transactional Item Layer V1

- Playerbot inventory/equipment/storage mutations now have a first explicit
  audit ledger: `bot_item_audit`.

Current support:

- live bot-safe script verbs now exist for:
  - `playerbot_itemgrant`
  - `playerbot_itemremove`
  - `playerbot_itemequip`
  - `playerbot_itemunequip`
  - `playerbot_storagedeposit`
  - `playerbot_storagewithdraw`
- authoritative item counting now distinguishes:
  - online headless-bot inventory/equipment state
  - offline persisted SQL state
- a visible `Playerbot Item Lab` NPC now exposes:
  - quick bot ready/spawn
  - grant/equip/unequip/deposit/withdraw verbs
  - item summary
  - item audit summary
- a hidden `PlayerbotItemSelftest` plus repo-local
  `tools/ci/playerbot-item-smoke.sh` path now validate:
  - grant
  - remove
  - equip
  - unequip
  - storage deposit
  - storage withdraw
  - post-test parking

Current limits:

- the item layer currently relies on the normal rAthena `inventory` and
  `storage` tables rather than a dedicated persistent bot inventory model
- trade, NPC shop buying, item use/consume, and broader storage/trade recovery
  semantics are still later participation slices
- item mutations are audited but not yet mirrored into the broader structured
  trace/event timeline

## Participation Hooks V1

- Playerbots now have the first direct participation hooks for:
  - NPC/dialog start/next/menu/close
  - storage open/close ownership
  - trade request/cancel state

Current support:

- live bot-safe script verbs now exist for:
  - `playerbot_npcstart`
  - `playerbot_npcnext`
  - `playerbot_npcmenu`
  - `playerbot_npcclose`
  - `playerbot_npcactive`
  - `playerbot_storageopen`
  - `playerbot_storageclose`
  - `playerbot_storageisopen`
  - `playerbot_traderequest`
  - `playerbot_tradecancel`
  - `playerbot_tradepartner`
  - `playerbot_tradeactive`
- a visible `Playerbot Participation Lab` plus hidden
  `PlayerbotParticipationSelftest` now validate:
  - full deterministic dialog flow
  - storage open/close
  - storage session reset after despawn/respawn
  - trade request/cancel integrity
  - interaction trace emission
- interaction traces now cover the first participation actions in
  `bot_trace_event` with `phase = interaction`

Current limits:

- the current dialog path now covers:
  - numeric input
  - string input
  - nested menu branching
  - deterministic item hand-in
  but still does not cover richer quest-state mutation or broad NPC-specific
  scripted side effects
- storage support now covers:
  - open/close ownership
  - manual recovery
  - despawn/respawn session reset
  - deposit persistence across forced recovery
  but still does not cover broader rollback semantics for interrupted
  multi-step storage mutations
- trade support now covers:
  - request/accept
  - staged item negotiation
  - staged zeny negotiation on the player side
  - lock/commit completion
  - cancel rollback after staged negotiation
  - explicit forced recovery of stale bot/player trade state
  but still does not cover broader dual-sided negotiation policy or partial
  failure recovery after peer disconnect mid-commit

Trace visibility:

- transactional item/storage mutations now emit both:
  - authoritative audit rows in `bot_item_audit`
  - structured timeline rows in `bot_trace_event`
- this makes it possible to correlate:
  - item grants/removals
  - equip/unequip
  - storage deposits/withdrawals
  with the broader participation/controller timeline in one place

Important behavior:

- native rAthena trade request and trade accept paths reject a participant that
  is still inside an NPC script session (`npc_id != 0`)
- that means attached-player NPC harness calls are invalid for end-to-end trade
  acceptance tests even when the underlying trade system is healthy
- the participation selftest now uses char-id-targeted trade accept/ok/commit
  helpers so the trade proof runs outside that invalid NPC ownership state

## Participation Hooks V4

- participation now has an explicit reservation-backed dialog lane for contested
  NPC targets
- the shared helpers are:
  - `F_PB_PART_NPCStartReserved`
  - `F_PB_PART_NPCCloseReserved`
  - `F_PB_PART_NPCRecoverReserved`
- this keeps dialog-target contention in the same reservation platform used by
  other shared resources instead of relying on ad hoc caller discipline

Trade/session recovery:

- `playerbot_traderecover(bot_key$)` now gives bots a direct stale-trade cleanup
  verb
- `playerbot_tradecharrecover(char_id)` does the same for the live player side
  during repo-local participation smoke validation
- current recovery semantics are:
  - prefer normal `trade_tradecancel(...)` when the peer/session still exists
  - if stale flags remain, force-clear the local trade state
  - emit interaction traces for the recovery attempt

Quest-style participation:

- `Playerbot Participation Lab` now includes a two-NPC relay proof:
  - `Playerbot Quest Relay A`
  - `Playerbot Quest Relay B`
- this covers:
  - reservation denial while another holder owns the dialog target
  - successful retry after release
  - cross-NPC state carry
  - string-input handling
  - cleanup/recovery between relay steps

Current limits:

- reservation-backed dialog is still opt-in through shared helpers and is not
  yet enforced automatically for every `playerbot_npcstart(...)` call
- the quest-style proof validates participation legality and cleanup, not a
  broad quest-framework abstraction

## Prontera Ambient Filler Cleanup

- the old Prontera ambient filler presentation could surface as `Alarm` when
  inspected as map mobs, even though the intent was harmless town ambiance
- the Prontera ambient lane now uses harmless low-level mob-backed fillers
  instead, so ambient chatter remains but the town no longer reads as if hostile
  Clock Tower mobs are roaming the square

## Participation Recovery Audits

- participation recovery now has an explicit authoritative audit ledger in
  `bot_recovery_audit`
- recovery authority for this slice is:
  - live actor/session state first
  - then forced cleanup of stale local flags
  - then forced cleanup of the live trade peer when the recovering bot is one
    endpoint of the stale deal

Current semantics:

- `playerbot_npcrecover(bot_key$)` is the narrow dialog/session cleanup verb
- `playerbot_participationrecover(bot_key$)` is the broader mixed-state cleanup
  verb for:
  - NPC/dialog
  - storage
  - trade

Important detail:

- the composite recovery proof does not require trade acceptance to succeed
  while the bot is still concurrently inside NPC/storage state
- that mixed state is intentionally hostile; the proof only requires the
  recovery pass to leave all participation surfaces clear and audited

Storage/trade audit coverage:

- `playerbot_storagerecover(bot_key$)` now records scope-specific recovery rows
  in `bot_recovery_audit`
- `playerbot_traderecover(bot_key$)` now records scope-specific recovery rows
  in `bot_recovery_audit`
- the state lab can inspect those recovery rows without dropping straight into
  SQL

Trade peer cleanup:

- stale trade recovery now treats the live peer as part of the same recovery
  boundary when the bot is one endpoint of the stale deal
- this keeps partial cleanup from leaving the human-side session in a phantom
  trade state after the bot clears itself

Reservation cleanup audits:

- stale and expired reservation cleanup now writes authoritative
  `bot_recovery_audit` rows instead of only trace rows
- current recovery authority for this lane is:
  - reservation table row existence
  - lease expiry for timed-out holders
  - holder identity existence for stale orphan cleanup
- cleanup details currently distinguish:
  - `reservation.expired`
  - `reservation.stale_holder`

Operator visibility:

- `Playerbot Reservation Lab` can now show the recent reservation recovery
  audits directly
- `Playerbot State Lab` now includes reservation cleanup in its broader recovery
  audit inspection path

Current limit:

- reservation recovery audits currently attach to reap/cleanup paths, not every
  successful normal release

Ownership drift recovery:

- pooled controller slots now treat ownership drift as an explicit recovery
  boundary instead of silently clearing the slot
- current detail codes are:
  - `owner.split`
  - `path.owner_split`
  - `slot.owner_missing`
  - plus profile/role drift when the assigned pooled identity no longer matches
    the slot contract

Release semantics:

- `F_LW_HPC_DefReleaseActor` no longer emits a normal `controller.released`
  trace when the pool owner has already drifted away
- in that case the local controller slot is cleared as a recovery step and the
  event is recorded as:
  - recovery audit in `bot_recovery_audit`
  - `reconcile.fixed` trace with `claim.lost`

Operator coverage:

- `Playerbot State Lab` now has:
  - manual ownership selftest
  - latest ownership-audit inspection
- repo-local smoke helper:
  - `bash tools/ci/playerbot-state-smoke.sh arm`
  - `bash tools/ci/playerbot-state-smoke.sh check`

Unified bot timeline:

- trace inspection and recovery inspection are no longer fully separate operator
  tasks for per-bot debugging
- `F_PB_OBS_BuildBotTimeline$` now merges:
  - `bot_trace_event`
  - `bot_recovery_audit`
- current surfaces:
  - `Playerbot Trace Lab -> Bot timeline`
  - `Playerbot State Lab -> Inspect bot timeline`

Current limit:

- the merged timeline is script-first and read-only
- it does not yet use shared correlation ids across trace/audit rows
- it is optimized for recent operator debugging, not long-range replay

Contested live handoffs:

- pooled controller ticks now treat live owner conflicts as an explicit recovery
  boundary, not a silent `return 0`
- current tick-time contested-handoff detail codes are:
  - `live.owner_split`
  - `claim.denied`

Current behavior:

- when a pooled actor reaches tick-time live-owner contention or claim denial,
  the local slot assignment is cleared
- recovery is recorded in:
  - `bot_recovery_audit`
  - `bot_trace_event`

Current limit:

- this slice improves visibility and reacquire safety, but it does not yet add a
  dedicated forced `claim.denied` smoke harness

Unified participation failure surface:

- operator debugging for participation problems is no longer split only across:
  - trace lab
  - reservation lab
  - recovery audit menus
- `F_PB_OBS_BuildFailureSurface$` now merges:
  - live participation state
  - held reservations
  - recent failed traces
  - recent recovery audits

Current surfaces:

- `Playerbot Participation Lab -> Inspect failure surface`
- `Playerbot Trace Lab -> Bot failure surface`

Current limit:

- failure surfaces are still recent-window summaries, not persistent incidents
- they prioritize practical debugging over perfect causal grouping

Participation recover-all:

- overlapping participation cleanup now includes bot-held reservations, not only
  NPC/storage/trade runtime state
- `F_PB_PART_RecoverAll` is the current script-side integration point for:
  - `playerbot_participationrecover(...)`
  - `F_PB_RES_ReleaseByHolder(...)`
  - reservation recovery audit + matching interaction trace

Current limit:

- recover-all currently clears only reservations held by the recovering bot
- it does not attempt cross-bot cleanup beyond the existing trade peer cleanup
  already handled in C++

Dialog drift recovery:

- `dialog_target` reservations are now treated as stale when the holder bot no
  longer has an active NPC session
- `F_PB_RES_ReapExpired` is the current recovery point for that drift
- the reaper now records:
  - recovery audit detail `reservation.dialog_inactive`
  - matching `reservation.released` trace rows with
    `reason_code=restart.recovery`
- `F_PB_OBS_BuildDialogConflictSurface$` is the current operator/debug view for
  the combined:
  - NPC target state
  - reservation holder state
  - recent dialog traces
  - recent reservation/participation audits

Current limit:

- only `dialog_target` reservations use the inactive-session cleanup rule
- broader inactive-lock cleanup for other reservation types is still deferred

Bot incident surfaces:

- `F_PB_OBS_BuildIncidentSurface$` is the current combined operator view for:
  - recovery authority summary
  - current failure surface
  - active dialog conflict surface
  - recent mixed trace/audit timeline rows
- the current goal is practical incident inspection, not perfect causal
  reconstruction

Current limit:

- incident surfaces are still computed from live state plus recent rows
- they do not persist grouped incident records
- they do not correlate multiple bots into one shared incident

Sequenced foundation smoke:

- the current canonical integrated runner is:
  - `bash tools/ci/playerbot-foundation-smoke.sh run`
- manual split mode still exists when needed:
  - `bash tools/ci/playerbot-foundation-smoke.sh arm`
  - one `codex` OpenKore login
  - `bash tools/ci/playerbot-foundation-smoke.sh check`
- the runner now waits for map-server readiness and launches OpenKore in tmux
  session `playerbot-foundation-kore`
- this replaced the earlier “arm every subsystem autorun at once” approach,
  which produced false contention between selftests sharing the same login and
  player session

Integrated sequenced-pass fixes now covered:

- merchant selftest no longer forces a nested control-plane reload from inside
  the aggregate run
- participation quest/dialog cleanup now matches the current reservation
  contract:
  - stale dialog preclaims are allowed to be reaped
  - drift cleanup uses authoritative NPC recovery
- guild selftest now prunes old temporary members before invite so the dev guild
  stays reusable instead of filling permanently

Current status:

- the sequenced foundation smoke is green on the integrated baseline
- all current subsystem result lines now pass in one deterministic run:
  - state
  - guild
  - item
  - merchant
  - participation

Current limit:

- this still closes only the current participation/recovery/observability
  foundation wave
- the next foundation frontier is still:
  - broader first-class mechanic cleanup under combat pressure
  - deeper equipment/loadout policy beyond the first intended-loadout baseline
  - richer combat/event participation beyond legal combat hooks

The implementation-facing combat frontier contract is now documented in:

- `doc/project/playerbot-combat-frontier-contract.md`

Follow-on update:

- combat/status/death/respawn participation is now integrated and green in the
  aggregate foundation smoke
- aggregate smoke now waits for the combat selftest line after `stage=done`
  instead of assuming the coordinator and the final combat debug line land at
  the same time
- the first intended-equipment authority now exists in:
  - `bot_equipment_loadout`
- spawn and respawn now reconcile legal intended equipment for headless bots
- item selftests now prove:
  - loadout write
  - despawn/spawn loadout continuity
  - death/respawn loadout continuity
  - loadout recovery-audit coverage

Combat-pressure mechanic cleanup now covered:

- death/respawn cleanup emits per-scope interrupt audits and traces for:
  - `npc`
  - `storage`
  - `trade`
- current combat selftest acceptance now proves:
  - NPC interrupt cleanup on death
  - storage interrupt cleanup on death
  - trade interrupt cleanup on death

Trade interrupt proof update:

- the remaining combat-harness false failures were in the harness setup, not the
  runtime cleanup path:
  - missing inviter identity during the trade path
  - repositioning the respawned bot to the wrong Alberta patch before trade
- the combat selftest now reuses the same proven Alberta trade neighborhood as
  the participation harness
- aggregate foundation smoke is green with trade interrupt now included in the
  combat acceptance proof
