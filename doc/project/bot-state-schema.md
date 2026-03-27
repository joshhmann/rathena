# Bot State Schema

## Purpose

Define the first persistent state model for pseudo-players so future party,
commerce, and behavior systems attach to stable bot identities rather than
temporary spawned GIDs.

The first persistent identity slice is now committed in SQL. This document
tracks the implemented core tables and the deferred extensions that should sit
on top of them.

Important near-term rule:

- the live `headless_pc` path currently reuses real account/character rows by
  `char_id`
- those rows should be treated as persistent reusable bot identities
- controller stop or map-idle cleanup should park bots offline, not treat them
  as disposable records

Committed slice:

- `bot_profile`
- `bot_identity_link`
- `bot_appearance`
- `bot_runtime_state`

## Core Rule

The spawned fakeplayer body is ephemeral.

The bot record is the persistent identity.

Anything that must survive despawn or restart belongs to the bot state layer,
not to the currently spawned body.

## Recommended Entities

### 1. `bot_profile`

One row per pseudo-player identity.

Fields:

- `bot_id`
  - primary key
- `bot_key`
  - stable unique string id used by scripts and engine code
- `name`
  - display name
- `status`
  - active, disabled, retired, draft
- `role`
  - traveler, guard, merchant, local, event_rival, companion
- `home_map`
  - default home/anchor map
- `routine_pool`
  - recurring region/cohort assignment
- `timezone_policy`
  - schedule/timezone grouping for routine presence
- `personality_tag`
  - lightweight behavior flavor tag
- `created_at`
- `updated_at`

Purpose:

- the canonical identity record

Status:

- committed in `sql-files/main.sql`
- migration artifact: `sql-files/upgrades/upgrade_20260324_playerbot_schema.sql`

### 2. `bot_identity_link`

One row per bot profile.

Fields:

- `bot_id`
  - foreign key to `bot_profile`
- `account_id`
  - optional real account link
- `char_id`
  - optional real character link
- `link_status`
  - pending, linked, retired
- `linked_at`

Purpose:

- maps a persistent bot identity to the reusable account/character rows that
  currently power the runtime body
- keeps the provisioning layer explicit instead of hiding the relationship in
  scripts

Status:

- committed in `sql-files/main.sql`
- migration artifact: `sql-files/upgrades/upgrade_20260324_playerbot_schema.sql`

### 3. `bot_appearance`

One row per bot profile.

Fields:

- `bot_id`
  - foreign key to `bot_profile`
- `job_id`
- `sex`
- `hair_style`
- `hair_color`
- `cloth_color`
- `weapon_view`
- `shield_view`
- `head_top`
- `head_mid`
- `head_bottom`

Purpose:

- persistent visual presentation
- source-backed body spawn reads from this record

Status:

- committed in `sql-files/main.sql`
- migration artifact: `sql-files/upgrades/upgrade_20260324_playerbot_schema.sql`

### 4. `bot_runtime_state`

One row per bot profile.

Fields:

- `bot_id`
  - foreign key
- `current_map`
- `current_x`
- `current_y`
- `current_state`
  - idle, walking, resting, merchanting, event, party, offline
- `park_state`
  - active, grace, parked
- `spawned_gid`
  - nullable runtime reference only
- `last_spawned_at`
- `last_despawned_at`
- `last_parked_at`
- `despawn_grace_until`
- `last_route_key`
- `last_seen_tick`

Purpose:

- current runtime position and controller state
- safe restart/recovery coordination

Note:

- `spawned_gid` is runtime glue, not identity

Status:

- committed in `sql-files/main.sql`
- migration artifact: `sql-files/upgrades/upgrade_20260324_playerbot_schema.sql`

### 5. `bot_behavior_config`

One row per bot profile.

Current committed fields:

- `bot_id`
  - foreign key
- `profile_key`
- `pool_key`
- `controller_tag`
- `interaction_policy`
  - ambient_only, clickable, party_candidate, merchant_candidate
- `party_policy`
  - never, selective, open
- `presence_policy`
  - always_on, demand_gated, schedule_gated, hybrid
- `routine_group`
- `routine_start_hour`
- `routine_end_hour`
- `pulse_profile`
- `updated_at`

Purpose:

