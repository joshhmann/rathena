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
- scenario coverage for the core status continuity matrix, including
  `status-recovery-integrity`

## Remaining Foundational Gaps

The next unresolved mechanic-participation gaps are:

1. **Broader market/session execution semantics**
   - vending, vendlist, seller-side buyingstore, buyer-side multi-item
     buyingstore negotiation, partial fill, denial continuity, and reopen flows
     are now covered
   - the remaining market gap is narrower than the original baseline note:
     - fuller Rodex receive / attachment semantics
     - any still-missing dedicated bot-NPC-shop buy/sell proof if we want that
       path explicitly named rather than inherited from generic NPC interaction
   - mail composition/business logic is still only partially first-class; the
     current baseline now proves denial during active market sessions and
     successful delivery after close, but not full receive/attachment semantics

2. **Mechanic execution semantics beyond session ownership**
   - transient mechanic/session ownership is now broadly tracked and cleaned up
   - the remaining gap is the actual business/action layer for mechanics that
     still only have open/close continuity:
     - refine
     - reform
     - enchantgrade
     - related execution/result semantics
   - the unresolved question is no longer whether those states clear cleanly; it
     is whether bots can participate through the real engine flow without ad hoc
     shims

3. **Equip / use / consume continuity beyond the current loadout baseline**
   - intended loadout reconcile and first consume/use hooks are in place
   - the remaining gap is deeper legality and continuity under more complex
     transitions:
     - interrupted item use side effects
     - stronger ownership guarantees under overlapping mechanic transitions
     - richer equipment continuity outside the current spawn/death/respawn path

4. **Broader combat-event participation**
   - the stable aggregate combat gate is green
   - richer positional-skill / persistent-skillunit participation is proven
     through the separate probe and scenario layer
   - the remaining combat gap is promotion and expansion beyond that boundary:
     - more combat-adjacent event transitions
     - repeated sequential combat/status handoffs
     - eventual promotion of richer skill-unit proof into the broader accepted
       combat frontier when stable

5. **Scenario coverage beyond the current accepted gates**
   - `mechanic-cleanup` is now runbook-backed
   - combat skillunit cleanup is now scenario-backed
   - the remaining scenario gap is broader targeted coverage for the still-open
     fronts above:
     - richer market/session continuity
     - deeper item/use/equipment continuity
     - repeated combat-event transition cases

## Priority Order For The Remaining Gap Work

Recommended order:

1. broader market/session execution semantics
2. mechanic execution semantics beyond session ownership
3. equip / use / consume continuity
4. broader combat-event participation
5. scenario coverage for the remaining open fronts

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
- the stable aggregate combat gate
- the current interrupted participation cleanup gate
- the first market/session continuity baseline for vending and buyingstore

Those are now part of the current baseline.
