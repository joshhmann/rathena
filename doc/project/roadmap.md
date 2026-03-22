# Living World Roadmap

## Planning Rule

World atmosphere comes before automation.

For now, the project should prioritize:

1. stable upstream-compatible server behavior
2. believable town and field atmosphere
3. reusable script systems
4. selective source-backed pseudo-player actors where presentation matters
5. content curation from existing rAthena assets
6. only later, deeper simulation or AI-driven behavior

ML, LLM, and external agent control are explicitly backburner items until the
server already feels alive through normal rAthena systems.

## Milestone 0: Working Baseline

Status: complete

Definition of done:

- working Renewal server in the dev LXC
- `PACKETVER 20250604`
- desktop client login confirmed
- fork and upstream workflow established
- repo-local project docs created

## Milestone 1: Prontera Feels Alive

Status: complete

Goals:

- make Prontera feel populated within the first minute of player arrival
- add reasons for players to linger in town
- avoid source changes

Scope:

- scripted ambient actors in Prontera
- limited ambient chatter and emotes
- timed hotspot rotation
- selected service NPCs from `npc/custom/`

Exit criteria:

- no script errors on startup
- no blocked warps, guides, or service counters
- visible ambient activity around core Prontera zones
- Prontera established as the main convenience hub with intentional service coverage

## Milestone 2: Reusable Town System

Status: complete

Goals:

- convert the Prontera pattern into a reusable town-population template
- expand the pattern across the town network

Scope:

- common controller pattern for town ambience
- role-based hotspot sets per city
- city-specific dialogue pools
- hub-service parity for supported towns
- rollout through classic, flavor, frontier, and newer hub maps

Exit criteria:

- town rollout implemented through Waves 1-5
- no parser/runtime errors from the living-world layer
- shared conventions documented in `doc/project/`

Implementation note:

- current town layouts are accepted as the functional baseline
- service clusters are intentionally simple for now
- map-aware coordinate polish is deferred to a later pass

## Milestone 3: Living World Framework And Proofs

Status: complete

Goals:

- define the script-only limits of the project clearly
- replace one-off living-world patterns with reusable framework conventions
- support town actors, merchant actors, field actors, and event fillers through one shared framework layer

Scope:

- repo-local capability matrix and simulation-lane docs
- shared framework helpers and controller conventions
- one merchant proof slice
- one event filler proof slice

Exit criteria:

- script-only boundaries are documented clearly
- new framework helpers are in active use
- one semi-functional merchant pocket works
- one event filler prototype works

Implementation note:

- this milestone started as a script-only framework pass
- it now also includes the first approved source-backed primitive: `fakeplayer()`
- scripts remain the orchestration layer even when source-backed actors are used

## Milestone 4: Fakeplayer-Backed Overworld Activity

Status: complete

Goals:

- make early leveling routes feel observed and used
- create the illusion of adventurer traffic outside towns
- validate pseudo-player walkers as the field-actor foundation

Scope:

- one field map near a starter city
- fakeplayer-backed guards, travelers, and courier traffic
- script-controlled routes, respawn, and presence gating
- event-driven chatter rather than heavy AI

Exit criteria:

- one field map feels noticeably less empty
- actors read as player-like, not mob-like
- fakeplayer walkers remain a presentation layer, not true bots
- performance remains normal

Implementation note:

- `prt_fild08` is the accepted proof map for this milestone
- the current presentation uses conservative client-safe fakeplayer appearances
- further field rollout is optional polish, not a gating requirement for subsystem work

## Milestone 5: Broader Pseudo-Player Systems

Status: complete for ambiance scope

Goals:

- selectively extend fakeplayer-backed actors into other atmospheric roles
- improve merchant, event, and town presentation where NPCs are not convincing enough

Scope:

- selective town walkers
- merchant stand-ins where useful
- event participants using pseudo-player visuals
- first persistent bot-state schema

Constraints:

- towns and services remain primarily NPC-driven by default
- no promise of true player semantics
- keep fakeplayer usage selective, not universal

Implementation note:

- the next design freeze inside this milestone is `headless_pc_v1` Phase 0
- that phase defines the first real PC-backed bot target
- reference: [headless-pc-v1-phase0.md](/root/dev/rathena/doc/project/headless-pc-v1-phase0.md)
- for the atmosphere lane, this milestone is considered complete once:
  - town ambience is fakeplayer-backed where appropriate
  - one field slice is fakeplayer-backed
  - merchant/event proofs exist
  - bot-state schema is documented
- true party, merchant, and player semantics are subsystem work, not remaining ambiance work

## Milestone 6: External AI Bridge

Status: deferred

Goals:

- let external systems influence the world without owning core gameplay truth

Scope:

- read-only or advisory bridge first
- dialogue generation or schedule suggestion
- later, action proposals for controlled actor systems

Constraints:

- rAthena remains the authority
- the server must still be playable if the bridge is offline
- no mandatory ML or LLM dependency for core gameplay
