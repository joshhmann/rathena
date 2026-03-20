# Living World Simulation Lanes

## Lane 1: Script-Only Baseline

This is the active lane for current implementation.

Includes:
- town ambient actors
- field patrol actors
- semi-functional merchant actors
- mob-backed event fillers

Constraints:
- no source edits
- no external AI dependency
- no true fake-player behavior

## Lane 2: Source-Assisted Later

This lane is allowed later only if the script-only baseline proves insufficient.

Examples:
- stronger actor control
- more complex event participation logic
- improved target selection or coordination
- deeper performance-driven behavior systems

This lane is not in scope until the script-only baseline is clearly exhausted.

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
- do not block script-only progress on it
