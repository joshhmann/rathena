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

The current catalog contains:

- `combat-baseline`
- `combat-skillunit-mapchange-cleanup`
- `combat-skillunit-death-cleanup`
- `combat-skillunit-quit-cleanup`
- `combat-skillunit-promotion-precheck`
- `combat-repeated-transition-stress`
- `status-continuity`
- `status-death-cleanup`
- `status-map-continuity`
- `status-respawn-reconcile`
- `status-recovery-integrity`
- `death-respawn`
- `item-loadout-continuity`
- `loadout-denied-recover`
- `loadout-overlap-continuity`
- `mechanic-cleanup`
- `mechanic-execution-rollback`
- `market-buyingstore-partial-fill`
- `market-buyingstore-reopen`
- `market-buyingstore-denial-continuity`
- `market-mail-delivery-integrity`
- `market-session-restart-continuity`
- `lifecycle-spawn-failure-cleanup`
- `lifecycle-despawn-grace-window`
- `foundation-rich-gate`

Current phase labels used by the catalog:

- `combat`
- `status`
- `respawn`
- `equipment`
- `participation`
- `market`
- `lifecycle`

These split into two groups:

- runbook-backed with a repo-local smoke launcher:
  - `combat-baseline`
  - `combat-skillunit-mapchange-cleanup`
  - `combat-skillunit-death-cleanup`
  - `combat-skillunit-quit-cleanup`
  - `combat-skillunit-promotion-precheck`
  - `combat-repeated-transition-stress`
  - `status-continuity`
  - `status-death-cleanup`
  - `status-map-continuity`
  - `status-respawn-reconcile`
  - `status-recovery-integrity`
  - `death-respawn`
  - `item-loadout-continuity`
  - `loadout-denied-recover`
  - `loadout-overlap-continuity`
  - `mechanic-cleanup`
  - `mechanic-execution-rollback`
  - `market-buyingstore-partial-fill`
  - `market-buyingstore-reopen`
  - `market-buyingstore-denial-continuity`
  - `market-mail-delivery-integrity`
  - `market-session-restart-continuity`
  - `foundation-rich-gate`

- documented lifecycle fronts split into:
  - runbook-only:
    - `lifecycle-spawn-failure-cleanup`
  - helper-backed:
    - `lifecycle-despawn-grace-window`

The lifecycle entries now split cleanly:

- `lifecycle-spawn-failure-cleanup` remains manual/runbook-focused
- `lifecycle-despawn-grace-window` is backed by
  `tools/ci/playerbot-lifecycle-grace-smoke.sh`

Spawn-failure cleanup is runtime-backed. Despawn grace is runtime-visible and
now helper-backed, but neither lifecycle front is promoted into the automated
closeout set yet.

The runbook-backed scenarios use:

- `tools/ci/playerbot-combat-smoke.sh`
- `tools/ci/playerbot-combat-skillunit-smoke.sh`
- `tools/ci/playerbot-combat-skillunit-precheck-smoke.sh`
- `tools/ci/playerbot-item-smoke.sh`
- `tools/ci/playerbot-item-overlap-stress.sh`
- `tools/ci/playerbot-participation-smoke.sh`
- `tools/ci/playerbot-market-smoke.sh`
- `tools/ci/playerbot-market-session-stress.sh`
- `tools/ci/playerbot-combat-transition-stress.sh`
- `tools/ci/playerbot-lifecycle-grace-smoke.sh`

Highest-value missing additions after this expansion:

- repo-local lifecycle helper that can promote spawn-failure cleanup from a
  runtime-backed runbook into a passing automated check
- richer scenario automation for remaining open market/item/mechanic/lifecycle
  fronts

## CLI Contract

Use the runner with:

```bash
bash tools/ci/playerbot-scenario.sh list
bash tools/ci/playerbot-scenario.sh show combat-baseline
bash tools/ci/playerbot-scenario.sh show combat-skillunit-death-cleanup
bash tools/ci/playerbot-scenario.sh checklist death-respawn
bash tools/ci/playerbot-scenario.sh describe item-loadout-continuity
bash tools/ci/playerbot-scenario.sh template combat-baseline
bash tools/ci/playerbot-scenario.sh run mechanic-cleanup
bash tools/ci/playerbot-scenario.sh run combat-baseline
bash tools/ci/playerbot-scenario.sh run market-buyingstore-partial-fill
bash tools/ci/playerbot-scenario.sh run loadout-denied-recover
bash tools/ci/playerbot-scenario.sh run combat-skillunit-promotion-precheck
bash tools/ci/playerbot-scenario.sh run market-mail-delivery-integrity
bash tools/ci/playerbot-scenario.sh run loadout-overlap-continuity
bash tools/ci/playerbot-scenario.sh run combat-repeated-transition-stress
bash tools/ci/playerbot-scenario.sh show lifecycle-spawn-failure-cleanup
bash tools/ci/playerbot-scenario.sh show lifecycle-despawn-grace-window
bash tools/ci/playerbot-scenario.sh run foundation-rich-gate
```

Expected behavior:

- `list` prints the catalog table
- `show` prints the runbook, prerequisites, checklist, expected signals, and notes
- `describe` prints machine-readable `key=value` metadata
- `checklist` prints only the steps
- `template` prints a copy/paste scenario skeleton
- `run` prints the runbook and, when available, the repo-local launcher/check flow
- lifecycle scenarios that do not yet have a launcher are expected to print the
  skeleton/manual-runbook fallback text

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

For closeout, the scenario catalog should stay aligned with the gap audit and
the foundation closeout checklist:

- market/session execution depth
- equip/use/consume continuity depth
- combat-event repeated-transition continuity
- lifecycle fronts that are still documentation-only should be called out as
  manual/not-yet-automated so the closeout docs do not overclaim runtime proof
