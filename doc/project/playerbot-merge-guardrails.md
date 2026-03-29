# Playerbot Merge Guardrails

## Purpose

This file defines the guardrails for accepting external branch work into the
integrated playerbot baseline.

Use it when:

- deciding whether to merge a Claude/Gemini branch
- reviewing whether a contributor exceeded scope
- checking whether a branch should be corrected instead of accepted

## Non-Negotiable Rules

1. no direct contributor merges to `master`
2. no acceptance without review against current `master`
3. no shared-hotspot edits from side lanes unless explicitly assigned
4. no stale-branch assumptions
5. no runtime-truth claims that exceed what the code or query really reads

## Shared Hotspots

Treat these as guarded files:

- `src/map/script.cpp`
- `src/map/pc.cpp`
- `npc/custom/living_world/_common.txt`
- `npc/custom/playerbot/playerbot_combat_lab.txt`
- `npc/custom/playerbot/playerbot_item_lab.txt`
- `npc/custom/playerbot/playerbot_merchant_lab.txt`
- `tools/ci/playerbot-foundation-smoke.sh`

If a side lane edits one of these without explicit assignment, reject or narrow
the branch.

## Merge-Readiness Checklist

A branch is not merge-ready unless all are true:

- based on current `master`
- write scope matches assigned task
- docs match actual behavior
- validation commands are listed
- validation commands passed
- no unexplained file drift
- no stale slice-log overwrite

## Runtime-Truth Guardrail

Do not merge branches that:

- describe static config as live runtime truth
- describe dedicated probe coverage as aggregate-gate coverage
- claim a mechanic is "foundation complete" when only a lab/probe proves it

Accepted wording examples:

- `configured threshold`
- `parked supply`
- `dedicated skillunit probe`
- `aggregate gate baseline`

Rejected wording examples unless proven by runtime source:

- `current demand`
- `live scheduler demand`
- `combat gate now includes skillunit` when it does not

## Contributor Merge Model

Expected model:

- contributor works on branch
- contributor reports scope, validation, commit
- primary reviewer checks and requests fixes if needed
- primary reviewer performs the final integration decision

This is the required process, not a courtesy preference.

## Branch Rejection Triggers

Reject or return for correction when:

- branch touches forbidden hotspots
- validation is missing or weak
- output labels are misleading
- docs are stale against current `master`
- branch claims merge readiness but still fails repo-local validation
- branch creates overlap with the active primary runtime lane

## Good Branch Behavior

- narrow scope
- exact validation
- clean branch brief
- honest labels
- docs updated only where needed
- easy cherry-pick or merge

## Current Foundation-Specific Guardrail

For the remaining foundation frontier:

- the aggregate foundation smoke is the acceptance baseline
- the richer skillunit path is still a separate proof lane
- outside contributors should not unilaterally promote probe-only paths into
  aggregate acceptance

That promotion belongs to the primary runtime lane.
