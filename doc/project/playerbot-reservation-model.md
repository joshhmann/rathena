# Playerbot Reservation Model

## Goal

Prevent bots and controllers from fighting over the same contested spaces and
interactions.

## First Reservation Types

1. anchors using leases
2. NPC/dialog targets using hard locks with timeout
3. social targets using leases
4. merchant spots using hard locks
5. party roles using leases

## Reservation Record

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

## Rules

- leases must expire if the holder disappears or loses ownership
- hard locks must still have bounded timeout
- cleanup should be authority-driven, not best-effort guessing
- reservations are a platform rule, not per-controller ad hoc state
