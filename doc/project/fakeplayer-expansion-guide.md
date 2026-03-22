# Fakeplayer Expansion Guide

## Purpose

This guide explains how to add more fakeplayer-backed ambiance to the live
living-world system.

Use this for:

- adding more town ambient actors
- adding another field traffic slice
- extending an existing town with more walkers

Do **not** use this guide for:

- merchants with real shop interaction
- party-capable bots
- persistent bot state
- true `BL_PC` subsystem work

Those belong to the later `headless_pc_v1` lane.

## Core Rule

Use the cheapest convincing tool.

- town ambience: fakeplayer-backed walkers are now acceptable
- anchored merchants/services: keep them as NPCs unless there is a strong reason not to
- field traffic: use fakeplayer-backed actors
- true player semantics: not part of this system

## Files You Will Touch

Shared helpers:

- [\_common.txt](/root/dev/rathena/npc/custom/living_world/_common.txt)

Examples:

- [prontera_ambient.txt](/root/dev/rathena/npc/custom/living_world/prontera_ambient.txt)
- [alberta_ambient.txt](/root/dev/rathena/npc/custom/living_world/alberta_ambient.txt)
- [prt_fild08_ambient.txt](/root/dev/rathena/npc/custom/living_world/prt_fild08_ambient.txt)

Loader:

- [scripts_custom.conf](/root/dev/rathena/npc/scripts_custom.conf)

## Current Safe Pattern

The current fakeplayer baseline is intentionally conservative.

Use:

- first-job sprites only
- default hair style
- default hair color
- default cloth color
- no weapon/shield/headgear looks unless you have verified client assets

Reason:

- broader appearance mixes caused client crashes due to missing palette assets

If you want more visual variety later, do it slowly and test the exact client
pack first.

## Town Ambient Pattern

Town controllers use this flow:

1. define visible actor names as normal NPC scripts at the bottom of the file
2. hide those NPCs and spawn fakeplayer bodies with the same names
3. move the fakeplayer body between hotspot coordinates
4. use helper functions for talk and emotions

Key helpers:

- `F_LW_SetAmbientActor(name, show, x, y)`
- `F_LW_ActorTalk(name, msg)`
- `F_LW_ActorEmotion(name, emotion_id)`

### Minimal Town Actor Example

Add a visible actor NPC:

```txt
prontera,150,200,4	script	Square Wanderer	4_F_01,{
	mes "[Square Wanderer]";
	mes "Prontera feels busy today.";
	close;
}
```

Then in the controller:

```txt
S_RefreshSquareWanderer:
	.active_npc$[0] = "Square Wanderer";
	switch (rand(1, 3)) {
	case 1: callfunc "F_LW_SetAmbientActor", "Square Wanderer", 1, 150, 200; break;
	case 2: callfunc "F_LW_SetAmbientActor", "Square Wanderer", 1, 160, 205; break;
	case 3: callfunc "F_LW_SetAmbientActor", "Square Wanderer", 1, 170, 198; break;
	}
	return;
```

Optional talk:

```txt
callfunc "F_LW_ActorTalk", "Square Wanderer", "The market is crowded again.";
```

Optional emotion:

```txt
callfunc "F_LW_ActorEmotion", "Square Wanderer", ET_HUM;
```

## Field Traffic Pattern

Field controllers use a different pattern from towns.

Use:

- one hidden controller
- fakeplayer spawn on player presence
- explicit actor variables like `.guard_west`
- `unitwalk` route loops
- `sleep2` between chained walk callbacks
- despawn when the map is empty

Reference:

- [prt_fild08_ambient.txt](/root/dev/rathena/npc/custom/living_world/prt_fild08_ambient.txt)

### Minimal Field Actor Example

Spawn:

```txt
.traveler = callfunc("F_LW_SpawnFakePlayer", .map$, 180, 340, "Road Traveler", Job_Swordman, Sex_Male, 1, 0, 0, 0, 0, 0, 0, 0, 0);
callsub S_SetAmbientActorMode, .traveler;
unitwalk .traveler, 240, 300, strnpcinfo(3) + "::OnTravelerLeg2";
```

Loop:

```txt
OnTravelerLeg2:
	sleep2 300;
	if (.traveler && unitexists(.traveler))
		unitwalk .traveler, 320, 240, strnpcinfo(3) + "::OnTravelerLeg3";
	end;

OnTravelerLeg3:
	sleep2 300;
	if (.traveler && unitexists(.traveler))
		unitwalk .traveler, 180, 340, strnpcinfo(3) + "::OnTravelerLeg2";
	end;
```

## Merchant Rule

Do **not** make shop NPCs walk.

Keep merchants and service NPCs:

- anchored
- clickable
- stable

Reason:

- moving interactive shop actors caused broken dialog/shop state

If you want a busier merchant area:

- keep the merchants fixed
- add nearby non-interactive ambient walkers

Reference:

- [alberta_merchants.txt](/root/dev/rathena/npc/custom/living_world/alberta_merchants.txt)
- [alberta_ambient.txt](/root/dev/rathena/npc/custom/living_world/alberta_ambient.txt)

## Placement Rules

For towns:

- do not place actors on warps
- do not place actors on doors or service counters
- do not stack actors on the same tile
- keep merchant/service areas readable

For fields:

- avoid warp edges
- keep routes simple
- prefer road, bridge, gate, or landmark traffic
- use short readable loops first

## Naming Rules

- keep visible actor names unique in the living-world tree
- do not reuse the same visible name for multiple different NPC definitions
- use descriptive names tied to the town or role

Good:

- `Dock Runner`
- `Busy Shopper`
- `Road Courier`

Bad:

- `NPC 1`
- `Traveler`
- reused names across several different files

## Safe Workflow

### 1. Add or update the controller

Edit the target file under:

- `npc/custom/living_world/`

### 2. Keep appearances conservative

Do not experiment with palette-heavy looks unless you are intentionally testing
client asset coverage.

### 3. Restart the server

Use:

```bash
SERVER_IP=192.168.0.132 bash /root/setup_dev.sh configure
bash /root/setup_dev.sh restart
```

### 4. Inspect in-game

Check:

- no client crash
- actor visible
- name looks right
- movement loop is not stuck
- chatter is not spammy
- actor is not blocking traffic

## Good Expansion Targets

Easy additions:

- add 1-2 more walkers to an existing town
- add another rest pocket or courier to `prt_fild08`
- add one more field road between two existing hubs

Good next field candidates:

- another Prontera-adjacent route
- Izlude approach traffic
- Alberta dockside road traffic

## Do Not Do Yet

- party invites
- combat AI
- persistent inventories
- fake vending semantics
- true merchant bots
- any logic that depends on real `BL_PC` semantics

That work belongs to `headless_pc_v1`, not the ambiance layer.