- separates bot identity from reusable controller behavior
- allows controllers to request recurring identities by `pool_key`,
  `profile_key`, and `role` instead of by fixed seeded names

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260325_playerbot_provisioning.sql`

Near-term extension fields still expected later:

- `schedule_key`
- `route_set_key`
- `daily_routine_key`
- `ambient_talk_pool_key`
- `merchant_policy`
- `field_policy`
- `despawn_grace_ms`

These remain deferred until the scheduler, merchant, and travel-controller
lanes need them in SQL rather than script config.

### 6. `bot_merchant_state`

One row per bot profile.

Committed fields:

- `bot_id`
  - foreign key
- `merchant_policy`
  - stall_day, harbor_evening, popup_weekend, disabled
- `shop_name`
- `market_map`
- `market_x`
- `market_y`
- `opening_start_hour`
- `opening_end_hour`
- `stock_profile`
- `price_profile`
- `stall_style`
  - anchored, roaming, popup
- `open_state`
  - closed, scheduled, open
- `enabled`

Purpose:

- separates merchant-capable recurring bot state from generic behavior config
- gives merchant-capable bots a persistent market identity even while parked
- supports later shop-facing controller work without forcing vending semantics
  into the scheduler or party layers

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260325_playerbot_merchant_state.sql`

### 7. `bot_merchant_stock_item`

One or more rows per merchant stock profile.

Committed fields:

- `stock_profile`
- `item_index`
- `item_id`
- `stock_amount`
- `sell_price`

Purpose:

- moves merchant stock definition out of script config and into SQL-backed
  recurring data
- supports the approved merchant-runtime pattern of visible merchant actors
  plus real NPC shop interfaces
- gives merchant-capable recurring bots a stable stock identity without
  pretending they are true vending-player sessions

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260326_playerbot_merchant_runtime.sql`

### 8. `bot_controller_demand_map`

One or more weighted demand-map rows per controller policy.

Committed fields:

- `controller_key`
- `map_name`
- `user_weight`
- `point_index`

Purpose:

- lets scheduler and controller run-gating react to weighted demand from more
  than one map
- keeps spillover demand logic out of hardcoded script conditionals
- supports town-plus-field or town-plus-neighbor demand models without
  rewriting controller scripts

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260326_playerbot_demand_profiles.sql`

### 9. `bot_pulse_profile`

One row per reusable ambient/social pulse profile.

Committed fields:

- `profile_key`
- `start_hour`
- `end_hour`
- `min_delay_s`
- `max_delay_s`
- `talk_weight`

Purpose:

- moves social pulse timing and talk-vs-emote weighting out of script config
- gives controller slots stable SQL-backed pulse keys
- keeps recurring social behavior data-owned instead of hand-coded in controller
  files

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260326_playerbot_demand_profiles.sql`

### 10. `bot_inventory`

Deferred but expected if commerce or party support becomes real.

Fields:

- `bot_id`
- `item_id`
- `amount`
- `equip_slot`
- `is_equipped`

Purpose:

- persistent merchant stock
- future equipment-driven appearance or progression

Status:

- deferred

### 11. `bot_guild_state`

One row per bot profile.

Committed fields:

- `bot_id`
  - foreign key
- `guild_policy`
  - town_member, event_roster, guildless, reserved
- `guild_name`
- `guild_position`
- `invite_policy`
  - never, selective, open
- `guild_member_state`
  - unguilded, candidate, member, officer, leader
- `enabled`

Purpose:

- separates guild-capable recurring bot state from generic party and merchant
  policy
- gives recurring bots a stable guild-facing identity even while parked or not
  currently attached to real guild mechanics
- provides the persistent metadata layer that later guild invitation,
  membership, and schedule/event work can build on without redefining bot
  identity

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260326_playerbot_guild_state.sql`

### 12. `bot_guild_runtime`

Runtime guild activity ledger used by scheduler demand.

Committed fields:

- `guild_name`
- `last_member_join_at`
- `last_notice_at`
- `updated_at`

Purpose:

- records recent guild activity without overloading static guild-policy state
- supports time-window scheduler signals such as:
  - `guild_join_recent_name`
  - `guild_notice_recent_name`
- keeps recent guild activity queryable even when bots are parked or demand is
  being evaluated without a live controller body

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260326_playerbot_guild_activity_signals.sql`

### 12a. `bot_guild_activity_log`

Recent guild-activity event ledger.

Committed fields:

- `id`
- `guild_name`
- `activity_type`
  - `member_join`
  - `notice_change`
- `activity_units`
- `created_at`

Purpose:

- keeps recent guild activity queryable as event volume, not only latest timestamp
- supports richer scheduler demand signals such as:
  - `guild_join_events_name`
  - `guild_notice_events_name`
- lets in-game operator surfaces show recent guild pressure without falling back to
  ad hoc SQL inspection

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260326_playerbot_activity_logs.sql`

### 13. `bot_party_state`

Deferred until party-capable pseudo-players are implemented.

Fields:

- `bot_id`
- `party_id`
- `party_role`
- `invite_policy`
- `leader_preference`
- `follow_target_bot_id`
- `follow_target_char_id`

Purpose:

- stable party semantics independent of one spawned body

Status:

- deferred

### 14. `bot_controller_demand_signal`

One or more weighted participation-signal rows per controller policy.

Committed fields:

