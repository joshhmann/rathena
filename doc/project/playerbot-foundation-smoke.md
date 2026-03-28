# Playerbot Foundation Smoke

This is the repo-local aggregate smoke path for the current playerbot
foundation baseline.

Use it when you want one login pass to exercise the integrated selftests for:

- guild participation
- transactional item layer
- merchant runtime
- broader participation hooks
- ownership / state recovery

## Canonical Flow

From the repo root:

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

The runner also clears stale subsystem autorun/manual mapregs before restart so
the integrated pass has one authority.

and then restarts the repo-local stack through:

```bash
bash tools/dev/playerbot-dev.sh restart
```

## What It Checks

The combined `check` output reports:

- recent `playerbot_foundation_selftest: stage=...` lines from the map-server
  pane
- recent `playerbot_*_selftest` lines from the map-server pane
- recent recovery-audit summaries across:
  - `npc`
  - `storage`
  - `trade`
  - `participation`
  - `reservation`
  - `ownership`
- recent structured trace summaries across:
  - `interaction`
  - `reservation`
  - `reconcile`

## Current Limits

- this is still a smoke runner, not a scenario orchestrator
- it depends on one test login path through the `codex` OpenKore profile
- the sequenced pass is intentionally serialized because the subsystem
  selftests contend on the same login/session if they all autorun at once
- it does not yet cover:
  - combat-participation foundations
  - broader status/death/revive hooks
  - fully generalized scenario fixtures
