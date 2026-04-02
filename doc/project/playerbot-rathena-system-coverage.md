# Playerbot rAthena System Coverage Map

## Purpose

Map every major rAthena game system against the current playerbot foundation
and classify each one by coverage status, layer, and priority.

Use this document to:

- identify foundation gaps that must be addressed before behavior work starts
- identify behavior-layer targets for the next phase
- avoid accidentally shipping a behavior feature that depends on an untested
  system path

This document does not claim runtime behavior. It maps intent and gaps only.

Companion documents:

- `doc/project/playerbot-foundation-closeout-checklist.md`
- `doc/project/playerbot-mechanic-gap-audit.md`
- `doc/project/playerbot-future-design-notes.md`
- `doc/project/headless-pc-edge-cases.md`

---

## Coverage Legend

| Symbol | Meaning |
|--------|---------|
| ✓ | Covered in current baseline |
| ~ | Partially covered — happy path only or session-level only |
| ✗ | Not covered |
| ✗ (blocked) | Explicitly blocked at spawn time |
| ✗ (deferred) | Explicitly deferred, no active plan |

Layer labels:

- **foundation** — must be hardened before behavior work depends on it
- **behavior** — requires foundation to exist; belongs in the behavior phase
- **ops** — operator/admin tooling, not a playerbot runtime concern

---

## Lifecycle and Presence

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Spawn / bring-up | ✓ | foundation | Async char-to-map load, headless flag, world-only path |
| Restore after restart | ✓ | foundation | Active-only restore from `headless_pc_runtime` |
| Park / offline lifecycle | ✓ | foundation | Parked pool, offline state |
| Remove / save | ✓ | foundation | Sequence-tracked, ack-persisted |
| Reconcile / stale-state recovery | ✓ | foundation | Targeted reconcile-and-retry lane |
| Despawn grace window | ~ | foundation | Controller grace now writes runtime `park_state='grace'` and `despawn_grace_until` for live actors; still no dedicated automated closeout helper proving expiry/park behavior end-to-end |
| Spawn-failure cleanup | ✓ | foundation | `map_addblock` failure now rolls back partial headless load state and stops pre-ready follow-on reconcile work |
| Companion state at spawn | ✗ (blocked) | foundation | Pet / homunculus / mercenary / elemental presence rejects spawn — see Companions section |

---

## Movement and Navigation

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Teleport / setpos | ✓ | foundation | `headlesspc_setpos` |
| Walk to coordinate | ✓ | foundation | `headlesspc_walkto`, walk-ack, position writeback |
| Route queue | ✓ | foundation | In-memory waypoint loop, looping routes |
| Map change / warp | ✓ | foundation | Covered by participation baseline |
| Multi-map traversal routing | ~ | foundation | Primitive exists; no scheduler-driven cross-map route controller yet |
| Pathfinding around obstacles | ✗ | behavior | Server pathfinder handles movement; no higher-level obstacle-aware planner |
| Follow target | ✗ | behavior | Party assist foundations exist; dedicated follow behavior not built |

---

## Combat

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Attack intent | ✓ | foundation | `playerbot_attack`, `playerbot_attackstop`, `playerbot_target` |
| Death and cleanup | ✓ | foundation | Stale reservations cleared, combat state cleaned |
| Respawn and reconcile | ✓ | foundation | State reconciled before resume |
| Status effects (buffs / ailments) | ✓ | foundation | Apply, clear, continuity across death/respawn/map |
| Ground skill units (skillunit) | ~ | foundation | Creation and cleanup are proven via dedicated probe lane; accepted as a split helper-backed proof rather than aggregate baseline |
| Skillunit promotion precheck | ✓ | foundation | Pre-condition validation surface is helper-backed and covered through the dedicated precheck lane |
| Skill casting (non-positional) | ✗ | behavior | Foundation buildins exist for status; general skill-cast behavior layer not built |
| Target selection / priority | ✗ | behavior | No combat AI decision layer; `playerbot_target` is operator-driven today |
| Loot routing | ✗ | behavior | No item pickup or loot behavior |
| MVP / boss mechanics | ✗ | behavior | Special boss aggro, tombstone, and loot rules not addressed |
| PvP (player-vs-player maps) | ✗ | foundation edge case | PvP death has different drop rules and respawn semantics; foundation should handle these without breaking — see note below |
| War of Emperium | ✗ | behavior | Requires combat, guild, movement foundation; siege AI is behavior-layer |
| Battlegrounds | ✗ (deferred) | behavior | Explicitly deferred in backlog |
| Elemental properties / resist | ✗ | behavior | Engine handles damage calc; bot targeting by element is behavior |

