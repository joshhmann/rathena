# Living World Roadmap

## Planning Rule

World atmosphere comes before automation.

For now, the project should prioritize:

1. stable upstream-compatible server behavior
2. believable town and field atmosphere
3. reusable script systems
4. selective source-backed pseudo-player actors where presentation matters
5. content curation from existing rAthena assets
6. only later, deeper simulation or AI-driven behavior

ML, LLM, and external agent control are explicitly backburner items until the
server already feels alive through normal rAthena systems.

Future-phase playerbot behavior notes now live in:

- `doc/project/playerbot-future-design-notes.md`
- `doc/project/playerbot-foundation-priorities.md`
- `doc/project/playerbot-foundation-program.md`
- `doc/project/playerbot-behavior-phase-plan.md`

That file is for aligned long-term design ideas, not for claiming current
implementation status.

Current foundation priorities for the playerbot lane live in:

- `doc/project/playerbot-foundation-priorities.md`
- `doc/project/playerbot-foundation-program.md`

That file is the working source of truth for what should be finished before the
project leans harder into richer behavior scripting.

Current status:

- the accepted playerbot foundation baseline is now complete
- requested follow-on extension lanes are also complete for:
  - PvP / WoE death semantics
  - Rodex receive / attachment retrieval
  - pet / mercenary / elemental continuity
- homunculus remains intentionally excluded for now

Behavior work is now the primary frontier.

Current behavior-phase status:

- baseline behavior-kernel scaffold is now landed
- current verified kernel lane:
  - `npc/custom/playerbot/playerbot_behavior_lab.txt`
  - `tools/ci/playerbot-behavior-smoke.sh`
- the kernel now has a config-backed policy surface sourced from `bot_behavior_config`
- first real town/social presence proof is now landed
  - `npc/custom/playerbot/playerbot_social_behavior_lab.txt`
  - `tools/ci/playerbot-social-behavior-smoke.sh`
- first real party/support proof is now landed
  - `npc/custom/playerbot/playerbot_party_behavior_lab.txt`
  - `tools/ci/playerbot-party-behavior-smoke.sh`
- first real merchant/economy proof is now landed
  - `npc/custom/playerbot/playerbot_merchant_behavior_lab.txt`
  - `tools/ci/playerbot-merchant-behavior-smoke.sh`
- first real combat-selection proof is now landed
  - `npc/custom/playerbot/playerbot_combat_behavior_lab.txt`
  - `tools/ci/playerbot-combat-behavior-smoke.sh`
- combat now also has a first role-bias proof:
  - tank -> `hold_position`
  - dps -> `attack_target`
  - support -> `disengage`
- combat now also has a first skill-selection proof:
  - caster -> `cast_skill`
- first real quest/progression proof is now landed
  - `npc/custom/playerbot/playerbot_progression_behavior_lab.txt`
  - `tools/ci/playerbot-progression-behavior-smoke.sh`
- next recommended behavior expansion: richer support/heal behavior, broader class-aware combat policy, or progression-state persistence

## External Test Harness

An external CLI client harness is now part of the project workflow:

- `OpenKore` is approved for regression and smoke testing
- it is a client-side validation tool only
- it is not part of the `headless_pc` / `playerbot` subsystem design

Canonical note:

- `doc/project/openkore-test-harness.md`

## Slice Documentation Rule

Every non-trivial subsystem slice should leave behind repo-local implementation
notes.

Execution policy:

- prefer strong foundation slices over tiny cosmetic micro-slices when the
  design boundary is already clear
- it is acceptable to land a larger slice if it closes one coherent subsystem
  step end-to-end
- still validate every non-trivial slice before treating it as done
- use CLI/OpenKore validation first when it is sufficient, then use the desktop
  client for visual or interaction-heavy confirmation
- parallel sidecar work is encouraged when it shortens the path to a validated
  slice, especially for:
  - docs and slice logging
  - config/data-layer drafting
  - regression harness updates
  - bounded non-overlapping code paths
- parallel work must not weaken validation, documentation, or SQL-artifact
  discipline
- when parallel branches are active, keep their repo-local scope briefs updated
  in `doc/project/parallel-branch-workmap.md`
- for playerbot work, branch-first parallel execution is now the preferred
  operating mode whenever write scopes are disjoint enough to support it cleanly

Minimum for each slice:

- what the slice was trying to prove
- exact files/modules touched
- lifecycle or runtime path changes
- what was intentionally deferred
- how the slice was validated

If a slice changes database structure or requires persistent data changes, it
must also leave behind an explicit SQL artifact in the repo:

- schema/table changes go in `sql-files/main.sql` and a dated
  `sql-files/upgrades/upgrade_YYYYMMDD.sql`
- data backfills or required operator updates should also live in a checked-in
  SQL file rather than only in ad hoc shell history
- the slice log should mention the SQL file used

For `headless_pc_v1`, the running log lives in:

- `doc/project/headless-pc-v1-slice-log.md`

## Milestone 0: Working Baseline

Status: complete

Definition of done:

- working Renewal server in the dev LXC
- `PACKETVER 20250604`
- desktop client login confirmed
- fork and upstream workflow established
- repo-local project docs created

