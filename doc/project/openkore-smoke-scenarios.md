# OpenKore Smoke Scenarios

## Purpose

This document turns the current ad hoc OpenKore checks into repeatable smoke
scenarios for playerbot and scheduler slices.

Use it with:

- [OpenKore Test Harness](/root/dev/rathena/doc/project/openkore-test-harness.md)
- `tools/ci/openkore-smoke.sh`
- `tools/ci/playerbot-guild-smoke.sh`
- [Playerbot Scenario Runner](/root/dev/rathena/doc/project/playerbot-scenario-runner.md)

## Current Baseline

These scenarios assume the current local harness:

- OpenKore control overlay: `/root/testing/openkore-control-codex`
- OpenKore tables overlay: `/root/testing/openkore-tables-codex:/root/testing/openkore/tables`
- OpenKore root: `/root/testing/openkore`
- login account: `codexbot`
- login password: `codexbot`
- default observer map: `prontera`

## Scenario 1: Login Baseline

Purpose:

- verify OpenKore can still log in and reach map-server entry

Command:

```bash
tools/ci/openkore-smoke.sh login-baseline
```

Manual expectations:

- account server login succeeds
- character server login succeeds
- the chosen character reaches `prontera`
- nearby NPC enumeration works

Useful OpenKore checks:

- `pl`
- `nl`

## Scenario 2: Scheduler Status

Purpose:

- verify scheduler summaries expose clear state without needing raw globals
- verify controller drill-down is available from the demo NPC

Command:

```bash
tools/ci/openkore-smoke.sh scheduler-status
```

Manual path:

1. Open `[Headless Scheduler]` in Prontera.
2. Choose `Status`.
3. Choose `Controller drill-down`.
4. Inspect `HeadlessPronteraSocialController`.
5. Inspect `HeadlessAlbertaSocialController`.

Expected signals:

- scheduler cap/tick/actor cap are visible
- controller status shows active/pending/parked/unassigned counts
- controller status shows per-pool slot breakdown
- scheduler status shows the last decision reason for each controller

## Scenario 3: Prontera Repopulation

Purpose:

- verify scheduler start/stop still repopulates the Prontera pooled set cleanly

Command:

```bash
tools/ci/openkore-smoke.sh prontera-repopulate
```

Manual path:

1. Open `[Headless Scheduler]` in Prontera.
2. Choose `Start scheduler`.
3. Confirm the Prontera pool repopulates.
4. Use `pl` to confirm nearby pooled actors are visible.

Expected signals:

- `BotPc06`
- `BotPc07`
- `BotPc08`
- `BotPc09`
- `BotPc10`

## Scenario 4: Alberta Gate

Purpose:

- verify the map-demand gate still controls whether the Alberta controller runs

Command:

```bash
tools/ci/openkore-smoke.sh alberta-gate
```

Manual path:

1. Log a second observer into Alberta, or move a local observer there.
2. Open `[Headless Scheduler]` in Prontera.
3. Choose `Start scheduler`.
4. Verify `HeadlessAlbertaSocialController` transitions to active once the gate is satisfied.

Expected signals:

- Alberta remains idle while the gate is not satisfied
- Alberta becomes active when the gate threshold is met

## Scenario Notes

- These scenarios are intentionally CLI-first.
- Visual client checks are reserved for layouts or interactions that need them.
- If a scenario needs a second observer, note that in the validation log.
- If a controller menu changes, update this document and the launcher script in
  the same slice.
- Combat/status/death/respawn frontier work should use the scenario runner
  catalog in [playerbot-scenario-runner.md](/root/dev/rathena/doc/project/playerbot-scenario-runner.md)
  and `tools/ci/playerbot-scenario.sh` as the canonical runbook layer.

## Scenario 5: Guild Invite Proof

Purpose:

- prove the active headless/playerbot guild invite path end-to-end from a clean
  repo-managed restart baseline

Command:

```bash
tools/ci/playerbot-guild-smoke.sh arm
```

Manual path:

1. Run the arm command above.
2. Log in with the `codex` OpenKore profile.
3. Check the result:

```bash
tools/ci/playerbot-guild-smoke.sh check
```

Expected signals:

- the hidden guild selftest provisions a fresh guild-capable bot
- the bot spawns as a headless player
- the guild invite is accepted through the runtime hook
- the map-server log shows:
  - `playerbot_guild_selftest: ... result=1`