**PvP note**: bots can currently be placed on PvP/PK maps. PvP death does not
drop items for headless actors by default if `headless_bot` flag is respected
by the drop path — this should be verified and added to the edge cases doc.
WoE death respawn point routing is similarly unverified.

---

## Companions

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Pet | ✗ (blocked) | foundation (future ext.) | Spawn rejected if character owns a pet; companion lifecycle not handled |
| Homunculus | ✗ (blocked) | foundation (future ext.) | Alchemist class companion; blocked at spawn |
| Mercenary | ✗ (blocked) | foundation (future ext.) | Hired combat companion; blocked at spawn |
| Elemental | ✗ (blocked) | foundation (future ext.) | Sorcerer class companion; blocked at spawn |

All four are currently a hard reject at spawn time. This is intentional policy
for now, not an oversight. If companion-bearing bots are ever wanted, the spawn
and lifecycle path needs a dedicated foundation extension slice for each
companion type. Companion state persistence, recall/dismiss, and hunger/intimacy
semantics are non-trivial.

Recommended near-term action: document the block explicitly as "future
foundation extension" in the edge cases doc so it is tracked rather than
forgotten.

---

## Social and Party

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Party invite / accept / decline | ~ | foundation | Invite and assist foundations exist; full in-game flow not fully exercised |
| Party follow / assist | ~ | foundation | Basic assist primitives exist; dedicated follow behavior is behavior-layer |
| Party EXP share | ✗ | behavior | Engine handles share calc; bot being present in party is covered; intentional share strategy is behavior |
| Chat (say / shout / party / guild) | ✗ | behavior | No chat emission layer for bots; living-world chatter uses fakeplayer-fronted NPCs today |
| Whisper | ✗ | behavior | Bots should not appear in whisper lists by default; needs deliberate design |
| Friends list visibility | ✗ | behavior | Bots should not pollute player friends lists; needs explicit policy |
| Marriage | ✗ (deferred) | behavior | Social flavor; depends on stable identity and interaction layer |
| Mentoring system | ✗ (deferred) | behavior | Requires persistent relationship model |
| Player search visibility | ✗ | ops | Bots should be explicitly excluded from `/who` and player-search by default |

---

## Guild

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Guild invite / join | ✓ | foundation | Guild invite and join foundations implemented |
| Guild state and demand signaling | ✓ | foundation | Guild-aware demand drives controller visibility |
| Guild storage | ~ | foundation | Inherits from storage baseline; not specifically hardened for bots |
| Guild chat | ✗ | behavior | Chat layer not built |
| Guild notice / roster | ✗ | behavior | Read/respond to guild notices is behavior |
| Guild skills / buffs | ✗ | behavior | Guild-level buff application is behavior |
| War of Emperium participation | ✗ | behavior | See combat section |
| Guild castle defense / supply | ✗ | behavior | Requires WoE behavior layer |

---

