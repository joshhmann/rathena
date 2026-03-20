# Living World Script Capability Matrix

## Purpose

This document defines what the current living-world project can and cannot do
using stock rAthena scripting only.

It is the guardrail for future implementation work.

## Script-Only: Approved Now

- Town ambient NPCs with hotspot rotation
- Schedule-based visibility for town actors
- Chatter and emotion systems
- Hub merchant actors that open real NPC shops
- `marketshop` or barter-backed merchant interactions
- Mob-backed field actors with waypoint patrols
- Player-presence gating with `getmapusers`
- Mob-backed event fillers in custom scripted events
- Simple score/state tracking for event filler participation

## Script-Only: Allowed With Important Limits

- `unitwalk` chains are workable, but require `sleep2` between chained callbacks
- `setunitdata` is safe for modes, speed, HP, and stat-style tuning
- Direct ATK/MATK tuning through `setunitdata` is not a reliable project pattern
- Field actors can look active and reactive, but they do not behave like real players
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
- Field life: mob-backed patrol actors
- Merchant life: visible merchant actors plus NPC shop interfaces
- Event fill: mob-backed rival or filler actors inside custom event logic

## Disallowed Shortcuts

- Pretending a shop NPC is a real vending player
- Treating event fillers as equivalent to real player slots
- Building framework assumptions on top of future bot systems
- Introducing source edits before script-only limits are actually reached
