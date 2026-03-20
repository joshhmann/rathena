# rAthena Living World Project Charter

## Purpose

Build a low-population Ragnarok Online server on top of rAthena that still
feels active, social, and worth exploring. The server should feel alive through
server-owned simulation, not through cheating clients or external farming bots.

## Primary Goal

Create a maintainable development workflow that lets us:

- stay close to upstream rAthena
- keep custom work isolated in our fork
- test changes quickly inside this LXC dev container
- eventually add believable ambient population systems

## Immediate Objectives

- establish this LXC as the main development container
- keep the editable source tree in `/root/dev/rathena`
- keep local machine config out of tracked rAthena files
- define a single client target for first-login testing
- confirm the server builds, boots, and accepts a desktop client login

## Product Direction

The project is aiming for a "living world" private server with:

- ambient town population
- fake social activity and map presence
- merchant and vending atmosphere
- basic companion or helper behavior later
- scripted or source-backed world activity systems later

## Non-Goals Right Now

- no production deployment work yet
- no full web control panel
- no multi-client bot farm setup
- no premature source-heavy AI work before the baseline server is stable

## Development Principles

- upstream compatibility matters
- tracked config should stay close to rAthena defaults
- local container config belongs in ignored `conf/import/*.txt` files
- fork-first workflow for custom work
- documentation should be updated as decisions become real

## Git Workflow

- `upstream` is `rathena/rathena`
- `origin` is `joshhmann/rathena`
- `upstream` is read-only reference history
- official changes flow from `upstream` into local branches, never the other direction
- custom work is merged and pushed only to `origin`
- `master` is the fork's integrated baseline and may be ahead of upstream
- `dev` is an optional integration/staging branch when needed
- feature work should branch from the current fork baseline

### Git Policy

- never push custom work to `upstream`
- never treat `rathena/rathena` as a merge target for project-specific features
- fetch from `upstream`, then merge or rebase those updates into fork branches locally
- push project history only to `origin`

## Current Milestone

Baseline playable development environment.

Definition of done:

- container dependencies installed
- MariaDB configured
- rAthena builds cleanly
- server config generated for the LXC LAN IP
- login, char, and map servers start
- desktop client can connect and create or log into an account

Current validated baseline:

- mode: Renewal
- client date: `2025-06-04`
- server packetver: `20250604`
- client/server login path: confirmed working

## Current Direction

The server should stay as raw as practical while we build atmosphere.

That means:

- stay close to upstream rAthena
- prefer script/content work over source changes
- make towns and common maps feel inhabited before attempting fake players
- treat ML, LLM, and external AI control as future integrations, not current dependencies

## Next Milestones

1. Polish the Prontera living-world MVP until it feels intentional in play.
2. Audit existing `npc/custom/` scripts and enable only the ones that improve town life without cheapening progression.
3. Expand the ambient system to one additional town and one low-level field map.
4. Define a future bridge contract for AI systems, but keep that work on the backburner until the scripted world layer is strong.

## Open Questions

- exact desktop client file pack to standardize on for the `2025-06-04` baseline
- final patcher distribution method
- whether `2025-06-04` remains the long-term baseline or only the current working branch
- how far simulation can go with script-only systems before source work starts
- which official/custom convenience NPCs improve atmosphere versus making the server feel over-automated
