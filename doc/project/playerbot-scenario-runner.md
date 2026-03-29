# Playerbot Scenario Runner

## Purpose

This document defines the repo-local scenario runner foundation for the next
playerbot frontier:

- combat participation
- status continuity
- death / respawn continuity
- item and loadout continuity
- broader mechanic cleanup

The runner is intentionally tooling-only. It does not change runtime semantics
and it does not replace the existing OpenKore smoke helpers.

## Scope

The current implementation is a scenario catalog plus a CLI entrypoint that
prints structured runbooks. The first combat-oriented scenarios now also point
at a repo-local smoke helper.

Implemented files:

- `tools/ci/playerbot-scenario.sh`
- `tools/ci/playerbot-scenario-catalog.sh`

The catalog is safe to extend by adding more scenario cases in the tooling
layer. A scenario is treated as a stable definition if it exposes:

- title
- phase
- kind
- purpose
- prerequisites
- checklist
- expected signals

## Current Scenario Catalog

The initial frontier catalog contains:

- `combat-baseline`
- `status-continuity`
- `status-death-cleanup`
- `status-map-continuity`
- `status-respawn-reconcile`
- `status-recovery-integrity`
- `death-respawn`
- `item-loadout-continuity`
- `mechanic-cleanup`

Current phase labels used by the catalog:

- `combat`
- `status`
- `respawn`
- `equipment`
- `participation`

These split into two groups:

- runbook-backed today:
  - `combat-baseline`
  - `status-continuity`
  - `status-death-cleanup`
  - `status-map-continuity`
  - `status-respawn-reconcile`
  - `status-recovery-integrity`
  - `death-respawn`
  - `item-loadout-continuity`
- skeleton-only for the next frontier:
  - `mechanic-cleanup`

The unresolved mechanic-cleanup gaps are summarized in:

- `doc/project/playerbot-mechanic-gap-audit.md`

The runbook-backed scenarios use:

- `tools/ci/playerbot-combat-smoke.sh`
- `tools/ci/playerbot-item-smoke.sh`

The remaining skeleton scenario stays future-facing until those runtime hooks
land.

Highest-value missing additions after this update are:

- richer mechanic-cleanup coverage for interrupted NPC, trade, and storage flows
- a narrower combat-interrupt scenario that isolates death/respawn cleanup from
  broader status continuity
- scenario coverage for later combat/status edges such as status persistence
  across repeated handoffs or multiple sequential deaths

## CLI Contract

Use the runner with:

```bash
bash tools/ci/playerbot-scenario.sh list
bash tools/ci/playerbot-scenario.sh show combat-baseline
bash tools/ci/playerbot-scenario.sh checklist death-respawn
bash tools/ci/playerbot-scenario.sh describe item-loadout-continuity
bash tools/ci/playerbot-scenario.sh template combat-baseline
bash tools/ci/playerbot-scenario.sh run mechanic-cleanup
bash tools/ci/playerbot-scenario.sh run combat-baseline
```

Expected behavior:

- `list` prints the catalog table
- `show` prints the runbook, prerequisites, checklist, expected signals, and notes
- `describe` prints machine-readable `key=value` metadata
- `checklist` prints only the steps
- `template` prints a copy/paste scenario skeleton
- `run` prints the runbook and, when available, the repo-local launcher/check flow

## Definition Flow

The intended definition flow is:

1. add a new case in `tools/ci/playerbot-scenario-catalog.sh`
2. keep the CLI contract unchanged
3. add a short doc note if the scenario family gains a new testing expectation
4. only add runtime automation when the corresponding runtime frontier exists

That keeps the runner useful now, while leaving room for later OpenKore-backed
or in-game automation.

## Relationship To Existing Smoke Helpers

The existing OpenKore smoke helper remains the right tool for scheduler-facing
CLI checks:

- `tools/ci/openkore-smoke.sh`

The scenario runner is the next-layer runbook for frontier work where the
observed system is partly automated and still needs a stable operator contract.

## Validation Notes

The runner should stay non-breaking and doc-backed. When adding a new scenario
definition, the minimum validation should cover:

- `list`
- `show <scenario>`
- `describe <scenario>`
- `checklist <scenario>`

For the next mechanic-participation frontier, the scenario catalog should
expand in the same order as the gap audit:

- map-change / warp cleanup
- trade / storage / dialog interruption under combat pressure
- equip / use / consume continuity
- broader combat-event participation