## Commerce and Economy

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Vending (seller open / close) | ✓ | foundation | Seller-side vending continuity covered |
| Vendlist browsing | ✓ | foundation | Buyer-side browse covered |
| Buying store (seller open / close) | ✓ | foundation | Seller-side covered |
| Buying store (buyer browse and sell) | ✓ | foundation | Basic buyer-side covered |
| Buying store partial fill | ✓ | foundation | Partial-fill execution and state continuity are covered |
| Buying store reopen | ✓ | foundation | Close/reopen continuity is covered |
| Buying store denial continuity | ✓ | foundation | Browse-inactive, wrong-item, overfill, and zeny-limit denial continuity is covered |
| NPC shop buy / sell | ~ | foundation | NPC interaction layer covers this path; no dedicated bot-NPC-shop smoke |
| Trade with players | ✓ | foundation | Trade session participation covered |
| Mail send / receive (Rodex) | ~ | foundation | Active-session denial + post-close successful send/delivery are covered; receive/attachment semantics are still not proven |
| Mail delivery integrity | ~ | foundation | Post-close mail delivery integrity is covered; full receive/attachment semantics remain open |
| Auction house | ✗ | behavior | Not addressed; depends on item and economy foundation |
| Zeny routing / transfer | ~ | foundation | Covered implicitly through trade and market; no dedicated bot-zeny-routing surface |
| Economy participation (market response) | ✗ | behavior | Bot deciding prices, restocking, responding to supply/demand is behavior |

---

## Storage

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Kafra storage | ✓ | foundation | Deposit, withdraw, interrupted-session cleanup covered |
| Guild storage | ~ | foundation | Inherits from storage baseline; not specifically hardened |
| Extended storage (Rodex attachments) | ~ | foundation | Partial; mail attachment semantics not fully proven |
| Bank | ✓ | foundation | Bank session participation covered |

---

## Item Systems

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Equip / unequip | ✓ | foundation | Happy-path and denial/recovery paths are covered |
| Loadout denial and recovery | ✓ | foundation | Engine-rejected equip handling and recovery are covered |
| Loadout overlap continuity | ✓ | foundation | Overlapping transition continuity is covered |
| Item use / consume | ✓ | foundation | Instant consume, missing-item denial, and delayed item-use interruption proof are covered |
| Item consume continuity | ✓ | foundation | Delayed item-use keeps inventory stable across death/mapchange interruption and failed consumption semantics are covered |
| Refine / upgrade (+N) | ✓ | foundation | Execution/result semantics are covered |
| Reform / modification | ✓ | foundation | Execution/result semantics are covered |
| Enchantgrade | ✓ | foundation | Execution/result semantics are covered |
| Card insertion | ✓ | foundation | Denied + successful insertion path is now covered |
| Identify / appraise | ✗ | behavior | Item identification is a minor NPC interaction; low priority |
| Item drop | ✗ | behavior | Bots dropping items deliberately is behavior; death-drop rules should be verified (see PvP note) |
| Item pickup / loot | ✗ | behavior | No loot routing behavior |

---

## Crafting and Production

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Weapon forging (Blacksmith) | ✗ | behavior | Requires NPC interaction + item use primitives (both partially covered); decision to craft is behavior |
| Potion brewing (Alchemist) | ✗ | behavior | Same as forging; also requires homunculus foundation if Alchemist bot is wanted |
| Cooking | ✗ | behavior | Script-driven recipe NPC; uses NPC interaction and item consume |
| Arrow crafting | ✗ | behavior | Skill-based crafting; uses item consume |
| Rune crafting (Rune Knight) | ✗ | behavior | Skill-based; uses item consume |
| Gemstone / ore processing | ✗ | behavior | NPC interaction + item consume |

Crafting is a behavior-layer concern in all cases. The underlying primitives
(NPC interaction, item use/consume) are being built by the foundation. A bot
deciding to craft, sourcing materials, and executing the recipe belongs in the
behavior phase.

---

