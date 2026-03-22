# Ambiance Closeout

## Decision

The atmosphere layer is accepted as complete enough to stop building new
foundation content and pivot to subsystem work.

## What Counts As Complete

- town and hub coverage is in place
- fakeplayer-backed town ambience is working on the accepted baseline
- `prt_fild08` proves fakeplayer-backed field traffic
- Alberta merchant and event proof slices exist
- the living-world framework and pseudo-player docs are in the repo

## What Is Still Allowed

Allowed later as polish:

- better coordinates
- more landmark-aware placements
- extra field slices
- more pseudo-player merchant/event presentation
- client-safe appearance variety once assets are verified

## What Is No Longer A Gate

These are no longer blockers for subsystem work:

- another town rollout pass
- broader fakeplayer field coverage
- more service NPC curation
- more ambiance-only experimentation

## Current Pivot

The next real engineering push is:

- `headless_pc_v1`

That means:

- real `BL_PC`-backed actor lifecycle
- no real client socket
- safe world presence
- clean save/remove path

Atmosphere work can still be polished later, but it is no longer the primary
track.
