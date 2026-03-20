# Living World Roadmap

## Planning Rule

World atmosphere comes before automation.

For now, the project should prioritize:

1. stable upstream-compatible server behavior
2. believable town and field atmosphere
3. reusable script systems
4. content curation from existing rAthena assets
5. only later, deeper simulation or AI-driven behavior

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

Status: in progress

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
- at least two existing custom service NPCs evaluated and intentionally kept or removed

## Milestone 2: Reusable Town System

Status: planned

Goals:

- convert the Prontera pattern into a reusable town-population template
- expand to one second city

Recommended target towns:

- Izlude
- Alberta
- Payon

Scope:

- common controller pattern for town ambience
- role-based hotspot sets per city
- city-specific dialogue pools
- one city chosen for the second implementation

Exit criteria:

- second town implemented with the same architecture
- no copy-paste-only script sprawl
- shared conventions documented in `doc/project/`

## Milestone 3: Overworld Activity

Status: planned

Goals:

- make early leveling routes feel observed and used
- create the illusion of adventurer traffic outside towns

Scope:

- one field map near a starter city
- patrol-like or presence-rotation actors
- optional guard or traveler staging points
- event-driven chatter rather than heavy AI

Exit criteria:

- one field map feels noticeably less empty
- no combat/system exploits introduced
- performance remains normal

## Milestone 4: Controlled Simulation

Status: planned

Goals:

- make the world feel reactive, not just decorated

Scope:

- town schedule variants
- weekend or event density changes
- player-presence-based activation
- lightweight helper or companion prototype

Exit criteria:

- at least one time-based or population-based world-state change
- simulation still runs fully inside normal rAthena server behavior

## Milestone 5: External AI Bridge

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