- `controller_key`
- `point_index`
- `signal_type`
  - merchant_open_map, merchant_live_map, merchant_stock_map,
    merchant_browse_map, merchant_sale_map, merchant_browse_events_map,
    merchant_sale_units_map, guild_enabled_name,
    guild_roster_name, guild_live_name, guild_leader_name,
    guild_leader_live_name, guild_notice_name, guild_join_recent_name,
    guild_notice_recent_name, guild_join_events_name,
    guild_notice_events_name, guild_storage_name, guild_storage_log_name,
    guild_castle_name, guild_candidate_map
- `signal_key`
- `signal_weight`

Purpose:

- extends scheduler demand beyond pure map-user counts
- lets controller demand react to persistent merchant and guild participation
  pressure using the same SQL-backed policy lane as demand maps
- newer guild signal families can distinguish:
  - configured guild-capable identity pressure
  - real linked guild roster membership
  - real linked guild members currently online
  - recent guild joins
  - recent guild join event volume
  - recent guild notice changes
  - recent guild notice event volume
  - real guild storage depth
  - recent guild storage activity
  - guild castle ownership pressure
- newer merchant signal families can distinguish:
  - merchants merely being open
  - merchants being interacted with recently
  - recent browse-event volume
  - recent sale-unit volume
- keeps economy/guild participation heuristics data-owned instead of scattered
  through controller scripts

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260326_playerbot_demand_signals.sql`

### 14a. `bot_merchant_activity_log`

Recent merchant-activity event ledger.

Committed fields:

- `id`
- `bot_id`
- `activity_type`
  - `browse`
  - `sale`
- `activity_units`
- `created_at`

Purpose:

- keeps recent merchant interaction volume queryable as events instead of only the
  latest browse/sale timestamps
- supports richer economy-aware scheduler signals such as:
  - `merchant_browse_events_map`
  - `merchant_sale_units_map`
- lets in-game merchant lab inspection reflect the same recent demand surfaces the
  scheduler now uses

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260326_playerbot_activity_logs.sql`

### 15. `bot_progression_state`

Deferred but explicitly expected for the fuller playerbot lane.

Fields:

- `bot_id`
- `build_tag`
- `progression_profile`
- `base_level`
- `job_level`
- `equipment_profile`
- `daily_activity_budget`
- `last_progression_tick`

Purpose:

- preserve the feeling that recurring bots are living characters, not reset
  props
- support later progression, party, and role advancement systems

Status:

- deferred

### 16. `bot_item_audit`

Append-only transactional item mutation ledger for live playerbots.

Committed fields:

- `id`
- `ts`
- `bot_id`
- `char_id`
- `account_id`
- `action`
  - `inventory_add`
  - `inventory_remove`
  - `equip`
  - `unequip`
  - `storage_deposit`
  - `storage_withdraw`
- `item_id`
- `amount`
- `location`
  - `inventory`
  - `equipped`
  - `storage`
- `result`
  - `ok`
  - `denied`
  - `invalid`
  - `missing`
  - `overflow`
  - `failed`
- `detail`

Purpose:

- gives the transactional inventory/equipment/storage foundation an explicit
  audit trail
- records the first bot-safe item mutation verbs against the real
  `inventory` and `storage` tables rather than inventing a parallel item
  store too early
- supports operator verification and failure recovery without relying on ad hoc
  SQL inspection

Status:

- committed in `sql-files/main.sql`
- migration artifact:
  `sql-files/upgrades/upgrade_20260327_playerbot_item_audit.sql`

## Runtime Ownership

### Source Layer Owns

- fakeplayer body creation
- body despawn
- body movement hooks
- runtime gid exposure

### Script Layer Owns

- spawn/despawn decisions
- schedules
- route selection
- chatter/emotes
- presence gating
- despawn grace and parking decisions until a dedicated scheduler owns them

### State Layer Owns

- stable identity
- appearance defaults
- interaction policy
- merchant and party capability flags
- recurring routine policy
- progression continuity

## Implementation Order

### Phase 1

- `bot_profile`
- `bot_identity_link`
- `bot_appearance`
- `bot_runtime_state`

This is enough for:

- stable pseudo-player identity
- reproducible visuals
- better controller ownership
- parked/offline continuity without deleting bot identities

### Phase 2

- `bot_behavior_config`

This is enough for:

- reusable route/schedule/controller assignment

### Phase 3

- transactional item audit + bot-safe item verbs
- `bot_inventory`
- `bot_party_state`
- `bot_progression_state`

This is enough for:

- merchant bots with auditable item mutations
- party-capable pseudo-players
- progression-capable recurring playerbots

## Initial Defaults

- bots are server-owned only
- current live path may continue to reuse account/login identity until a deeper
  provisioning layer replaces it
- no char-select semantics
- real item ownership still lives in rAthena `inventory` / `storage`; the bot
  layer currently adds audit and safe mutation surfaces on top
- one bot maps to one active body at most
- body absence must not destroy bot identity
