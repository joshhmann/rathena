# Bot State Schema

## Purpose

Define the first persistent state model for pseudo-players so future party,
commerce, and behavior systems attach to stable bot identities rather than
temporary spawned GIDs.

This is a design schema, not a committed SQL migration yet.

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
- `personality_tag`
  - lightweight behavior flavor tag
- `created_at`
- `updated_at`

Purpose:

- the canonical identity record

### 2. `bot_appearance`

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

### 3. `bot_runtime_state`

One row per bot profile.

Fields:

- `bot_id`
  - foreign key
- `current_map`
- `current_x`
- `current_y`
- `current_state`
  - idle, walking, resting, merchanting, event, party, offline
- `spawned_gid`
  - nullable runtime reference only
- `last_spawned_at`
- `last_despawned_at`
- `last_route_key`
- `last_seen_tick`

Purpose:

- current runtime position and controller state
- safe restart/recovery coordination

Note:

- `spawned_gid` is runtime glue, not identity

### 4. `bot_behavior_config`

One row per bot profile.

Fields:

- `bot_id`
  - foreign key
- `schedule_key`
- `route_set_key`
- `ambient_talk_pool_key`
- `interaction_policy`
  - ambient_only, clickable, merchant, party_candidate
- `party_policy`
  - never, selective, open
- `merchant_policy`
  - none, fixed_shop, timed_shop, roaming_vendor
- `field_policy`
  - none, patrol, traveler, escort

Purpose:

- separates bot identity from reusable controller behavior

### 5. `bot_inventory`

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

### 6. `bot_party_state`

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

### State Layer Owns

- stable identity
- appearance defaults
- interaction policy
- merchant and party capability flags

## Implementation Order

### Phase 1

- `bot_profile`
- `bot_appearance`
- `bot_runtime_state`

This is enough for:

- stable pseudo-player identity
- reproducible visuals
- better controller ownership

### Phase 2

- `bot_behavior_config`

This is enough for:

- reusable route/schedule/controller assignment

### Phase 3

- `bot_inventory`
- `bot_party_state`

This is enough for:

- merchant bots
- party-capable pseudo-players

## Initial Defaults

- bots are server-owned only
- no account/login identity required
- no char-select semantics
- no real player inventory logic in phase 1
- one bot maps to one active body at most
- body absence must not destroy bot identity

