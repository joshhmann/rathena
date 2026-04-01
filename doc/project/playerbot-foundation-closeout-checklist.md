# Playerbot Foundation Closeout Checklist

This document is the canonical closeout checklist for the current foundation
phase. It defines what must be verified before behavior-focused work becomes
the primary lane.

Use this together with:

- `doc/project/playerbot-foundation-program.md`
- `doc/project/playerbot-combat-frontier-contract.md`
- `doc/project/playerbot-mechanic-gap-audit.md`
- `doc/project/playerbot-scenario-runner.md`
- `doc/project/playerbot-foundation-smoke.md`

## Current Baseline

The following baseline is already accepted:

- aggregate foundation smoke gate is green (`run`)
- richer foundation smoke gate is green (`run-rich`)
- integrated combat selftest is green in aggregate foundation orchestration
- market/item/participation/state/guild stages are green in aggregate runs

## Current Roadmap Status (2026-03-31)

Recently stabilized in `master`:

- participation trade lane no longer flakes in aggregate runs
  (`trade_ok`, `trade_recover_ok`, `trade_force_clear_ok` are green)
- combat selftest no longer emits overlong local-var `set_reg` warnings
- aggregate foundation check is green after both fixes

Current closeout status:

1. Gate stability and determinism: in progress
   - full gate run reached `4/10` then failed at `5/10` on combat continuity loop flake
   - continuity loop retry hardening applied; quick gate is green again
2. Market execution semantics beyond ownership continuity: in progress
   - merchant market selftest now emits vend-phase mail integrity telemetry
   - pass criteria for new vend-mail signals intentionally deferred until denial semantics are deterministic
   - full closeout matrix now executes market-session stress as a dedicated
     checkpoint after overlap/combat stress
3. Mechanic execution semantics (refine/reform/enchantgrade) beyond baseline: in progress
   - item selftest mech re-exec now requires concrete enchant execution effect
     (material or zeny delta), not trace-only acceptance
   - mech re-exec setup now resets live enchant item state before regrant
   - aggregate quick gate is green with `enchant_reexec_ok=1` and `enchant_reexec_clear_ok=1`
4. Deeper equip/use/consume continuity under overlapping transitions: in progress
   - loadout overlap continuity loop increased to 3 cycles in aggregate item
     selftest
   - each cycle now proves overlap actions (storage withdraw/deposit and
     equip re-toggle) while preserving loadout + consumable invariants
   - item smoke now requires `loadout_cycle_count=3`
   - full closeout matrix now executes `playerbot-item-overlap-stress`
     (`pre item` -> `aggregate` -> `post item`) as a dedicated overlap check
5. Broader combat-event continuity under repeated transitions: in progress
   - repeated-transition stress now checks combat continuity + market commit +
     item loadout continuity + full mechanic re-exec (refine/reform/enchant)
   - closeout full matrix now executes repeated-transition stress after
     aggregate/rich loops with strict drift enforcement
   - repeated-transition stress now requires per-run interrupt-clear signals
     (`npc/storage/trade`) and per-run interrupt audit evidence
6. Scenario coverage for all remaining open fronts: in progress
7. Trace/audit reason/result quality and debuggability: in progress

## Closeout Gate

Run the canonical closeout executor:

```bash
bash tools/ci/playerbot-foundation-gate.sh full
```

Defaults:

- 10x aggregate gate (`run`)
- 5x richer gate (`run-rich`)
- required scenario definition checks for closeout fronts

Day-to-day pre-merge gate:

```bash
bash tools/ci/playerbot-foundation-gate.sh quick
```

Default workflow:

1. run `quick` for each candidate slice/branch
2. fix any failing lane before review-ready
3. run `full` at closeout checkpoints and major merge windows

## Required Checks

The foundation phase is not complete until all items below are true.

1. Gate stability and determinism
2. Market execution semantics beyond ownership continuity
3. Mechanic execution semantics (refine/reform/enchantgrade) beyond baseline
4. Deeper equip/use/consume continuity under overlapping transitions
5. Broader combat-event continuity under repeated transitions
6. Scenario coverage for all remaining open fronts
7. Trace/audit reason/result quality and debuggability

## Remaining Work Sequence

Execute the remaining closeout fronts in this order:

1. broader market/session execution semantics
2. mechanic execution semantics beyond session ownership
3. deeper equip/use/consume continuity under overlapping transitions
4. broader combat-event continuity under repeated transitions
5. richer scenario coverage and trace/audit clarity for those fronts

The companion system lane (pet/homunculus/mercenary/elemental) remains a
separate future foundation extension after this closeout sequence is green.

## Scenario Coverage Set

The closeout set includes:

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

## Behavior Readiness Rule

Behavior phase can start only when:

- all closeout checks are green
- closeout gate stability target is met
- remaining non-behavior deferrals are explicitly documented
- no unresolved foundation flake is still open in acceptance runs
