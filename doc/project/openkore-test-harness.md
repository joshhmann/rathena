# OpenKore Test Harness

## Purpose

Use OpenKore as a CLI-only smoke-test client for the live rAthena fork.

This is a testing tool, not part of the server-owned bot architecture.

Use cases:

- account login regression checks
- character select regression checks
- map-server entry checks
- NPC visibility and simple interaction checks
- later, party/invite/trade smoke tests against real protocol traffic

Non-goals:

- do not treat OpenKore as the implementation path for `headless_pc`
- do not use OpenKore as the long-term playerbot subsystem
- do not make the server architecture depend on OpenKore

## Local Layout

Working tree:

- `/root/testing/openkore`

Custom control/profile overlay:

- `/root/testing/openkore-control-codex`
- `/root/testing/openkore-tables-codex/servers.txt`

Custom field pack for this server:

- `/root/testing/openkore/fields/local20250604`

Generated field files currently in use:

- `/root/testing/openkore/fields/local20250604/prontera.fld2`
- `/root/testing/openkore/fields/local20250604/prt_fild08.fld2`

## Current Working Baseline

Validated date:

- `2026-03-22`

Server side:

- rAthena `PACKETVER 20250604`
- login `192.168.0.132:6900`
- char `192.168.0.132:6121`
- map `192.168.0.132:5121`

OpenKore profile:

- account: `testgm`
- character slot: `0`
- `XKore 0`
- `portalCompile -1`
- `portalRecord 0`

Current server profile values:

- `master Local rAthena 20250604`
- `version 55`
- `master_version 1`
- `serverType laRO`
- `charBlockSize 247`
- `pinCode 0`
- `fields_folder /root/testing/openkore/fields/local20250604`

Status of this baseline:

- account login works
- char select works
- map connect works
- Prontera map load works
- nearby NPC enumeration works

## Known Warnings

These are present but non-fatal in the current baseline:

- `Packet Tokenizer: Unknown switch: 001E`
- `Unknown Config Type: 5, Flag: 0`

Meaning:

- the current OpenKore packet profile is close enough to operate, but not fully tuned
- field data was the blocking issue; packet cleanup is now follow-up work

## Field Data Notes

OpenKore expects `.fld2` or `.fld2.gz` files.

The local converter path is:

- `/root/testing/openkore/fields/tools/gat_to_fld2.pl`

Input required per map:

- `<map>.gat`
- `<map>.rsw`

Example conversion flow:

1. copy `prontera.gat` and `prontera.rsw` into a temp working directory
2. run `perl ../tools/gat_to_fld2.pl`
3. copy resulting `prontera.fld2` into the active field pack

## Launch Command

```bash
perl /root/testing/openkore/openkore.pl \
  --control=/root/testing/openkore-control-codex \
  --tables=/root/testing/openkore-tables-codex:/root/testing/openkore/tables \
  --interface=Console \
  --ai=off
```

## Next Improvements

- replace the borrowed `laRO` packet profile with a better-matched private-server profile
- generate or import additional `.fld2` files for the maps we care about testing
- use [openkore-smoke-scenarios.md](/root/dev/rathena/doc/project/openkore-smoke-scenarios.md) as the canonical repeatable scenario list
- use `tools/ci/openkore-smoke.sh` as the local scenario launcher/checklist helper
- use `tools/ci/playerbot-guild-smoke.sh` to arm/check the hidden guild selftest from a clean repo-managed restart path
- use [playerbot-scenario-runner.md](/root/dev/rathena/doc/project/playerbot-scenario-runner.md)
  and `tools/ci/playerbot-scenario.sh` as the combat/status/death/respawn
  frontier runbook
- later, add scripted interaction checks for key Prontera NPCs
