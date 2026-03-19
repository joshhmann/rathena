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
- `master` stays close to upstream
- `dev` is the main integration branch for project work
- feature work should branch from `dev`

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

## Next Milestones

1. Repository hygiene and initial push of the working client branch.
2. Commit the validated `2025-06-04` baseline and setup-script fixes.
3. Document the client packaging assumptions more precisely.
4. Start the first living-world MVP design work.

## Open Questions

- exact desktop client file pack to standardize on for the `2025-06-04` baseline
- final patcher distribution method
- whether `2025-06-04` remains the long-term baseline or only the current working branch
- how far simulation can go with script-only systems before source work starts
