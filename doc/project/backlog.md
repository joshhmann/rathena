# Living World Backlog

## Current Focus

Make the server feel alive using rAthena-first patterns, then selective
source-backed pseudo-player actors where NPC and mob tricks are not convincing
enough. Avoid deep source divergence.

Execution preference:

- bias toward larger coherent subsystem slices once the foundation is clear
- use parallel sidecar work where it helps close a slice faster without
  weakening validation
- for playerbot work, prefer branch-owned parallel lanes plus sub-agents when
  scopes are disjoint enough to review cleanly

## Immediate Tasks

- freeze `headless_pc_v1` Phase 0 so the first PC-backed bot implementation stays narrow
- translate the Phase 0 design freeze into concrete source tasks for the first inert headless PC
- document each `headless_pc_v1` implementation slice as it lands
- keep DB-affecting slices paired with checked-in SQL artifacts under `sql-files/`
- keep the OpenKore smoke-test harness working as packet and map coverage evolve
- build the first shared playerbot scheduler layer above the current controller kit
- add despawn grace windows so controller-gated actors do not pop instantly when maps empty
- define a persistent routine-pool policy for recurring daily-life actors
- design connected-map traversal for selected world actors rather than only single-map loops
- define parked/offline lifecycle rules for recurring provisioned bots so party
  and progression systems can rely on continuity
- drive playerbot work from the phased execution guide:
  - `doc/project/playerbot-execution-plan.md`
- keep future behavior ideas aligned with the implemented foundation:
  - `doc/project/playerbot-future-design-notes.md`
- drive the remaining foundation phase from:
  - `doc/project/playerbot-foundation-priorities.md`
  - `doc/project/playerbot-foundation-program.md`
- keep the branch-scoped parallel work briefs current:
  - `doc/project/parallel-branch-workmap.md`
- keep parallel work inside approved write-scope lanes instead of splitting
  across shared hotspots like `_common.txt` and `src/map/chrif.cpp`

## Existing rAthena Custom NPCs Worth Evaluating

These are useful because they already exist in the tree and can be enabled or
adapted without committing to heavy engine work.

### Strong candidates for a living-world server

- `npc/custom/etc/bank.txt`
  - Adds an economic/social reason to stop in town.
- `npc/custom/quests/questboard.txt`
  - Gives players a town hub objective loop.
- `npc/custom/quests/hunting_missions.txt`
  - Good candidate for making towns feed players into nearby field content.
- `npc/custom/quests/quest_shop.txt`
  - Useful later if the quest economy becomes a real progression track.
- `npc/custom/stylist.txt`
  - Strong for social-town energy if used sparingly.
- `npc/custom/etc/marriage.txt`
  - Flavor-rich, but only worth enabling if the social layer becomes active.

### Use cautiously

- `npc/custom/warper.txt`
  - Convenient, but can kill world scale and travel texture if enabled too early.
- `npc/custom/healer.txt`
  - Useful for testing, but easy to make the server feel cheap.
- `npc/custom/jobmaster.txt`
  - Great for dev/testing, poor fit for a grounded world baseline.
- `npc/custom/resetnpc.txt`
  - Convenience-heavy; probably better for staff-only or later use.
- `npc/custom/platinum_skills.txt`
  - Similar concern to `jobmaster.txt`.

### Probably later or out of scope for now

- mini-games and arena scripts
- battleground scripts
- MVP room and ladder scripts
- economy/game-of-chance scripts like lottery or stock market

## Content Expansion Order

1. town/hub baseline complete
2. framework and capability pass complete
3. merchant and event proof slices complete
4. one nearby fakeplayer-backed field map
5. selective pseudo-player expansion where presentation matters

## Codebase Rules

- put living-world scripts under `npc/custom/living_world/`
- wire them through `npc/scripts_custom.conf`
- prefer additive scripts over edits to official NPC files
- avoid source edits unless script limitations are proven

## Deferred Work

- map-aware coordinate polish for towns and hub-service clusters
- more hand-authored landmark-based ambient placements
- additional fakeplayer field slices beyond `prt_fild08`
- more pseudo-player merchant/event presentation polish
- fully generalized pseudo-player actor system across all maps
- PC-backed bot controller work after `headless_pc_v1` Phase 0
- larger-scale distributed playerbot load testing after the scheduler layer exists
- bot-style autonomous actors
- ML-driven behavior systems
- LLM-generated dialogue systems
- external AI bridge or MCP control

## Remaining Playerbot Foundation

The current preferred order is:

1. observability and replayability
2. shared perception / world-query facade
3. reservation and contention primitives
4. explicit memory/state boundaries
5. failure-recovery semantics
6. transactional inventory / equipment / storage foundation
7. broader player-system participation hooks

Execution model:

- use one canonical primary lane
- allow only safe side lanes for docs, tooling, and disjoint support work

These are not rejected. They are deferred until the script/content layer is
clearly worth extending.
