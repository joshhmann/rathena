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

Fields:

- `bot_id`
  - foreign key
- `schedule_key`
- `route_set_key`
- `daily_routine_key`
- `ambient_talk_pool_key`
- `interaction_policy`
  - ambient_only, clickable, merchant, party_candidate
- `party_policy`
  - never, selective, open
- `merchant_policy`
  - none, fixed_shop, timed_shop, roaming_vendor
- `field_policy`
  - none, patrol, traveler, escort
- `presence_policy`
  - always_on, demand_gated, schedule_gated, hybrid
- `despawn_grace_ms`
  - cooldown before parking when demand disappears

Purpose:

- separates bot identity from reusable controller behavior

Status:

- deferred
- still expected as the next behavior-focused slice after the core identity
  tables

### 6. `bot_inventory`

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

### 7. `bot_party_state`

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

### 8. `bot_progression_state`

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

- `bot_inventory`
- `bot_party_state`
- `bot_progression_state`

This is enough for:

- merchant bots
- party-capable pseudo-players
- progression-capable recurring playerbots

## Initial Defaults

- bots are server-owned only
- current live path may continue to reuse account/login identity until a deeper
  provisioning layer replaces it
- no char-select semantics
- no real player inventory logic in phase 1
- one bot maps to one active body at most
- body absence must not destroy bot identity
