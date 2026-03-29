# Playerbot Mechanic Participation Gap Audit

This note isolates the remaining mechanic-participation gaps after the current
combat, loadout, and status continuity baseline is green.

It is a companion to:

- `doc/project/playerbot-foundation-program.md`
- `doc/project/playerbot-combat-frontier-contract.md`
- `doc/project/playerbot-status-continuity-contract.md`
- `doc/project/playerbot-scenario-runner.md`
- `doc/project/playerbot-failure-recovery.md`

## What Is Already Covered

The current baseline already has:

- combat intent and death / respawn participation hooks
- status continuity rules across death, respawn, map change, and recovery
- intended loadout continuity for the first transactional item slice
- trace and recovery-audit surfaces for combat, status, reservation, and
  participation cleanup
- repo-local smoke coverage for the integrated baseline

## Remaining Foundational Gaps

The next unresolved mechanic-participation gaps are:

1. **Map-change / warp continuity for active participation**
   - bots should not retain stale claims, targets, or session ownership after a
     handoff or warp
   - map-change cleanup still needs a fuller contract for every contested
     mechanic, not just the first combat/status paths

2. **Trade / storage / dialog interruption under combat pressure**
   - the current hooks exist, but the cleanup rules still need broader
     mechanical coverage when death, respawn, or warp interrupts an active
     session
   - the remaining gap is not "can we close the session?"
     - it is "does every overlapping mechanic release the right authority and
       leave one clear recovery source?"

3. **Equip / use / consume continuity beyond the first loadout baseline**
   - intended loadout reconcile is in place
   - item-use and consume side effects still need a clearer continuity model
     when a bot dies or respawns mid-flow
   - the next gap is legal continuity, not equipment optimization

4. **Broader combat-event participation**
   - legal attack/death/respawn participation exists
   - richer combat-adjacent transitions still need to be formalized, including
     what happens when combat interrupts other player-system activity

5. **Scenario coverage for mechanic cleanup**
   - the current scenario runner covers the first legal combat/status/loadout
     cases
   - the unresolved gap is a dedicated mechanic-cleanup scenario matrix for:
     - death during dialog
     - death during trade
     - death during storage
     - warp during active participation
     - respawn after interrupted mechanic state

## Priority Order For The Remaining Gap Work

Recommended order:

1. map-change / warp cleanup
2. trade / storage / dialog interruption rules
3. equip / use / consume continuity
4. broader combat-event participation
5. scenario coverage for the cleanup matrix

That order follows the current authority model:

- live actor state first
- reservation/session authority second
- persisted recovery audit third
- runtime cache only as a follower

## What This Audit Deliberately Does Not Include

This note does not reopen the already-covered foundation slices:

- observability and replayability
- shared perception / world-query facade
- reservation primitives
- status continuity baseline
- intended loadout continuity baseline
- the first legal combat hooks

Those are now part of the current baseline.
