# Playerbot Behavior Authoring Guide

## Purpose

Define the stable workflow for expanding the playerbot behavior system in this
repo without drifting away from the shared kernel, the family model, or the
existing validation surface.

This guide is for:

- extending an existing behavior family
- adding a new persona or play style inside an existing family
- adding a new first-class behavior family
- planning population orchestration and unique named bots

Companion docs:

- `doc/project/playerbot-behavior-kernel-workflow.md`
- `doc/project/playerbot-behavior-phase-plan.md`
- `doc/project/playerbot-scenario-runner.md`
- `doc/project/bot-state-schema.md`
- `doc/project/playerbot-contributor-workflow.md`

## Core Model

The playerbot behavior system now has four layers:

1. **Kernel**
   - shared chooser
   - shared cooldown memory
   - shared last-action memory
   - shared config-aware policy bonus scoring
2. **Family**
   - social
   - party/support
   - merchant/economy
   - combat
   - quest/progression
3. **Persona / Play Style**
   - cautious
   - aggressive
   - supportive
   - routine-driven
   - shopkeeper
   - regular / local
4. **Instance State**
   - what the bot is doing right now
   - cooldowns
   - most recent action and reason
   - family-specific transient state

Use the family layer for broad behavior shape.
Use persona/play style for finer policy differences inside the family.

Do not create a second top-level chooser.

## Stable Surfaces

### Shared Kernel

Current shared kernel surface lives in:

- `npc/custom/playerbot/playerbot_behavior_lab.txt`
- `tools/ci/playerbot-behavior-smoke.sh`

Primary helpers:

- `F_PB_BEHAVIOR_Key$`
- `F_PB_BEHAVIOR_LastAction$`
- `F_PB_BEHAVIOR_CooldownReady`
- `F_PB_BEHAVIOR_Score`
- `F_PB_BEHAVIOR_ConfigBonus`
- `F_PB_BEHAVIOR_ScorePolicy`
- `F_PB_BEHAVIOR_MarkDecision`
- `F_PB_BEHAVIOR_PickSimple$`
- `F_PB_BEHAVIOR_PickPolicy$`
- `F_PB_BEHAVIOR_BuildSummary$`

### Shared Config

Current policy/config surface lives in:

- `bot_behavior_config`
- `bot_merchant_state`
- `bot_guild_state`
- `bot_progression_state`
- controller/pool tables

Fresh installs must use:

- `sql-files/main.sql`

Upgrade installs must use:

- `sql-files/upgrades/*.sql`

### Runbook Surface

Every accepted family must have:

- one focused smoke helper under `tools/ci/`
- one scenario entry in `tools/ci/playerbot-scenario-catalog.sh`
- one scenario launcher path through `tools/ci/playerbot-scenario.sh`

## Current Behavior Families

These first-pass families are already established:

- social
  - `idle`
  - `emote`
  - `hotspot`
- party/support
  - `assist`
- merchant/economy
  - `open_shop`
- combat
  - `attack_target`
  - `disengage`
  - `hold_position`
  - `cast_skill`
  - `cast_support_buff`
- quest/progression
  - `advance_relay`

Treat these as reusable family roots, not one-off scripts.

## Authoring Workflow

### 1. Choose the layer

Ask:

- is this a new family?
- or a persona/play style inside an existing family?
- or persistence/orchestration for an existing family?

If it is just a new flavor of an existing family, stay inside that family.

### 2. Reuse runtime, do not replace it

Behavior chooses **what** to do.
Existing runtime/labs/hooks should continue to own **how** the game system
executes safely.

Examples:

- social proof should reuse town/social runtime hooks
- support proof should reuse the existing party assist runtime
- merchant proof should reuse merchant state/runtime surfaces
- combat proof should reuse attack/skill/status hooks
- progression proof should reuse the quest relay runtime

### 3. Define candidates explicitly

Before editing code, name the candidate actions.

Examples:

