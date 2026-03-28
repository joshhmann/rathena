# Playerbot Foundation Smoke

This is the repo-local aggregate smoke path for the current playerbot
foundation baseline.

Use it when you want one login pass to exercise the integrated selftests for:

- combat/status/death/respawn participation
- guild participation
- transactional item and loadout layer
- merchant runtime
- broader participation hooks
- ownership / state recovery

## Canonical Flow

Recommended end-to-end path from the repo root:

```bash
bash tools/ci/playerbot-foundation-smoke.sh run
```

Manual split path:

```bash
bash tools/ci/playerbot-foundation-smoke.sh arm
```

Then log in once with the `codex` OpenKore profile.

After the login-triggered selftests finish:

```bash
bash tools/ci/playerbot-foundation-smoke.sh check
```

## What It Arms

The aggregate runner currently arms only the coordinator:

- `$PBFNST_AUTORUN_AID`

The coordinator then dispatches the subsystem selftests in sequence through their
manual-start hooks:

- state
- guild
- item
- merchant
- participation
- combat

The runner also clears stale subsystem autorun/manual mapregs before restart so
the integrated pass has one authority.

and then restarts the repo-local stack through:

```bash
bash tools/dev/playerbot-dev.sh restart
```

The new `run` mode owns the full path:

- arms the sequenced pass
- restarts the repo-local stack
- waits for map-server readiness
- launches the `codex` OpenKore profile in tmux session
  `playerbot-foundation-kore`
- waits for `playerbot_foundation_selftest: stage=done`
- runs the final integrated `check`

## What It Checks

The combined `check` output reports:

- recent `playerbot_foundation_selftest: stage=...` lines from the map-server
  pane
- recent `playerbot_*_selftest` lines from the map-server pane
- recent recovery-audit summaries across:
  - `combat`
  - `loadout`
  - `npc`
  - `storage`
  - `trade`
  - `participation`
  - `reservation`
  - `ownership`
- recent structured trace summaries across:
  - `combat`
  - `interaction`
  - `reservation`
  - `reconcile`

The item stage now also proves intended loadout continuity:

- persistent intended equipment rows exist in `bot_equipment_loadout`
- spawn-time reconcile can re-equip legal intended items
- respawn-time reconcile can re-equip legal intended items
- loadout reconcile emits item audits, recovery audits, and traces

## Current Limits

- this is still a smoke runner, not a scenario orchestrator
- it still depends on one test login path through the `codex` OpenKore profile
- the sequenced pass is intentionally serialized because the subsystem
  selftests contend on the same login/session if they all autorun at once
- it does not yet cover:
  - fully generalized scenario fixtures
- the next frontier after this smoke is:
  - broader first-class mechanic cleanup under combat pressure
  - richer combat/event participation beyond the current legal hooks
  - deeper equipment/loadout policy and continuity beyond the first intended
    loadout baseline
