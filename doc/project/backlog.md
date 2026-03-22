# Living World Backlog

## Current Focus

Make the server feel alive using rAthena-first patterns, then selective
source-backed pseudo-player actors where NPC and mob tricks are not convincing
enough. Avoid deep source divergence.

## Immediate Tasks

- freeze `headless_pc_v1` Phase 0 so the first PC-backed bot implementation stays narrow
- translate the Phase 0 design freeze into concrete source tasks for the first inert headless PC
- document each `headless_pc_v1` implementation slice as it lands
- keep the OpenKore smoke-test harness working as packet and map coverage evolve

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
- bot-style autonomous actors
- ML-driven behavior systems
- LLM-generated dialogue systems
- external AI bridge or MCP control

These are not rejected. They are deferred until the script/content layer is
clearly worth extending.
