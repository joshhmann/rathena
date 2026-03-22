# Living World Framework Conventions

## Purpose

The living-world framework exists to keep town, field, merchant, and event
filler scripts reusable and consistent.

## Framework Layers

- `_common.txt`
  - shared helper functions
  - schedule checks
  - timer staggering
  - actor activation helpers
- town controllers
  - visible NPC ambience
- merchant controllers
  - visible merchant actors with shop interfaces
- field controllers
  - pseudo-player or other field-actor controllers
- event filler controllers
  - scripted participants with map-specific presentation
- `hub_services.txt`
  - separate convenience layer, not part of actor behavior logic

## Controller Rules

- one controller per map or proof system
- one refresh timer policy per controller
- stagger long-running timers on init
- keep visible actor names globally unique
- keep schedule checks and activation logic centralized

## Actor Classes

### Town Actors

- visible NPCs
- hotspot rotation
- optional chatter/emotes
- no combat behavior

### Merchant Actors

- visible NPCs
- schedule or hotspot shifts
- open a real NPC shop, marketshop, or barter interface
- never pretend to be real vending players

### Field Actors

- preferably fakeplayer-backed walkers when player-like traffic is the goal
- script-controlled waypoint routes via `unitwalk`
- use `sleep2` between chained route callbacks
- gated by map population when practical

### Event Fillers

- mob-backed or fakeplayer-backed scripted participants
- role-based state tracked by the event controller
- custom event logic only
- not a substitute for real player slots

## Naming Rules

- visible actor names must be unique across the full living-world tree
- controller names should be prefixed by subsystem and map
- shop identifiers should be prefixed by map and role

## Scope Rules

- use the framework for behavior systems
- keep hub-service duplication separate
- keep coordinate polish optional unless placement is broken
- keep fakeplayer usage selective and script-orchestrated
