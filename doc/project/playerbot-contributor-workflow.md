# Playerbot Contributor Workflow

## Purpose

This file defines the expected workflow for Claude, Gemini, and other external
contributors working on playerbot branches.

Use it when:

- assigning a new branch
- checking whether a branch proposal is safe
- reviewing whether a contributor followed the expected process

This workflow exists to reduce drift, repeated prompt repair, and accidental
runtime overlap with the primary lane.

## Core Rule

Contributors may work on branches.

Contributors do **not** self-merge their work.

Nothing is accepted until the primary reviewer has checked it against current
`master`.

## Read First

Every contributor must read:

- `AGENTS.md`
- `doc/project/playerbot-foundation-handoff.md`
- `doc/project/playerbot-collaborator-brief.md`
- `doc/project/parallel-branch-workmap.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

If the branch is docs-only, also read the relevant contract docs.

If the branch is scenario/tooling-only, also read the relevant tool/runbook
docs.

## Startup Checklist

Before any work:

1. confirm branch:
   - `git branch --show-current`
2. confirm baseline:
   - `git log --oneline -n 8`
3. confirm worktree state:
   - `git status --short`
4. confirm allowed write scope from the assigned brief

If the branch is not based on current `master`, rebase before calling it ready.

## Branch Scope Rules

Every branch should have:

- one coherent task
- explicit allowed files
- explicit forbidden files
- explicit validation commands

If a branch touches these hotspots, it is no longer a casual side lane:

- `src/map/script.cpp`
- `src/map/pc.cpp`
- `npc/custom/living_world/_common.txt`
- active selftest labs under `npc/custom/playerbot/*.txt`
- aggregate gate tooling such as `tools/ci/playerbot-foundation-smoke.sh`

Those files require explicit assignment.

## Contributor Defaults

### Good default lanes

- scenario expansion
- tooling and diagnostics
- docs/contracts
- gap audits
- runbook improvements

### Bad default lanes

- runtime semantics without explicit ownership
- changing trace meanings from docs only
- claiming live runtime truth from static config
- editing shared hotspots "just for convenience"

## Reporting Format

When returning work, report:

- what changed
- what was validated
- exact commit hash
- whether the branch is proposed as merge-ready

Do not say "ready to merge" unless:

- the branch rebases onto current `master`
- validation actually passed
- the branch stayed inside scope
- docs match the real implementation or query behavior

## Validation Requirements

## Two-Tier Foundation Gates

Foundation validation now has two standard levels:

- quick gate (every candidate branch before review-ready)
- full gate (closeout checkpoints and major merges)

Commands:

- quick gate: `bash tools/ci/playerbot-foundation-gate.sh quick`
- full gate: `bash tools/ci/playerbot-foundation-gate.sh full`

### Runtime branches

Minimum:

- `cmake --build build --target map-server -j4`
- `git diff --check`
- `bash tools/dev/playerbot-dev.sh restart`
- `bash tools/ci/playerbot-foundation-gate.sh quick`
- `bash tools/ci/playerbot-foundation-gate.sh full` (for closeout checkpoints and major merges)

### Side-lane tooling branches

Minimum:

- `--help`
- one general command
- one focused command
- clean exit codes
- clean worktree after commit
- if touching aggregate smoke/gate tooling, include `bash tools/ci/playerbot-foundation-gate.sh quick`

### Docs-only branches

Minimum:

- `git diff --check`
- contract language checked against current implementation and current docs

## Review Expectations

Primary reviewer checks:

- scope discipline
- current `master` alignment
- validation quality
- runtime-truth honesty
- doc accuracy
- non-overlap with active primary lane

If any of those fail, the branch should be revised instead of merged.

## Merge Policy

Contributors do not merge their own work.

Contributors do not push directly to `master`.

The primary reviewer:

- reviews
- requests corrections
- cherry-picks or merges intentionally
- decides final commit shape on integrated `master`

## Anti-Patterns

Avoid these:

- editing extra files "while already in there"
- using stale branch assumptions from older foundation phases
- silently broadening a branch from docs/tooling into runtime semantics
- describing probe-only features as aggregate-gate features
- saying a tool reports "live demand" when it only reads config tables

## Current Recommended Branches

As of the current foundation frontier:

- Claude:
  - `test/playerbot-scenario-expansion`
- Gemini:
  - `doc/playerbot-foundation-gap-audit`

Those branches should stay inside the scope defined in:

- `doc/project/playerbot-foundation-handoff.md`
