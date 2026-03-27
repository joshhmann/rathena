# Playerbot Perception Contract

## Goal

Give controllers one stable read-only world-query layer so behavior does not
depend on each controller rediscovering world state differently.

## First Queries

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

## Response Shape

Perception should return:

- `value`
- `observed_at`
- `stale_ms`
- `confidence`

## Rules

- perception is read-only in v1
- freshness/staleness is part of the contract, not an afterthought
- once a shared query exists, new controller code should prefer it over
  re-deriving the same context locally
