# Playerbot Collaborator Brief

## Purpose

This file keeps side-lane contributors aligned with the current integrated
`master` baseline.

Use it when:

- assigning a safe parallel lane to another Codex/Kimi session
- reviewing whether a side-lane tool or doc change is mergeable
- checking whether a branch is describing live runtime truth or only static
  config state

This file is for:

- tooling lanes
- diagnostics lanes
- contract/doc refinement lanes

It is not a substitute for the main foundation docs.

## Read First

Before starting any side-lane branch, read:

- `AGENTS.md`
- `doc/project/playerbot-foundation-program.md`
- `doc/project/playerbot-foundation-priorities.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

Then check:

- `git branch --show-current`
- `git log --oneline -n 5`
- `git status --short`

For the current remaining foundation frontier, also read:

- `doc/project/playerbot-foundation-handoff.md`

Assume `master` is the only trustworthy integrated baseline unless explicitly
assigned otherwise.

## Current Foundation Reality

The project is past the early scheduler/controller demo phase.

Current integrated foundation already includes:

- structured trace events
- shared perception facade
- reservation primitives
- shared-memory and recovery audit ledgers
- transactional item/storage foundations
- broader participation hooks
- ownership/recovery audits
- unified per-bot timeline surfaces

This means:

- many older branch briefs are stale
- static config is often not the same thing as live runtime behavior
- side-lane tooling must be careful not to overstate what it is actually
  measuring

## The Most Important Rule

Do not present static configuration as live runtime truth.

Examples:

- `bot_controller_slot.min_demand_users`
  - this is a configured threshold
  - it is not automatically the current live requested actor count
- `bot_controller_policy.actor_demand`
  - this is a policy/config field
  - it is not automatically the current demanded-slot load after focus,
    posture, or intensity-lane changes
- parked/active counts in `bot_runtime_state`
  - these are useful live supply signals
  - but they do not by themselves explain why a controller wants more actors

If a tool cannot derive a live runtime number directly, label it honestly:

- `configured threshold`
- `configured slots`
- `parked supply`
- `active supply`
- `available parked supply`

Do not label it:

- `requested`
- `current demand`
- `live scheduler demand`

unless you are actually reading the live runtime source for that concept.

## Safe Side-Lane Write Scopes

Usually safe:

- `tools/ci/`
- `doc/project/`
- narrowly scoped read-only operator surfaces in `npc/custom/playerbot/*.txt`

Usually unsafe without explicit approval:

- `npc/custom/living_world/_common.txt`
- `src/map/*`
- `src/char/*`
- shared SQL schema files already owned by the primary lane

If the lane needs `_common.txt` or core runtime files, it is probably no longer
a side lane.

## Preferred Side-Lane Work

Good current side lanes:

- trace viewer / trace tooling
- reservation inspector
- scenario runner
- perception fixtures
- contract tightening / validation docs
- read-only operator diagnostics

Bad current side lanes:

- redoing early merged scheduler or provisioning work
- changing runtime semantics from a tooling branch
- adding new controller behavior while the primary lane owns runtime recovery
- assuming old branch briefs still match current `master`

## Validation Rules For Side Lanes

Every side-lane branch should prove:

1. the tooling/docs work against the current local dev DB
2. output labels match what the queries really measure
3. the worktree is clean after commit
4. the branch rebases cleanly onto current `master`

Minimum validation examples:

- `--help`
- one general query
- one focused query
- one failure/diagnostic query if relevant
- at least one command returning exit code `0` with real local data

## Review Checklist

Before a side-lane branch is called merge-ready, check:

- Is it based on current `master`?
- Does it avoid shared hotspot files?
- Does it describe static config honestly?
- Does it avoid inventing scheduler/runtime truth it does not actually read?
- Are docs aligned with the integrated baseline?
- Is slice-log content rebased cleanly?

If any of those fail, the branch is not merge-ready.

## How To Ask For Work

When assigning a branch to another session, provide:

- branch name
- allowed write scope
- source-of-truth docs
- forbidden hotspots
- exact validation commands
- explicit note about whether the lane may speak about:
  - configured state only
  - or live runtime truth

## Current Best Use Of This Brief

Use this brief together with:

- `doc/project/playerbot-foundation-handoff.md`

when assigning Claude/Gemini/Kimi-style parallel lanes while the main thread
continues the core playerbot foundation work on `master`.
