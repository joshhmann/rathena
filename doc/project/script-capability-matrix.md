# Living World Script Capability Matrix

## Purpose

This document defines what the current living-world project can and cannot do
using stock rAthena scripting plus the currently approved selective
source-backed fakeplayer primitive.

It is the guardrail for future implementation work.

## Script-Only: Approved Now

- Town ambient NPCs with hotspot rotation
- Schedule-based visibility for town actors
- Chatter and emotion systems
- Hub merchant actors that open real NPC shops
- `marketshop` or barter-backed merchant interactions
- Player-presence gating with `getmapusers`
- Mob-backed event fillers in custom scripted events
- Simple score/state tracking for event filler participation

## Selective Source-Assisted: Approved Now

- `fakeplayer()` for pseudo-player presentation and script control
- fakeplayer-backed field walkers such as guards, travelers, and couriers
- script-driven routes, respawn, chatter, and presence gating for pseudo-players
- script-owned fakeplayer lifecycle through shared living-world helpers

## Script-Only: Allowed With Important Limits

- `unitwalk` chains are workable, but require `sleep2` between chained callbacks
- `setunitdata` is safe for modes, speed, HP, and stat-style tuning
- Direct ATK/MATK tuning through `setunitdata` is not a reliable project pattern
- Script-only field actors can look active, but do not present convincingly enough for all road-traffic use cases
- Event fillers can participate in scripted logic, but do not satisfy real player semantics
- Semi-functional merchants can feel alive, but they are not true vending players

## Not Script-Only For This Phase

- Real vending-player emulation
- Real trade/chat/player packet behavior
- Fake PCs that count as actual players in player-gated systems
- True player-bot systems
- Deep autonomous behavior beyond controlled scripted patterns
- Source-level AI, pathfinding, or fake-player packet handling

## Approved Implementation Patterns

- Town life: visible NPC actors
- Field life: fakeplayer-backed walkers when player-like presentation matters
- Merchant life: visible merchant actors plus NPC shop interfaces
- Event fill: mob-backed or fakeplayer-backed filler actors inside custom event logic

## Disallowed Shortcuts

- Pretending a shop NPC is a real vending player
- Treating event fillers as equivalent to real player slots
- Building framework assumptions on top of future bot systems
- Treating selective fakeplayer support as equivalent to true bot systems
