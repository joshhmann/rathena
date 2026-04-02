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
   - added repeated quick-gate flake-hunt helper with automatic fail-hint
     extraction (`tools/ci/playerbot-foundation-flake-hunt.sh`)
2. Market execution semantics beyond ownership continuity: complete
   - market smoke and market-session stress now prove buyingstore partial fill,
     reopen, denial continuity, and post-close mail delivery
   - Rodex receive / attachment retrieval is now helper-backed through the
     dedicated Rodex selftest lane
   - any dedicated NPC-shop proof is now optional naming, not a required
     foundation blocker
   - full closeout matrix now executes market-session stress as a dedicated
     checkpoint after overlap/combat stress
3. Guild storage signal hardening: complete
   - SQL-safe guild storage helper proves real `guild_storage` and
     `guild_storage_log` activity can be seeded, observed, and cleaned up
     without residue
   - scenario governance now treats guild storage demand/activity as a
     helper-backed proof surface rather than an undocumented side helper
3. Mechanic execution semantics (refine/reform/enchantgrade) beyond baseline: in progress
   - item selftest now proves real refine/reform/enchantgrade execution and
     re-exec semantics
   - card insertion denied + success proof is now covered in the item lane
   - aggregate quick gate is green with the expanded mechanic execution proof
4. Deeper equip/use/consume continuity under overlapping transitions: complete
   - loadout overlap continuity loop increased to 3 cycles in aggregate item
     selftest and remains green
   - overlap actions (storage withdraw/deposit and equip re-toggle) are now
     covered in the accepted item lane
   - real delayed item use now proves session-open success, death/mapchange
     interruption cleanup, inventory continuity, and missing-item denial
5. Broader combat-event continuity under repeated transitions: complete
   - repeated-transition stress now checks combat continuity + market commit +
     item loadout continuity + full mechanic re-exec and is green
   - richer skillunit creation/cleanup and precheck proof are helper-backed in
     the dedicated combat lanes
   - helper-backed PvP nightmare-drop retention and WoE-style respawn routing
     are now proven in the combat edge lane
   - accepted boundary: keep the split skillunit proof helper-backed unless a
     future sprint intentionally promotes it
6. Scenario coverage for all remaining open fronts: in progress
7. Trace/audit reason/result quality and debuggability: in progress
   - closeout matrix now executes a trace-quality checkpoint that fails on
     malformed failure metadata (`error_code`/`error_detail`/`reason_code`)
     and missing interrupt audit detail
   - combat selftest now emits expanded fail hints for hidden gating signals
     (session/trace/audit/warp groups) when `result=0`

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

The remaining lifecycle-specific open fronts are now split:

- spawn-failure cleanup is covered in runtime and now helper-backed through `tools/ci/playerbot-lifecycle-spawnfail-smoke.sh`
- despawn grace is runtime-visible and helper-backed through `tools/ci/playerbot-lifecycle-grace-smoke.sh`
  guarantee

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
- `lifecycle-spawn-failure-cleanup`
- `lifecycle-despawn-grace-window`
- `foundation-rich-gate`

## Additional Lifecycle Runbooks (Not Yet Automated Closeout Gates)

The scenario runner also documents two remaining lifecycle fronts:

Both lifecycle fronts are now part of the automated scenario-definition set and
have dedicated lifecycle checkpoints.

## Behavior Readiness Rule

Behavior phase can start only when:

- all closeout checks are green
- closeout gate stability target is met
- remaining non-behavior deferrals are explicitly documented
- no unresolved foundation flake is still open in acceptance runs
