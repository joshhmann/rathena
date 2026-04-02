# Playerbot Behavior Phase Plan

## Purpose

Turn the now-complete playerbot foundation into an implementation order for the
first real behavior systems.

This document assumes:

- the accepted foundation baseline is complete
- helper-backed extension coverage exists for:
  - PvP / WoE death semantics
  - Rodex receive / attachment retrieval
  - pet / mercenary / elemental continuity
- homunculus remains intentionally out of scope

Companion documents:

- `doc/project/playerbot-rathena-system-coverage.md`
- `doc/project/playerbot-future-design-notes.md`
- `doc/project/playerbot-execution-plan.md`
- `doc/project/playerbot-mechanic-gap-audit.md`

---

## Current Status

The baseline behavior kernel scaffold now exists and is verified through:

- `npc/custom/playerbot/playerbot_behavior_lab.txt`
- `tools/ci/playerbot-behavior-smoke.sh`

Current proof:

- weighted candidate choice works
- cooldown gating works
- repeat-penalty redirection works
- decision reason/score memory is inspectable
- `bot_behavior_config` can now bias candidate choice through a dedicated policy-aware picker

This means the next behavior slice should build on the scaffold rather than
re-arguing the kernel model.

The first real family now also exists in focused proof form through:

- `npc/custom/playerbot/playerbot_social_behavior_lab.txt`
- `tools/ci/playerbot-social-behavior-smoke.sh`
- `npc/custom/playerbot/playerbot_party_behavior_lab.txt`
- `tools/ci/playerbot-party-behavior-smoke.sh`
- `npc/custom/playerbot/playerbot_merchant_behavior_lab.txt`
- `tools/ci/playerbot-merchant-behavior-smoke.sh`
- `npc/custom/playerbot/playerbot_combat_behavior_lab.txt`
- `tools/ci/playerbot-combat-behavior-smoke.sh`
- `npc/custom/playerbot/playerbot_progression_behavior_lab.txt`
- `tools/ci/playerbot-progression-behavior-smoke.sh`
- `npc/custom/playerbot/playerbot_combat_behavior_lab.txt`
- `tools/ci/playerbot-combat-behavior-smoke.sh`

Current social-family proof:

- a town/social bot chooses among idle, emote, and hotspot actions
- decision memory remains inspectable through shared memory
- hotspot movement is proven at least once in the deterministic selftest path

Current party/support-family proof:

- a party-capable bot chooses `assist` as the winning action under party-friendly policy
- the chosen action is persisted through the shared behavior memory surface
- the existing assist-anchor runtime completes against the moved leader target

Current merchant/economy-family proof:

- a merchant-capable bot chooses `open_shop` as the winning action under merchant-friendly policy
- the chosen action is persisted through the shared behavior memory surface
- the existing merchant state/runtime surface enters open + merchanting state and records browse/sale runtime activity

Current combat-family proof:

- a combat-capable bot chooses `attack_target` as the winning action under combat-friendly policy
- the chosen action is persisted through the shared behavior memory surface
- the existing attack-intent runtime engages a live target and then clears target state again

Current progression/quest-family proof:

- a progression-capable bot chooses `advance_relay` as the winning action under progression-friendly policy
- the chosen action is persisted through the shared behavior memory surface
- the existing quest relay A→B runtime completes and leaves stable stage progression evidence

Current combat-family proof:

- a combat-capable bot chooses `attack_target` as the winning action under combat-friendly policy
- the chosen action is persisted through the shared behavior memory surface
- the existing attack-intent runtime acquires and engages one legal dummy target

---

## Foundation Features Now Available To Behavior

Behavior work can now safely depend on:

- persistent bot identity + runtime state
- pooled parked/offline lifecycle
- restore / reconcile / remove / grace-window semantics
- movement, routing, and map changes
- reservation and contention control
- NPC/dialog, storage, trade, guild, and market participation hooks
- item/loadout/reform/refine/enchant/card execution semantics
- combat intent, death/respawn cleanup, and status continuity
- helper-backed Rodex retrieval
- helper-backed pet / mercenary / elemental continuity
- trace + recovery-audit observability

Behavior work should **not** assume:

- homunculus support
- full Rodex delete/return workflow automation
- aggregate-gate promotion of the split skillunit proof
- whisper/chat/social-visibility policy being settled

---

## Behavior Design Rules

1. **Reuse real game systems first**
   - behaviors should call the existing playerbot/headless primitives, not fake new layers
2. **Keep policy separate from mechanics**
   - behavior chooses *what* to do; foundation owns *how* the game system executes safely
3. **Prefer deterministic weighted logic over opaque AI control**
   - state machines, scores, cooldowns, and tags first
