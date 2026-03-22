# Pseudo-Player Research Notes

## Purpose

Summarize outside references and implementation patterns relevant to
pseudo-players, playerbots, and fake-player presentation, then translate them
into practical guidance for this fork.

## Key Takeaways

### 1. AzerothCore Playerbots are a branch-level system, not a script feature

Reference:

- https://github.com/mod-playerbots/mod-playerbots

Relevant takeaway:

- AzerothCore playerbots rely on a custom core branch plus a dedicated module,
  not a lightweight patch.
- The useful lesson is architectural: separate bot bodies, logic, config, and
  world integration into explicit subsystems.

Implication for this project:

- if rAthena pseudo-players are pursued seriously, they should become a
  dedicated subsystem with their own state and controller layers
- they should not be treated as a few scattered script hacks

### 2. rAthena fake-player mods prove the body/presentation primitive is viable

Reference:

- https://rathena.org/board/topic/120751-release-script-command-fake-player/

Relevant takeaway:

- the community has already proven that a source-backed fake-player body can be
  spawned and controlled from script
- the community also ran into immediate edge cases like:
  - how to clear spawned fake players
  - headgear display quirks
  - whisper list / `/w` visibility questions
  - rendering issues when multiple fake players are spawned

Implication for this project:

- `fakeplayer()` is a good body primitive
- the subsystem needs explicit lifecycle, appearance, and visibility rules
- social and chat semantics should not be assumed just because the body looks
  like a player

### 3. Expanded AI is useful as a brain, not as a playerbot system

Reference:

- https://rathena.org/board/topic/130266-mod-expanded-ai-conditions/

Relevant takeaway:

- the expanded condition system is valuable because it improves decision logic
- it does not solve persistence, commerce, party semantics, or fake-player
  session behavior

Implication for this project:

- use expanded AI ideas later for combat and behavior decisions
- do not confuse AI condition evaluation with pseudo-player implementation

### 4. Keep the cheapest convincing tool per role

Observed pattern across the research:

- full bot systems are expensive and invasive
- visual fake players are much cheaper
- many “alive world” goals do not need true player semantics

Project guidance:

- towns/hubs: prefer NPCs and anchored service actors first
- roads/fields: use fakeplayer walkers where player-like motion matters
- merchants: start with fakeplayer-fronted NPC commerce before any deeper
  vending-like work
- party/combat semantics: defer until bot state and controller layers exist

## Recommended Best Practices

### Use subsystem boundaries from day one

- body layer
- controller layer
- bot state layer
- behavior layer
- interaction layer
- commerce layer
- semantics layer

This reduces the risk of building an impressive demo that cannot evolve into a
maintainable playerbot system.

### Keep identity separate from spawned bodies

- a bot needs a stable identity independent from its current spawned GID
- spawned fakeplayer instances should be treated as bodies attached to that
  identity

This is required for persistence, party membership, and commerce later.

### Treat chat, whisper, and social visibility as explicit features

Do not assume pseudo-players can or should automatically appear in:

- whisper lists
- player search
- FluxCP/player web views
- party/member tools

These should be implemented deliberately per system.

### Build commerce as a separate subsystem

The bot decision engine may answer:

- should the merchant be active now
- where should the merchant stand
- should the merchant restock or close shop

But it should not own:

- inventory persistence
- stock pricing
- vending-like session semantics
- player trade behavior

### Build party support only after bot state exists

Party-capable pseudo-players need:

- stable identity
- invite handling
- acceptance/decline rules
- role preferences
- persistent association beyond one spawned body

Without that, party support becomes brittle quickly.

## What To Avoid

- treating fakeplayer visuals as equivalent to real `BL_PC` semantics
- building all pseudo-player logic directly into the spawn primitive
- importing broad AI-world forks wholesale
- importing large combat forks before narrowing the intended integration
- attaching inventory/party/combat behavior directly to temporary GIDs

## Current Recommendation

Near-term:

- keep using fakeplayer for selective ambiance and field traffic
- validate the field pattern first

Next design step:

- define a persistent bot-state model

Later:

- evaluate a narrow `expanded_ai` core import for combat decision logic