- social:
  - `idle`
  - `emote`
  - `hotspot`
- combat:
  - `attack_target`
  - `disengage`
  - `cast_skill`
- progression:
  - `advance_relay`
  - `idle`

### 4. Bias through config first

Prefer extending `F_PB_BEHAVIOR_ConfigBonus(...)` and `F_PB_BEHAVIOR_PickPolicy$`
before inventing family-local scoring systems.

Use:

- `profile_key`
- `controller_tag`
- `interaction_policy`
- `party_policy`
- `presence_policy`
- `routine_group`
- `pulse_profile`

for first-pass persona and role differences.

### 5. Add one focused selftest/smoke

Every accepted family or family extension needs:

- one hidden selftest
- one dedicated smoke helper
- one scenario entry
- one clear `result=1` line

### 6. Update docs in the same slice

Minimum:

- behavior plan
- roadmap
- slice log
- scenario notes if a new scenario exists

If persistence/schema changes:

- update `doc/project/bot-state-schema.md`

## SQL Rules

If the slice changes durable state:

1. update `sql-files/main.sql`
2. add a new upgrade file under `sql-files/upgrades/`
3. mention both in the slice log
4. validate against the local DB

Do not leave schema changes only in shell history.

## Population Orchestration

The current system already supports most of the building blocks for population
control:

- pool assignment
- controller policy
- demand maps/signals
- pulse profiles
- behavior config

What the project does **not** yet have is one unified top-level population
orchestration layer comparable to “spawn N bots of these personas on these maps
under these caps.”

When building that layer later, keep the model:

1. **population policy**
   - how many bots by family/persona/map/time
2. **pool source**
   - which pool provides those identities
3. **family policy**
   - what those bots do once present
4. **persona weighting**
   - how likely each play style is

Do not collapse all four into one table unless the maintenance cost is clearly
worth it.

## Unique Named Bots

The system already supports handcrafted unique bots.

Use:

- `bot_profile`
- `bot_identity_link`
- `bot_appearance`
- `bot_behavior_config`
- optional family-specific state:
  - merchant
  - guild
  - progression

### Recipe

1. create/provision the bot identity
2. set a stable `bot_key`
3. set appearance
4. set behavior config
5. set any family-specific persistent state
6. add/adjust scenario coverage if the bot introduces a new behavior surface

Good examples of unique bots:

- a named harbor merchant
- a guild regular in Prontera
- a cautious support bot
- a quest runner with a recognizable routine

## Persona Template Model

Use personas as configuration bundles on top of families.

Examples:

### Social

- `social.regular`
- `social.wanderer`
- `social.quiet`

### Party / Support

- `support.cautious`
- `support.anchor`
- `support.helper`

### Merchant

- `merchant.stallkeeper`
- `merchant.peak-hours`
- `merchant.stockkeeper`

### Combat

- `combat.tank`
- `combat.dps`
- `combat.support`
- `combat.caster`

### Progression

- `progress.quest`
- `progress.grinder`
- `progress.routine`

## Guardrails

Do not:

- invent a second chooser outside the kernel
- bypass existing runtime hooks when a proven one exists
- land a family without a smoke helper
- land a persistence change without SQL artifacts
- present static config as live runtime truth

Do:

- keep family slices coherent
- keep validation mandatory
- prefer larger but still bounded slices when the boundary is clear
- use the scenario runner as the canonical runbook layer

## Minimum Acceptance Checklist

For any new family or persona extension:

1. kernel or family action added
2. config bias defined
3. runtime surface reused
4. smoke helper added or updated
5. scenario entry added or updated
6. docs updated
7. fresh install SQL updated if needed
8. upgrade SQL added if needed
9. validation passed

## What Comes Next

With the current repo state, the next major behavior/frontier work is mostly:

- broader class-aware combat policy
- stronger support/heal/cleanse behavior
- longer-horizon progression budgets and routines
- population orchestration and persona distribution
- richer named/unique pseudo-players
