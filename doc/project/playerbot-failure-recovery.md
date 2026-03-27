# Playerbot Failure Recovery

## Goal

Define one source of truth and one recovery rule for common partial-failure
cases.

## First Cases To Formalize

- controller assigned but bot missing on map
- bot present but controller missing
- stale reservation held by dead/missing bot
- dialog started but bot warped or target invalidated
- merchant marked open in DB but not live in world
- storage mutation interrupted mid-operation
- party assist target missing after map change
- guild invite pending across restart
- path handoff completed but old owner still claims bot
- reconcile restores stale location data

## Authorities

Approved authorities for v1:

- live world actor state
- reservation table
- transactional inventory/store state
- persisted scheduler runtime
- controller epoch token

## Rule

For each failure class, choose one authority.

Do not allow two competing sources of truth for the same recovery decision.
