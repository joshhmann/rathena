# Codebase Notes: Living World

## Current Implementation Pattern

The project currently uses a script-first approach.

Active custom entrypoints:

- `npc/scripts_custom.conf`
- `npc/custom/living_world/prontera_ambient.txt`

This is the correct default pattern for current work because it keeps the fork
close to upstream and makes rollback/testing easy.

## Existing Reusable Script Surface

The stock `npc/custom/` tree already provides several useful building blocks:

- town services
- progression hooks
- social flavor systems
- mini-games and events

We should treat these as curated ingredients, not a bundle to enable wholesale.

## Recommended Usage Strategy

### Use directly

- simple service NPCs that strengthen towns
- quest-board style hub content
- cosmetic/social services

### Adapt lightly

- scripts with good gameplay purpose but poor placement or tone
- scripts that need relocation into the living-world town layout
- scripts that need reward tuning for the project’s pacing

### Avoid for now

- scripts that trivialize movement or progression
- scripts that over-centralize convenience in one town
- scripts that make the server feel like a utility sandbox instead of a world

## Future Source Work Threshold

Do not add source changes for “living world” features until at least one of
these is true:

- scripts cannot express the needed behavior cleanly
- a repeated script workaround becomes fragile or expensive
- a desired illusion clearly requires engine-level support

Until then, script architecture should carry the project.