4. **Ship one behavior family at a time**
   - social, party, merchant, combat, progression should not be mixed in one slice
5. **Trace every decision boundary that can fail or drift**
   - when behavior chooses, skips, aborts, or retries, the reason should be inspectable

---

## Recommended Phase Order

### Phase B1: Behavior Kernel And Policy Surface

Goal:
- create one reusable behavior-decision skeleton that later families can share

Slices:
1. behavior profile/tag schema usage through `bot_behavior_config`
2. utility/weight evaluation helpers
3. per-bot cooldown + recent-action memory
4. one common "choose next action" contract

Definition of done:
- every later behavior family can plug into one common selector shape
- decisions are deterministic and traceable

### Phase B2: Social / Town Presence Behavior

Goal:
- make bots feel intentionally present in towns before deeper combat logic

Slices:
1. ambient idle / emote / reposition routines
2. hotspot preference by profile/role
3. lightweight NPC interaction behaviors where safe
4. recurring familiarity/presence hooks (non-chat first)

Definition of done:
- one recurring town bot can choose among idle/social actions without external forcing

Current status:
- thin deterministic proof is landed through `playerbot_social_behavior_selftest`
- broader recurring ambient/controller promotion is still the next expansion inside this family

### Phase B3: Party / Support Behavior

Goal:
- move from party-capable primitives to actual party-capable bots

Slices:
1. invite accept/decline policy
2. follow / regroup policy
3. assist / protect target selection
4. role tags: tank / support / dps / social companion

Definition of done:
- one party helper bot can join, follow, and assist predictably across map/death transitions

### Phase B4: Merchant / Economy Behavior

Goal:
- make merchant-capable recurring bots actually act like merchants

Slices:
1. open/close vending policy by routine and stock
2. buyingstore policy and reopen timing
3. restock source policy (limited, explicit)
4. simple price/stock profile behavior, not full simulation

Definition of done:
- one recurring merchant bot can decide when to open, close, and restock within bounded rules

### Phase B5: Combat Behavior

Goal:
- convert combat participation into combat choice

Slices:
1. target selection policy
2. attack vs reposition vs disengage choice
3. safe self-buff / consumable use policy
4. first class/role-specific combat profiles
5. optional later skillunit promotion if needed by behavior quality

Definition of done:
- one combat-capable bot can choose legal targets and sustain basic fights autonomously

### Phase B6: Quest / Progression Behavior

Goal:
- give recurring bots a long-horizon reason to exist

Slices:
1. quest/task preference tags
2. equipment/loadout preference policy
3. simple level/job progression policy
4. daily routine + progression blend

Definition of done:
- one recurring bot can show persistent progression choices over time

---

## First Behavior Slice Recommendation

The best first implementation target is:

### **B1 + B2 thin vertical slice**

Specifically:
- create the behavior kernel
- immediately use it for a town/social bot

Why this first:
- lowest risk
- highest visible payoff
- exercises scheduler/presence/guild/merchant context without depending on full combat AI
- gives one reusable selector pattern before party/combat behaviors arrive

Concrete first slice:
1. behavior tags in `bot_behavior_config`
2. decision helper for weighted action choice
3. social/town routine controller using:
   - stay idle
   - emote
   - move to hotspot
   - open NPC/shop interaction when allowed
4. trace reasons for each choice

---

## What Not To Do First

Avoid starting behavior with:

- full combat rotations
- full merchant economy simulation
- guild chat/politics
- quest automation
- ML/LLM-driven control

Those all depend on having a stable behavior kernel and family boundaries first.

---

## Parallelization Guidance For Behavior Work

Safe parallel lanes:
- docs + scenario/runbook updates
- behavior-tag schema/docs
- decision-trace tooling
- one behavior family implementation + one read-only reviewer lane

Unsafe parallel combinations:
- two behavior families editing the same controller/runtime hotspots
- combat behavior and merchant behavior both changing shared decision helpers before they stabilize
- chat/social policy work mixed with core movement/combat policy in one slice

---

## Behavior Entry Checklist

Before starting the first behavior implementation slice, confirm:

- foundation coverage doc is current
- helper-backed extension boundaries are documented honestly
- one behavior family is chosen as the primary lane
- its acceptance criteria are scenario-backed and traceable
- the slice does not silently widen into another family

---

## Recommended Immediate Next Actions

1. implement the **behavior kernel** in the smallest reusable form
2. use it for a **town/social presence** bot first
3. then move into **party/support** behavior
4. then **merchant/economy** behavior
5. then **combat** behavior

That order maximizes visible progress while minimizing early behavior fragility.