## Quest and Progression

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| EXP gain from kills | ~ | foundation | Engine handles EXP grant; bot can kill things; no dedicated EXP-progression bot behavior |
| Job EXP and job change | ✗ | behavior | Deciding to change job, selecting classes, is behavior |
| Stat point allocation | ✗ | behavior | No auto-stat behavior; deferred |
| Skill point allocation | ✗ | behavior | No auto-skill behavior; deferred |
| Quest tracking / acceptance | ✗ | behavior | NPC interaction layer covers the dialog; quest state tracking for bots is behavior |
| Daily missions / hunting missions | ✗ | behavior | Requires quest layer and behavior decision engine |
| Achievement system | ✗ (deferred) | behavior | Low priority; engine awards achievements passively in many cases |

---

## Instance and Special Content

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Instance dungeon creation | ✗ | behavior | Requires party coordination and NPC interaction |
| Instance dungeon participation | ✗ | behavior | Requires combat, movement, and party behavior layers |
| Seasonal / GM events | ✗ | behavior | Event NPC interaction; behavior-layer decision to participate |
| PvP ranking / ladders | ✗ (deferred) | behavior | Out of scope until PvP behavior exists |

---

## Chat and Visibility

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Overhead chat (say) | ✗ | behavior | Living-world chatter is NPC-backed today; headless bot say is not built |
| Shout / global channel | ✗ | behavior | Should be deliberately gated — bots shouting by default is noise |
| Party chat | ✗ | behavior | Behavior layer |
| Guild chat | ✗ | behavior | Behavior layer |
| Whisper | ✗ | behavior | Needs deliberate policy — bots should not appear in whisper by default |
| `/who` and player search | ✗ | ops | Bots should be excluded or clearly labeled in player listings |
| Emotes | ~ | behavior | Living-world layer uses emotes on fakeplayer-fronted actors; headless PC emotes not specifically proven |

---

## Kafra and Utility Services

| System | Status | Layer | Notes |
|--------|--------|-------|-------|
| Kafra teleport | ~ | foundation | Map change path is covered; Kafra-gated teleport specifically not tested |
| Kafra save point | ✗ | behavior | Deciding where to save is behavior; respawn point correctness should be verified |
| Healer NPC | ✗ | behavior | Trivial NPC interaction; low priority |
| Job master | ✗ | behavior | Job change is behavior-layer |
| Stylist / appearance change | ✗ | behavior | Cosmetic; not a playerbot priority |
| Platinum skills NPC | ✗ | behavior | Skill acquisition behavior; low priority |

---

## Summary by Layer

### Foundation gaps still open

These need to be addressed before the behavior phase is safe to build on them:

1. PvP / WoE death semantics verification
2. Companion unblock (pets, homunculus, mercenary, elemental) — named future extension
3. Buying store partial fill, reopen, denial continuity
4. Mail delivery integrity
5. Guild storage hardening
6. Skillunit promotion precheck and aggregate-gate decision

### Behavior-layer targets (after foundation closes)

Good first-wave behavior targets once the foundation is closed:

1. Combat target selection and skill usage
2. Party follow / assist role behavior
3. Guild chat and presence behavior
4. Quest tracking and daily mission participation
5. Crafting (Blacksmith / Alchemist / cooking)
6. Loot routing
7. WoE participation (long-term)
8. Instance dungeon participation (long-term)

### Explicitly deferred / out of scope for now

- Battlegrounds
- PvP ranking
- Marriage / mentoring
- Auction house
- Chat / whisper / social visibility (needs deliberate policy design)
- ML / LLM behavior systems
- External AI bridge

---

## Recommended Next Actions

1. Add PvP and WoE death/respawn semantics as named edge cases in
   `headless-pc-edge-cases.md`.

2. Promote the companion block from implicit to explicit in
   `headless-pc-edge-cases.md` — label each one as "future foundation
   extension" with a note on what the extension would require.

3. Add the remaining foundation gaps from the summary above to the closeout
   checklist as the next wave of required checks after the current open fronts
   close.

4. Add the behavior-layer targets to `playerbot-future-design-notes.md` as
   named future commitments when they are ready to be scheduled.
