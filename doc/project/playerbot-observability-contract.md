# Playerbot Observability Contract

## Goal

Provide one structured, append-only event model that makes controller,
scheduler, movement, interaction, reservation, and reconcile behavior
explainable after the fact.

## First Event Fields

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

## First Event Families

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

## Rules

- reason and result should use enums, not freeform prose
- every meaningful controller action should emit:
  - start
  - end
  - failure when applicable
- observability should explain behavior, not replace behavior logic

## First Debugging Surfaces

- trace-by-bot
- trace-by-controller
- trace-by-map
- trace-by-result/failure
- one timeline view that reconstructs an action path from assignment through
  resolution
