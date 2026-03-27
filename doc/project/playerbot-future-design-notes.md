# Playerbot Future Design Notes

## Purpose

Capture higher-level playerbot ideas that align with the current foundation but
are not yet accepted as active implementation commitments.

This document is intentionally future-facing.

Use it to:

- preserve strong design ideas from external brainstorm notes
- keep later-phase goals aligned with the current `headless_pc` / `playerbot`
  architecture
- separate:
  - implemented foundation
  - near-term planned subsystem work
  - later speculative behavior ideas

This file is not the source of truth for current runtime behavior.

Current runtime/source-of-truth docs remain:

- `doc/project/roadmap.md`
- `doc/project/backlog.md`
- `doc/project/pseudo-player-architecture.md`
- `doc/project/bot-state-schema.md`
- `doc/project/headless-pc-v1-slice-log.md`
- `doc/project/headless-pc-edge-cases.md`

## What Already Aligns With The Current Foundation

These ideas match the direction already implemented in this fork:

- build systems first, behavior second
- treat bots as persistent recurring identities, not disposable props
- use the same game systems players use where possible
- keep runtime capabilities separate from higher-level behaviors
- prefer data-backed scheduling, pooling, and policy over hardcoded one-off
  scripts
- use deterministic game logic for core decisions
- treat richer dialogue generation as optional flavor, not core control logic
- make the world feel populated through recurring familiar characters
- let guild, party, merchant, and scheduler state feed visible world behavior

## Current Foundation Boundary

The project is currently building and extending the lower layers that later
behavior systems need:

- persistent identity
- runtime body/lifecycle
- restore/reconcile/durability
- movement and routes
- ownership
- scheduler and parked/offline lifecycle
- provisioning
- SQL-backed controller registry
- SQL-backed controller content and route data
- role/profile-aware pool assignment
- party invite and assist foundations
- merchant state and merchant runtime surface
- guild state, invite/join foundation, and guild-aware demand/runtime ledgers
- economy and guild demand signals that drive controller visibility

This means the current milestone is:

- make bots able to exist as real system participants
- make controllers and scheduler react to real world/system pressure
- reduce hardcoded script glue into reusable data-backed control

It is not yet:

- full autonomous social AI
- full combat AI
- full market simulation
- full guild politics/event AI

## Accepted Long-Term Direction

The long-term direction is still:

- believable recurring pseudo-players
- not disposable scenery
- not raw fake chatter only
- not full black-box AI first

Desired later capabilities remain in scope:

- richer routines and daily presence patterns
- personality-aware behavior
- affinity and familiarity with real players
- more complete party participation
- guild participation beyond invite/join
- economy participation beyond a static merchant surface
- event and travel behaviors
- later combat/progression systems

## Design Rules For Future Behavior

When deeper behavior work begins, preserve these rules:

### 1. Capability First

Do not implement a behavior layer that depends on fake semantics.

If a bot needs to:

- move
- party
- vend
- join a guild
- react to demand

then the underlying capability and runtime/state ownership should exist first.

### 2. Game Logic Before ML

Core control logic should remain:

- state machines
- weighted choices
- deterministic policy
- context modifiers
- explicit runtime state

Possible later enhancement:

- dialogue-generation assistance
- content-authoring support
- non-authoritative flavor generation

Not recommended for the core runtime:

- opaque ML-driven decision authority over core bot state

### 3. Persistent Identity Over Disposable Presence

Bots should remain recurring characters.

That means:

- same names return
- same roles can recur
- same guild/merchant/social identity can persist
- offline/parked is better than delete/recreate

### 4. Scheduler Owns Presence

Behavior should not bypass the scheduler/control plane.

Presence should stay driven by:

- map demand
- routine windows
- guild/economy/party activity
- role/profile eligibility
- pool supply

### 5. Behavior Families Should Stay Modular

Future behavior families should layer on top of the same foundation:

- social/town
- merchant/economy
- party/support
- guild
- travel/courier
- event participation
- combat

Each family should reuse:

- provisioning
- pools
- controller ownership
- scheduler policy
- persistent state

## Future Behavior Themes

These are good candidates for later implementation, but they are still design
themes rather than active commitments.

### Personality

Possible future shape:

- archetype tags
- weighted response styles
- different comfort with risk, social interaction, routine stability, and
  chatter

Best fit with current system:

- likely as profile/personality tags in persistent state plus controller logic
  modifiers

### Affinity / Familiarity

Possible future shape:

- bots remember repeat players
- positive or negative familiarity shifts greetings and interaction likelihood

Best fit with current system:

- later persistent social-memory tables keyed by bot/player identity

### Social Recurrence

Possible future shape:

- stable login windows
- recurring map presence
- “I keep seeing this same character around town”

Best fit with current system:

- scheduler, routine groups, and parked/offline lifecycle already point in this
  direction

### Economy Participation

Possible future shape:

- specialized merchant bots
- trader/courier pressure
- inventory and stock depth mattering over time
- eventually richer market-response logic

Important boundary:

- not every persistent bot should become a merchant
- merchant capability should stay role- and policy-driven

### Guild Participation

Possible future shape:

- recurring guild members
- guild quarter presence
- guild-system-responsive activity
- later guild chat, notice, roster, storage, and event behaviors

Important boundary:

- current work already supports guild state and guild-aware demand
- future guild behavior should build on that, not replace it with isolated
  script gimmicks

### Party Participation

Possible future shape:

- richer join/decline rules
- follow/assist role behavior
- eventually role-aware support/combat routines

Important boundary:

- party semantics should continue to reuse real server systems

## Not Yet Committed

These ideas are valid to keep in mind, but they should stay out of the active
implementation lane until the foundation explicitly calls for them:

- gossip networks
- bot-generated drama
- loan systems or bot-to-bot finance
- large-scale emergent economy modeling
- dynamic quest authorship by bots
- fully autonomous guild politics
- full combat AI planning
- heavy LLM-driven interaction loops

These are not rejected.

They are simply later than the current control-plane/runtime milestone.

## Practical Rule For New Design Notes

When a future idea is written down, classify it first:

- implemented now
- near-term foundation target
- later behavior-layer target
- speculative future idea

That prevents brainstorm docs from drifting into “already built” architecture.

## Current Read

The external brainstorm notes align with the repo direction when read as:

- future-phase design inspiration
- not current implementation status
- not immediate roadmap commitments

That is the right way to carry them forward.
