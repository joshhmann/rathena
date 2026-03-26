# Repository Workflow Guide

## Source Of Truth
Use the repo-local project docs as the authority for scope, architecture, and validation:

- `doc/project/roadmap.md`
- `doc/project/backlog.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/bot-state-schema.md`
- `doc/project/openkore-test-harness.md`
- `doc/project/parallel-branch-workmap.md`
- `doc/project/parallel-branches/*.md`

`AGENTS.md` is workflow guidance only. If it disagrees with repo-local project docs, follow the docs.

## Current Development Model
This fork is being built in dependency-correct slices, not broad “demo complete” jumps.

Project naming:
- `headless_pc` = runtime subsystem name
- `playerbot` = broader feature lane

Current workflow priorities:
- build real foundations first
- keep runtime semantics honest
- prove behavior at the right boundary
- prefer larger coherent slices when the boundary is clear
- document every non-trivial slice
- work autonomously through a milestone unless blocked by missing information or a real architectural fork
- save/push clean milestones frequently so a new convo starts from a real integrated baseline

Current integrated baseline at time of this guide:
- persistent `headless_pc` lifecycle, restore, reconcile, and visibility are already in
- scheduler, parked pools, provisioning, role/profile pool assignment, party assist, and merchant state foundations are already in
- SQL-backed controller registry and merchant control-plane hardening are already in

## Fresh Convo Startup
When starting a new conversation on this repo:

1. read the repo-local docs listed above
2. check `git status` and `git log --oneline -n 5`
3. assume `master` is the latest integrated baseline unless the user explicitly assigns a feature branch
4. inspect the latest slice in `doc/project/headless-pc-v1-slice-log.md`
5. continue from the most recent accepted foundation milestone, not from stale plans or generic contributor assumptions

Do not restart architecture from scratch when the repo already contains the answer.

## Slice Policy
Every non-trivial slice must leave behind:

- working code
- repo-local documentation
- validation notes
- SQL artifacts if DB state/schema changed

Required slice steps:
1. understand the current repo-local design docs
2. implement the slice end-to-end
3. validate it
4. update slice docs
5. commit focused changes
6. push the branch or `master` when the slice is accepted

Do not present placeholder state flips, partial behavior, or unproven demos as complete features.

## Validation Policy
Validation is mandatory.

Minimum bar for non-trivial slices:
- rebuild if C/C++ changed
- restart services if runtime paths changed
- check server logs for startup/runtime regressions
- run a smoke test

Testing order:
- OpenKore CLI first when it is enough
- desktop client when the slice is visual, timing-sensitive, or interaction-heavy

When DB changes are involved:
- update `sql-files/main.sql`
- add a checked-in upgrade under `sql-files/upgrades/`
- mention the SQL artifact in the slice docs

## Branch And Parallel Work Policy
Prefer branch-first work for playerbot development.

Use:
- `master` as the integrated baseline
- focused feature/test/docs branches for parallel slices
- repo-local branch briefs in `doc/project/parallel-branches/`

Parallel work is encouraged, but only with disjoint write scopes.

Safe parallel lanes:
- source/runtime lane: `src/map/*`, `src/char/*`
- controller-kit lane: `npc/custom/living_world/_common.txt`
- controller-definition lane: `npc/custom/playerbot/*.txt`
- config/data lane: `npc/custom/playerbot/headless_pc_config.txt`, SQL/config/docs
- validation lane: OpenKore docs/tooling

Avoid parallel overlap on:
- `npc/custom/living_world/_common.txt`
- shared runtime files in `src/map/*` and `src/char/*`
- the same SQL schema/upgrade files

If a branch brief exists, stay inside its owned or preferred files.

Main-thread role in parallel work:
- review and integrate
- keep shared hotspots coherent
- reject parallel drift instead of silently merging it

## Coding And Content Rules
Follow `.editorconfig`.

General rules:
- keep changes ASCII unless the file already requires otherwise
- use `apply_patch` for manual file edits
- do not revert unrelated user changes
- do not use destructive git commands
- keep commits focused and imperative

For scripts:
- keep scripts procedural
- `select` / `switch` are fine for orchestration
- do not force fake OOP patterns into rAthena script
- put lifecycle/state-machine complexity in C++ helpers or explicit script helpers

For playerbot/living-world work:
- persistent identities are not disposable actors
- parking/offline is preferred over deletion
- controllers should claim ownership and use owned mutation APIs when available

## Repo Layout
- `src/` = core server/runtime code
- `conf/` = upstream-like config
- `db/` = YAML game data
- `sql-files/` = schema + upgrades
- `npc/custom/living_world/` = shared living-world helpers and ambience
- `npc/custom/playerbot/` = headless/playerbot labs, controllers, scheduler, provisioning
- `doc/project/` = architecture, slice logs, edge cases, branch briefs, test notes
- `tools/ci/` = local helper tooling

## Canonical Commands
Run from repo root unless noted otherwise.

- `bash /root/setup_dev.sh build`
- `bash /root/setup_dev.sh restart`
- `bash tools/ci/sql.sh`
- `/root/.codex/skills/rathena-playerbot-dev/scripts/openkore-login.sh`

Important note:
- do not blindly trust `bash tools/ci/npc.sh` to regenerate `npc/scripts_custom.conf` during playerbot work; verify the diff before keeping it

## What To Report
When finishing a milestone or slice, report:
- what changed
- what was validated
- any assumptions made
- anything that still needs input
