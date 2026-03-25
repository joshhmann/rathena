# `test/openkore-smoke-scenarios`

## Goal

Turn the current ad hoc OpenKore checks into repeatable smoke scenarios for
playerbot and scheduler slices.

## Scope

- scripted or documented CLI smoke flows
- scheduler start/stop checks
- pool repopulation checks
- later interaction checks for party/trade/follow

## Preferred Files

- `doc/project/openkore-test-harness.md`
- optional tooling under `/root/testing/openkore-control-*` or local helper scripts
- `doc/project/headless-pc-v1-slice-log.md`

## Avoid

- touching core runtime source unless a test-only hook is explicitly required
- editing `_common.txt` unless coordinated with the main controller branch

## Acceptance

- another Codex instance can run at least one reliable scheduler/playerbot smoke test from the repo instructions

## Codex Prompt

Use this branch brief as the source of truth.

Read first:

- `doc/project/parallel-branch-workmap.md`
- `doc/project/parallel-branches/test-openkore-smoke-scenarios.md`
- `doc/project/openkore-test-harness.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

Do:

- turn the current ad hoc OpenKore checks into repeatable smoke scenarios
- cover scheduler start/stop and pooled-bot repopulation first
- prefer docs and local helper tooling
- update repo-local test docs before committing

Avoid:

- core runtime changes unless a tiny test-only hook is required
- `_common.txt` edits unless coordinated with the main controller branch
