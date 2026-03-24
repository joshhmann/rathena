# Pseudo-Player Architecture

## Purpose

Define a staged path from the current living-world work to low-population
server-owned pseudo-players that can eventually move, party, trade, and fill
world activity without depending on real multiclient bots.

This document is not a commitment to implement full playerbots immediately. It
defines the subsystem boundaries so the next iterations do not paint the fork
into a corner.

## Product Goal

The long-term target is closer to AzerothCore-style playerbots than to static
NPC ambience:

- pseudo-players should visibly exist in the world
- they should be server-owned, not client cheats
- they should eventually support limited party, event, and commerce behavior
- they should improve a low-pop or offline server experience

## Core Principle

Keep the system split into layers.

Do not build party, commerce, or bot logic directly into `fakeplayer()`.

`fakeplayer()` should remain the body and rendering primitive.

## Script Design Rule

Do not try to make the rAthena script layer object-oriented.

Preferred long-term split:

- scripts handle orchestration, menus, and simple state routing
- C++ handles typed lifecycle/state helpers
- persistent data handles identity, policy, and provisioning

Using `select` / `switch` in scripts is acceptable and expected.
The project should avoid large ad hoc script logic trees only by moving
complexity into narrow source helpers and data-backed state, not by inventing
fake OOP patterns in NPC script.

## Subsystems

### 1. Body Layer

Responsibilities:

- spawn a pseudo-player body into the world
- expose player-like visuals
- support movement and map presence
- remain non-attackable or otherwise safe for ambient use

Current primitive:

- source-backed `fakeplayer()`

Non-goals:

- no inventory logic
- no party logic
- no real session semantics

### 2. Controller Layer

Responsibilities:

- script-owned spawn/despawn
- route control
- chatter/emotes
- presence gating
- recovery when an actor disappears

Current primitives:

- `F_LW_SpawnFakePlayer`
- living-world controllers such as `fakeplayer_test.txt`
- field traffic controllers such as `prt_fild08_ambient.txt`

This layer is where ambiance is currently built.

### 3. Bot State Layer

Responsibilities:

- persistent pseudo-player identity
- class, level, role, appearance profile
- inventory/zeny model
- progression flags
- party/combat preferences
- merchant configuration

Recommended shape:

- separate bot-state store, not embedded ad hoc into script locals
- one stable bot identifier independent from current spawned GID
- body spawn should read from bot state, not define bot identity itself

Initial implementation recommendation:

- start with a light persistent state model
- use SQL-backed records for bot identity and role
- defer full inventory/equipment persistence until commerce is needed

### 4. Behavior Layer

Responsibilities:

- decide what the pseudo-player is doing
- pick routes, patrols, tasks, downtime, and role behavior
- later, drive combat and support logic

Near-term implementation:

- script-driven schedules and state machines

Later enhancement:

- expanded combat condition engine
- richer target/skill logic
- role-specific behavior controllers

Scheduler direction:

- prefer a shared scheduler that activates controllers by map demand and time
  window rather than leaving every controller permanently hot
- use short despawn grace periods when maps empty so actors do not disappear the
  moment the last player leaves
- keep a recurring pool of named routine actors so some pseudo-players feel
  familiar across days
- support selected multi-map traversal for travelers, couriers, escorts, and
  commuter-like roles
- keep the number of globally active actors below the provisioned pool by
  activating only the subset currently needed

This is where a future `expanded_ai` core import fits. It should inform
decision-making, not define player semantics.

### 5. Interaction Layer

Responsibilities:

- player clicks and lightweight interaction
- invite/accept/decline party flows later
- contextual responses
- follow/assist toggles later

Near-term recommendation:

- keep interactions simple and explicit
- expose only scripted prompts and stateful responses first

Later recommendation:

- add party invitation handling only after bot identity/state is persistent

### 6. Commerce Layer

Responsibilities:

- merchant roles
- buy/sell behavior
- persistent stock and pricing
- town stall behavior
- eventual vending-like presentation if pursued

Important boundary:

- commerce is a separate subsystem from the condition engine
- the condition engine may decide *when* a bot opens shop or changes role
- it should not own inventory, pricing, or vending semantics

Recommended implementation order:

1. fakeplayer-fronted NPC shop interaction
2. persistent merchant stock state
3. optional vending-like behavior later

### 7. Semantics Layer

Responsibilities:

- party membership
- social/group participation
- event participation semantics
- later, trade/vending/session-like behavior if needed

This is the hardest layer.

It should be treated as future work until the lower layers are stable.

## Milestone Path

### Phase A: Ambiance Bodies

Status:

- active now

Includes:

- town and field presence
- fakeplayer walkers
- script-owned routes and chatter

Success criteria:

- actors feel player-like in presentation
- world traffic is more convincing than mob-backed actors

### Phase B: Interactive Pseudo-Players

Includes:

- click interaction
- simple stateful responses
- role-specific prompts

Success criteria:

- pseudo-players feel like entities, not scenery

### Phase C: Party-Capable Pseudo-Players

Includes:

- invite handling
- accept/decline logic
- basic assist/follow role support

Dependencies:

- stable bot identity/state model

### Phase D: Merchant Pseudo-Players

Includes:

- merchant bot roles
- persistent stock state
- fakeplayer-fronted commerce

Dependencies:

- bot state layer
- commerce subsystem

### Phase E: Full Playerbot Lane

Includes:

- combat roles
- persistent parties
- event participation
- richer merchant behavior
- broader social semantics

Dependencies:

- expanded behavior engine
- selective engine support beyond ambiance
- scheduler-driven activation and persistent routine policy

## Implementation Rules

- keep towns and services mostly NPC-driven unless pseudo-player presentation adds clear value
- keep fakeplayer usage selective and intentional
- do not confuse pseudo-player visuals with true `BL_PC` semantics
- do not couple bot state to a currently spawned body GID
- do not build commerce or party logic directly into `fakeplayer()`
- prefer script orchestration first, engine additions second

## Immediate Next Use

The next use of this architecture should be:

- validate fakeplayer-backed `prt_fild08` field traffic
- keep the current proof small
- do not add party or commerce semantics to that field slice yet

After that, the next design target should be:

- define the first persistent bot-state schema
