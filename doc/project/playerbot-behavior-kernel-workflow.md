# Playerbot Behavior Kernel Workflow

## Purpose

Document the baseline behavior-kernel scaffold and the intended workflow for
adding new behavior families on top of it.

This is the implementation-facing companion to:

- `doc/project/playerbot-behavior-phase-plan.md`
- `doc/project/playerbot-rathena-system-coverage.md`

## Current Kernel Shape

The first kernel baseline is intentionally small and script-driven.

It currently provides:

- stable bot-key -> behavior summary loading through existing bot profile helpers
- shared-memory-backed action cooldowns
- shared-memory-backed last-action memory
- repeat-penalty scoring
- simple weighted candidate picking
- config-aware policy bonus scoring through `bot_behavior_config`
- one smoke-tested selftest lane

Current runtime surface:

- `npc/custom/playerbot/playerbot_behavior_lab.txt`
- `tools/ci/playerbot-behavior-smoke.sh`
- `npc/custom/playerbot/playerbot_social_behavior_lab.txt`
- `tools/ci/playerbot-social-behavior-smoke.sh`

Key script functions:

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

## Decision Model

The kernel uses a hybrid structure:

1. **Hard gates**
   - if an action is illegal or cooling down, it is discarded
2. **Utility scoring**
   - legal actions receive deterministic scores
3. **Repeat penalty**
   - the most recent action is penalized to reduce loops and spam
4. **Selection**
   - the best current score wins
5. **Marking**
   - the chosen action is written into shared memory with score + reason

This is intentionally **not** a full behavior tree.

Top-level policy should stay utility-driven.
Multi-step execution should live in narrow action-specific flows.

## What This Baseline Is For

Use this baseline when you need to:

- add a new behavior family without inventing a new decision architecture
- compare a few candidate actions deterministically
- enforce cooldowns and anti-repeat memory
- surface decision reasons for debugging and tuning

## What This Baseline Is Not

It is **not yet**:

- a broad ambient/controller-driven town/social system
- a combat planner
- a GOAP system
- a behavior tree engine
- an ML/LLM decision layer

Those may come later, but they should layer on top of the same traceable
selection contract.

## Recommended Development Workflow

### 1. Start with one family only

Do not mix:

- town/social
- party/support
- merchant/economy
- combat
- progression

in the same first-pass implementation.

### 2. Define candidates explicitly

For any new family, list the possible actions first.

Example for town/social:

- idle
- emote
- move_to_hotspot
- inspect_npc

### 3. Define hard gates before scores

Examples:

- bot is online
- bot is not dead
- no conflicting session is active
- action-specific cooldown is clear
- reservation is available if required

### 4. Score with simple deterministic weights

Start with:

- base score
- role/profile modifier
- local context modifier
- repeat penalty
- failure penalty later if needed

Avoid large weight tables until one family is already working.

### 5. Mark the chosen action

Always persist:

- action
- score
- reason
- cooldown

This keeps behavior tuning inspectable.

### 6. Add one smoke/selftest per family

A family is not accepted until it has:

- one deterministic selftest or smoke lane
- one clear pass line
- one short runbook path

## Current Verification Path

Current kernel verification:

- `bash tools/ci/playerbot-behavior-smoke.sh run`

The current selftest proves:

- highest-score candidate wins first
- cooldown blocks immediate repetition
- repeat penalty changes the next winning action
- summary memory reflects the last chosen action and reason
- a seeded `bot_behavior_config` row can bias the winning action through the policy-aware picker

The first social-family selftest additionally proves:

- hotspot movement can win over idle/emote when the utility is higher
- behavior memory captures a real family-specific reason trail
- one bounded town/social loop can run without inventing a new decision architecture

## How To Add The Next Behavior Family

Recommended order:

1. define the family's candidate actions
2. reuse the current behavior helper functions
3. add one family-specific state/reason summary if needed
4. create one focused smoke/selftest
5. document the new family's runbook

## When To Create A Dedicated Skill

Do **not** create the Codex skill yet just because the scaffold exists.

Create the skill after:

- the kernel has powered at least one real behavior family successfully
- the family has a stable implementation pattern
- the smoke/selftest lane is trustworthy
- the docs are no longer likely to churn immediately

The right time is after the first real town/social behavior slice lands and the implementation pattern is stable enough to reuse.
