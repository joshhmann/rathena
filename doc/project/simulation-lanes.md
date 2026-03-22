# Living World Simulation Lanes

## Lane 1: Script-Only Baseline

This remains the default lane for current implementation.

Includes:
- town ambient actors
- town service and merchant NPCs
- semi-functional merchant actors
- mob-backed event fillers

Constraints:
- no source edits
- no external AI dependency
- no true fake-player behavior

## Lane 2: Selective Source-Assisted Fake Players

This lane is now active and approved for selective use.

Examples:
- field walkers that should read like real adventurers
- pseudo-player guards, travelers, and couriers
- selective merchant or event presentation upgrades
- source-backed actor spawning with script-owned routes and schedules

Policy:
- use this only where NPC or mob presentation is not convincing enough
- scripts still own schedules, routes, chatter, respawn, and cleanup
- this is a presentation/control primitive, not a real player session

## Lane 3: True Fake-Player / Bot Systems

This lane is explicitly future work.

Examples:
- real vending-like fake players
- trade/chat/player packet emulation
- player-count replacement for player-gated systems
- external controller or bot-driven actors

Policy:
- document only for now
- do not design current implementation around it
- do not block atmosphere work on it