## Milestone 1: Prontera Feels Alive

Status: complete

Goals:

- make Prontera feel populated within the first minute of player arrival
- add reasons for players to linger in town
- avoid source changes

Scope:

- scripted ambient actors in Prontera
- limited ambient chatter and emotes
- timed hotspot rotation
- selected service NPCs from `npc/custom/`

Exit criteria:

- no script errors on startup
- no blocked warps, guides, or service counters
- visible ambient activity around core Prontera zones
- Prontera established as the main convenience hub with intentional service coverage

## Milestone 2: Reusable Town System

Status: complete

Goals:

- convert the Prontera pattern into a reusable town-population template
- expand the pattern across the town network

Scope:

- common controller pattern for town ambience
- role-based hotspot sets per city
- city-specific dialogue pools
- hub-service parity for supported towns
- rollout through classic, flavor, frontier, and newer hub maps

Exit criteria:

- town rollout implemented through Waves 1-5
- no parser/runtime errors from the living-world layer
- shared conventions documented in `doc/project/`

Implementation note:

- current town layouts are accepted as the functional baseline
- service clusters are intentionally simple for now
- map-aware coordinate polish is deferred to a later pass

## Milestone 3: Living World Framework And Proofs

Status: complete

Goals:

- define the script-only limits of the project clearly
- replace one-off living-world patterns with reusable framework conventions
- support town actors, merchant actors, field actors, and event fillers through one shared framework layer

Scope:

- repo-local capability matrix and simulation-lane docs
- shared framework helpers and controller conventions
- one merchant proof slice
- one event filler proof slice

Exit criteria:

- script-only boundaries are documented clearly
- new framework helpers are in active use
- one semi-functional merchant pocket works
- one event filler prototype works

Implementation note:

- this milestone started as a script-only framework pass
- it now also includes the first approved source-backed primitive: `fakeplayer()`
- scripts remain the orchestration layer even when source-backed actors are used

## Milestone 4: Fakeplayer-Backed Overworld Activity

Status: complete

Goals:

- make early leveling routes feel observed and used
- create the illusion of adventurer traffic outside towns
- validate pseudo-player walkers as the field-actor foundation

Scope:

- one field map near a starter city
- fakeplayer-backed guards, travelers, and courier traffic
- script-controlled routes, respawn, and presence gating
- event-driven chatter rather than heavy AI

Exit criteria:

- one field map feels noticeably less empty
- actors read as player-like, not mob-like
- fakeplayer walkers remain a presentation layer, not true bots
- performance remains normal

Implementation note:

- `prt_fild08` is the accepted proof map for this milestone
- the current presentation uses conservative client-safe fakeplayer appearances
- further field rollout is optional polish, not a gating requirement for subsystem work

## Milestone 5: Broader Pseudo-Player Systems

Status: complete for ambiance scope

Goals:

- selectively extend fakeplayer-backed actors into other atmospheric roles
- improve merchant, event, and town presentation where NPCs are not convincing enough

Scope:

- selective town walkers
- merchant stand-ins where useful
- event participants using pseudo-player visuals
- first persistent bot-state schema

Constraints:

- towns and services remain primarily NPC-driven by default
- no promise of true player semantics
- keep fakeplayer usage selective, not universal

Implementation note:

- the next design freeze inside this milestone is `headless_pc_v1` Phase 0
- that phase defines the first real PC-backed bot target
- reference: [headless-pc-v1-phase0.md](/root/dev/rathena/doc/project/headless-pc-v1-phase0.md)
- for the atmosphere lane, this milestone is considered complete once:
  - town ambience is fakeplayer-backed where appropriate
  - one field slice is fakeplayer-backed
  - merchant/event proofs exist
  - bot-state schema is documented
- true party, merchant, and player semantics are subsystem work, not remaining ambiance work

## Milestone 6: External AI Bridge

Status: deferred

Goals:

## Playerbot Scheduler Direction

The next playerbot/controller milestone should prefer a world scheduler over
more one-off demos.

Current preferred policy direction:

- spawn headless actors only when a player is active on the relevant map or
  route
- make recurring presence explicit with routine groups and hour windows so the
  scheduler can predictably keep some identities online while parking others
- do not despawn instantly when the last player leaves; use a short grace
  window/cooldown first so the world does not visibly pop
- allow some controllers to traverse connected field routes instead of living
  on a single map forever
- maintain a small persistent routine pool of identities that represent
  recurring "daily life" actors
- let recurring actors be predictably online or offline by schedule/timezone so
  the world develops familiar faces rather than pure randomness
- treat parking/offline as the normal lifecycle for recurring actors; avoid
  destructive cleanup except for explicit operator retirement

Implementation note:

- this is a scheduler/controller-policy concern, not a reason to bypass the
  existing `headless_pc` ownership and lifecycle rules
- the canonical phased execution guide is:
  - `doc/project/playerbot-execution-plan.md`

- let external systems influence the world without owning core gameplay truth

Scope:

- read-only or advisory bridge first
- dialogue generation or schedule suggestion
- later, action proposals for controlled actor systems

Constraints:

- rAthena remains the authority
- the server must still be playable if the bridge is offline
- no mandatory ML or LLM dependency for core gameplay
