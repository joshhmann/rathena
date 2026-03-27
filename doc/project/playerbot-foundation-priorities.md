# Playerbot Foundation Priorities

This note captures the remaining foundation work that should be finished before
the project shifts heavily into richer behavior scripting.

It is intentionally concrete. The goal is to reduce ambiguity around what
"foundation complete enough" means for `headless_pc` / `playerbot`.

## Priority Order

The current preferred order for remaining foundation work is:

1. observability and replayability
2. shared perception / world-query facade
3. reservation and contention primitives
4. explicit memory/state boundaries
5. failure-recovery semantics
6. transactional inventory / equipment / storage foundation
7. broader player-system participation hooks

Execution shape:

- use a `Primary + Parallel` model
- keep one canonical order
- allow only safe side lanes that do not compete for the same runtime or script
  hotspots

Execution companion:

- `doc/project/playerbot-foundation-program.md`

## 1. Observability And Replayability

The first step should be one append-only structured event model.

Do not start with many unrelated trace formats.

Minimum event fields:

- `ts`
- `trace_id`
- `bot_id`
- `char_id`
- `account_id`
- `map_id`
- `map_name`
- `x`
- `y`
- `controller_id`
- `controller_kind`
- `owner_token` or `claim_id`
- `phase`
- `action`
- `target_type`
- `target_id`
- `reason_code`
- `inputs`
- `signals`
- `reservation_refs`
- `result`
- `duration_ms`
- `fallback`
- `error_code`
- `error_detail`

First event families:

- `controller.assigned`
- `controller.released`
- `scheduler.spawned`
- `scheduler.parked`
- `move.started`
- `move.completed`
- `move.failed`
- `interaction.requested`
- `interaction.completed`
- `interaction.failed`
- `reservation.acquired`
- `reservation.denied`
- `reservation.released`
- `reconcile.started`
- `reconcile.fixed`
- `reconcile.failed`

Requirements:

- reason and result should use enums
- every meaningful controller action should emit:
  - start
  - end
  - failure if applicable

## 2. Shared Perception / World-Query Facade

Before richer behaviors land, controllers need one stable way to read the world
instead of each controller deriving context differently.

The first shared read-only queries should include:

- `get_self_state(bot)`
- `get_nearby_players(bot, radius, filters)`
- `get_nearby_bots(bot, radius, filters)`
- `get_nearby_npcs(bot, radius, filters)`
- `get_nearby_shops(bot, radius)`
- `get_anchor_state(anchor_id or area)`
- `get_local_heat(map, area)`
- `get_recent_social_contacts(bot, window)`
- `get_party_context(bot)`
- `get_guild_context(bot)`
- `get_route_viability(from, to)`
- `get_interaction_target_state(target)`

Perception responses should include freshness/staleness information, not just
raw values.

Minimum response shape:

- `value`
- `observed_at`
- `stale_ms`
- `confidence`

## 3. Reservation And Contention Primitives

Before deeper behavior work, the first reservation types should be:

1. anchors using leases
2. NPC/dialog targets using hard locks with timeout
3. social targets using leases
4. merchant spots using hard locks
5. party roles using leases

Minimum reservation record:

- `reservation_id`
- `type`
- `resource_key`
- `holder_bot_id`
- `holder_controller_id`
- `lease_until`
- `epoch`
- `priority`
- `reason`
- `created_at`

## 4. Explicit Memory / State Boundaries

The project should keep a strict four-layer state split.

### Persistent Long-Term State

Examples:

- bot identity
- account/character linkage
- appearance / persona / archetype
- long-term affinity or relationship values
- guild membership metadata
- merchant profile
- progression intent
- inventory / equipment ownership
- long-term schedule preferences
- home anchors and recurring content config

### Session / Runtime State

Examples:

- online/offline state
- current map / x / y
- current controller assignment
- active scheduler slot
- active owner / claim token
- active reservation ids
- current route segment
- live merchant open/closed state
- current party follow target
- pending reconcile flags

### Controller-Local Transient State

Examples:

- current candidate target this tick
- local scoring results
- debounce timers
- retry counters
- dialog step index
- recent fallback choice
- temporary posture / intensity state

### Shared World / Social Memory

Examples:

- hot/warm/cool area pressure
- recent map-level social interactions
- anchor occupancy memory
- shared greeting cooldowns
- guild-square focus state
- local crowd mood / activity markers

Rule:

- if losing it breaks who the bot is, it is persistent
- if losing it only interrupts the current activity, it is runtime or transient
- if many controllers need it, it belongs in shared world/social memory

## 5. Failure-Recovery Semantics

The system should define one source of truth for common partial failures.

First cases to formalize:

- controller assigned but bot missing on map
- bot present but controller missing
- stale reservations held by dead/missing bots
- dialog started but bot warped / target invalidated
- merchant open in DB but not live in world
- storage mutation interrupted mid-operation
- party assist target missing after map change
- guild invite pending across restart
- path handoff completed but old owner still claims bot
- reconcile restoring stale location data

Authorities should be explicit per case, for example:

- live world actor state
- reservation table
- transactional inventory store
- persisted scheduler runtime
- controller epoch token

## 6. Transactional Inventory / Equipment / Storage Foundation

This should land before deeper economy or progression work.

The first safe slice should support only:

- inventory add/remove
- equip
- unequip
- storage deposit
- storage withdraw

Rules:

- validate preconditions
- apply atomically
- emit audit events
- update runtime cache
- fail with no half-state

Required invariants:

- an item exists in exactly one location
- no duplicate ownership after failure
- equip legality is enforced server-side
- storage ownership is tied to actor/session ownership
- bot item mutation goes through one bot-safe service layer

## 7. Broader Player-System Participation Hooks

Bots should eventually be first-class across normal player-system codepaths.

Highest-risk codepaths to harden:

- NPC script menus / dialog
- trade
- storage
- equip / use / consume
- map change / warp / respawn
- status / death / revive
- guild and party callbacks
- merchant open/close and stock mutation

The goal is not rich AI yet.

The goal is making bots legal participants in the same server systems real
players already use.

## Supporting Tooling

The top operator / authoring tools to add next are:

1. trace viewer
2. scenario runner
3. reservation + scheduler inspector

These are foundation tools, not optional polish.
