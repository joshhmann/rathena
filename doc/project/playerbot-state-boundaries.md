# Playerbot State Boundaries

## Goal

Keep bot memory and state predictable by using one explicit four-layer split.

## Layers

### Persistent Long-Term State

Use for identity and continuity.

Examples:

- identity
- account/char linkage
- appearance/persona/archetype
- long-term relationship values
- guild membership metadata
- merchant profile
- progression intent
- inventory/equipment ownership
- long-term schedule preferences
- recurring home/config data

### Session / Runtime State

Use for reconstructable live-state.

Examples:

- online/offline
- current map/x/y
- current controller assignment
- active scheduler slot
- current owner/claim token
- active reservation ids
- current route segment
- live merchant open/closed state
- current follow target
- pending reconcile flags

### Controller-Local Transient State

Use for disposable controller scratch state.

Examples:

- current candidate target
- scoring results
- debounce timers
- retry counters
- dialog step index
- recent fallback choice
- temporary posture/intensity state

### Shared World / Social Memory

Use for medium-lived shared context.

Examples:

- area heat
- recent map-level social interactions
- anchor occupancy memory
- shared greeting cooldowns
- guild-square focus state
- local crowd mood/activity markers

## Rule

- if losing it breaks who the bot is, it is persistent
- if losing it only interrupts the current activity, it is runtime or transient
- if many controllers need it, it belongs in shared world/social memory
