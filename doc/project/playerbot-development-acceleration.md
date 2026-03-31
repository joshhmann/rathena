# Playerbot Development Acceleration Guide

## Purpose

This document captures reusable code patterns across the playerbot codebase and
defines architecture guidance for the next development phases. It covers:

- **Part A** — Foundation reuse: helpers, templates, and factorization
  opportunities in the current C++, CI, NPC, and SQL layers
- **Part B** — Next-phase patterns: behavior engine, weighted decisions, combat
  AI, and reinforcement learning integration

Use this document to:

- reduce time-to-implement for new buildins, smoke scripts, and NPC selftests
- maintain consistency across the growing playerbot surface
- ground future behavior and AI work in proven rAthena patterns

This document does not change runtime semantics. It documents what exists and
recommends patterns for what comes next.

Companion documents:

- `doc/project/playerbot-rathena-system-coverage.md`
- `doc/project/playerbot-foundation-closeout-checklist.md`
- `doc/project/playerbot-future-design-notes.md`
- `doc/project/playerbot-mechanic-gap-audit.md`

---

# Part A: Foundation Reuse

## 1. C++ Runtime Patterns

Source: `src/map/script.cpp` (lines 136–358, 12838–16437),
`src/map/pc.cpp` (lines 9896–10820)

### Shared Helpers

The following helpers are used across 60+ buildins. Every new buildin should
use them rather than reimplementing lookup or trace logic.

| Helper | Location | Purpose |
|--------|----------|---------|
| `playerbot_online_session_by_key()` | script.cpp:~160 | Bot key → full online session lookup |
| `playerbot_profile_lookup_by_key()` | script.cpp:~140 | Bot key → bot_id only |
| `playerbot_identity_lookup_by_key()` | script.cpp:~150 | Bot key → bot_id + char_id + account_id |
| `playerbot_trace_interaction()` | script.cpp:~200 | Core interaction telemetry (phase='interaction') |
| `playerbot_trace_combat()` | script.cpp:~220 | Combat telemetry (phase='combat') |
| `playerbot_item_audit()` | script.cpp:~250 | Item audit with automatic trace emission |
| `playerbot_recovery_audit()` | script.cpp:~280 | State before/after recovery recording |
| `playerbot_combat_state()` | script.cpp:~300 | 9-field combat state string |
| `playerbot_status_state()` | script.cpp:~330 | 5-field status state string |

PC-layer mirrors in `src/map/pc.cpp`:

| Helper | Purpose |
|--------|---------|
| `pc_playerbot_trace_event()` | Emit trace event from internal C++ paths |
| `pc_playerbot_recovery_audit()` | Record recovery state from internal paths |
| `pc_playerbot_cleanup_skillcast()` | Cancel active skill casts |
| `pc_playerbot_cleanup_skillunits()` | Remove owned ground units |
| `pc_playerbot_cleanup_session_state()` | Clear session-level combat state |
| `pc_playerbot_cleanup_participation()` | Release participation reservations |
| `pc_playerbot_release_reservations()` | Release all owned reservations |

### Standard Buildin Template

Every new `playerbot_*` buildin should follow this pattern:

```cpp
BUILDIN(playerbot_example) {
    // 1. Extract bot key
    const char* bot_key = script_getstr(st, 2);

    // 2. Look up session
    auto* session = playerbot_online_session_by_key(bot_key);

    // 3. Null-check with failure trace
    if (!session) {
        playerbot_trace_interaction(bot_key, "example", "fail",
            "bot not online");
        script_pushint(st, 0);
        return SCRIPT_CMD_SUCCESS;
    }

    // 4. Business logic
    // ... do work using session->sd, session->bot_id, etc.

    // 5. Success trace
    playerbot_trace_interaction(bot_key, "example", "ok",
        "detail=value");

    // 6. Return result
    script_pushint(st, 1);
    return SCRIPT_CMD_SUCCESS;
}
```

Time estimate with helpers: ~15 minutes for a simple buildin.
Without helpers (reimplementing lookup/trace): ~45–60 minutes.

### Factorization Opportunity: Recovery Sequence

The 4-phase cleanup sequence is repeated in four lifecycle paths:

- Death (pc.cpp:~10670–10709)
- Respawn (pc.cpp:~10715–10746)
- Map change (pc.cpp:~10752–10797)
- Logout (pc.cpp:~10803–10820)

Each calls the same four cleanup helpers in the same order:

```
pc_playerbot_cleanup_skillcast(sd);
pc_playerbot_cleanup_skillunits(sd);
pc_playerbot_cleanup_session_state(sd);
pc_playerbot_cleanup_participation(sd);
```

A bundled `pc_playerbot_execute_recovery(sd, context)` would:

- eliminate ~80 lines per new recovery path
- ensure cleanup ordering stays consistent
- let the `context` parameter drive any path-specific behavior

This is the single highest-value C++ factorization target.

### State String Builders

`playerbot_combat_state()` and `playerbot_status_state()` both produce
`key=value,key=value` format strings. Any new state summary function should
follow the same pattern for trace and audit consistency.

---

## 2. CI / Smoke Script Patterns

Source: `tools/ci/playerbot-*.sh` (19 scripts)

### Current Duplication

Approximately 640 lines of boilerplate are duplicated across 7+ smoke scripts.
Common duplicated blocks:

| Block | Approx. lines | Scripts using it |
|-------|---------------|-----------------|
| DB config setup | 15–20 | All smoke scripts |
| REPO_ROOT detection | 5 | All smoke scripts |
| Mapreg arming | 20–30 | combat, item, participation, market, foundation |
| tmux pane polling | 25–35 | combat, item, participation, market |
| OpenKore session launch | 20–25 | combat, item, participation, market |
| Signal validation | 15–20 | combat, item, participation, market, foundation |
| SQL trace/audit queries | 20–30 | combat, item, participation, market |

### Recommended: `tools/ci/playerbot-common.sh`

A shared library sourced by all smoke scripts:

```bash
#!/usr/bin/env bash
# tools/ci/playerbot-common.sh — shared helpers for playerbot smoke scripts

setup_repo_root() {
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[1]}")/../.." && pwd)"
}

setup_db_config() {
    DB_NAME="${DB_NAME:-ragnarok}"
    DB_USER="${DB_USER:-ragnarok}"
    DB_PASS="${DB_PASS:-ragnarok}"
    TEST_AID="${TEST_AID:-2000001}"
}

arm_test() {
    # $1 = mapreg key, $2 = value
    local key="$1" value="$2"
    mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
        "REPLACE INTO mapreg (varname, index_id, value) VALUES ('$key', 0, '$value');"
}

wait_for_pattern() {
    # $1 = tmux pane, $2 = pattern, $3 = timeout seconds
    local pane="$1" pattern="$2" timeout="${3:-60}"
    local elapsed=0
    while (( elapsed < timeout )); do
        if tmux capture-pane -t "$pane" -p 2>/dev/null | grep -q "$pattern"; then
            return 0
        fi
        sleep 2
        (( elapsed += 2 ))
    done
    return 1
}

launch_kore_session() {
    # $1 = session name, $2 = config path
    local session="$1" config="$2"
    tmux new-session -d -s "$session" \
        "cd /root/openkore && perl openkore.pl --config='$config' 2>&1"
}

validate_signals() {
    # $1 = result line, shift = required signals
    local result="$1"; shift
    local missing=0
    for signal in "$@"; do
        if ! echo "$result" | grep -q "$signal"; then
            echo "MISSING: $signal" >&2
            missing=1
        fi
    done
    return "$missing"
}

query_trace_events() {
    # $1 = bot_key, $2 = phase (optional), $3 = limit (optional)
    local bot_key="$1" phase="${2:-}" limit="${3:-20}"
    local where="WHERE detail LIKE '%${bot_key}%'"
    [[ -n "$phase" ]] && where="$where AND phase='$phase'"
    mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
        "SELECT id, ts, bot_id, phase, action, result, detail
         FROM bot_trace_event $where ORDER BY id DESC LIMIT $limit;"
}

query_recovery_audit() {
    # $1 = bot_key, $2 = limit (optional)
    local bot_key="$1" limit="${2:-10}"
    mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e \
        "SELECT id, ts, bot_id, action, result, state_before, state_after
         FROM bot_recovery_audit
         WHERE bot_id = (SELECT bot_id FROM headless_pc_runtime
                         WHERE bot_key='$bot_key' LIMIT 1)
         ORDER BY id DESC LIMIT $limit;"
}
```

### Impact

| Metric | Before | After |
|--------|--------|-------|
| New smoke script size | ~100–120 lines | ~30–40 lines |
| Time to write new smoke | 30–45 min | 10–15 min |
| Bug surface from copy-paste | High | Low (single source) |

---

## 3. NPC Script Patterns

Source: `npc/custom/playerbot/*.txt` (31 scripts)

### Current Duplication

Six or more lab/selftest scripts repeat the same setup and inspection blocks:

- Bot provisioning → spawn → wait for readiness (~15–20 lines each)
- Manual trigger pattern (~10 lines each)
- Bot state inspection queries (~10–15 lines each)
- Trace/audit query formatting (~10 lines each)

### Recommended: Shared Functions in `_common.txt`

Add to `npc/custom/playerbot/_common.txt` or a new
`npc/custom/playerbot/_selftest_common.txt`:

```
// F_PB_SELFTEST_EnsureBot — provision, spawn, wait for readiness
// Args: .@bot_key$, .@map$, .@x, .@y
function	script	F_PB_SELFTEST_EnsureBot	{
    .@bot_key$ = getarg(0);
    .@map$ = getarg(1);
    .@x = getarg(2);
    .@y = getarg(3);
    // ... provision if needed, spawn, poll readiness
    return;
}

// F_PB_SELFTEST_TriggerManual — arm a mapreg trigger and wait
// Args: .@trigger_key$, .@trigger_value
function	script	F_PB_SELFTEST_TriggerManual	{
    .@trigger_key$ = getarg(0);
    .@trigger_value = getarg(1);
    setd .@trigger_key$, .@trigger_value;
    return;
}

// F_PB_DB_InspectBot — query and display bot runtime state
// Args: .@bot_key$
function	script	F_PB_DB_InspectBot	{
    .@bot_key$ = getarg(0);
    // ... query headless_pc_runtime, format output
    return;
}

// F_PB_DB_QueryTraceRecent — show recent trace events
// Args: .@bot_id, .@limit
function	script	F_PB_DB_QueryTraceRecent	{
    // ... query bot_trace_event
    return;
}
```

### Impact

New selftest scripts drop from ~80–100 lines to ~30–40 lines of unique logic.

---

## 4. SQL Schema Patterns

Source: `sql-files/main.sql` (lines 1163–1734)

These patterns should be followed when adding new tables for behavior-phase
work. Do not create the tables yet — document the conventions so future schema
additions are consistent.

### Identity Triple

Eight or more tables use the same identity columns:

```sql
`bot_id` int(11) NOT NULL,
`char_id` int(11) unsigned NOT NULL DEFAULT '0',
`account_id` int(11) unsigned NOT NULL DEFAULT '0',
```

Every bot-related table should include this triple and index on `bot_id`.

### Timestamp Conventions

- **Mutable state tables**: use `updated_at datetime DEFAULT NULL`
- **Append-only / audit tables**: use `ts int(10) unsigned NOT NULL DEFAULT '0'`

Do not mix these within a single table.

### Audit Table Template

```sql
CREATE TABLE IF NOT EXISTS `bot_<domain>_audit` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ts` int(10) unsigned NOT NULL DEFAULT '0',
  `bot_id` int(11) NOT NULL,
  `char_id` int(11) unsigned NOT NULL DEFAULT '0',
  `account_id` int(11) unsigned NOT NULL DEFAULT '0',
  `action` varchar(32) NOT NULL DEFAULT '',
  `result` varchar(16) NOT NULL DEFAULT '',
  `detail` text,
  PRIMARY KEY (`id`),
  KEY `idx_bot_ts` (`bot_id`, `ts`)
) ENGINE=MyISAM AUTO_INCREMENT=1;
```

### Controller Content Template

```sql
CREATE TABLE IF NOT EXISTS `bot_<domain>_content` (
  `set_key` varchar(32) NOT NULL DEFAULT '',
  `element_index` smallint(5) unsigned NOT NULL DEFAULT '0',
  -- domain-specific columns --
  PRIMARY KEY (`set_key`, `element_index`)
) ENGINE=MyISAM;
```

### Activity Log Template

```sql
CREATE TABLE IF NOT EXISTS `bot_<domain>_activity_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `ts` int(10) unsigned NOT NULL DEFAULT '0',
  `bot_id` int(11) NOT NULL,
  `scope` varchar(32) NOT NULL DEFAULT '',
  `activity_type` varchar(32) NOT NULL DEFAULT '',
  `activity_units` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_bot_ts` (`bot_id`, `ts`)
) ENGINE=MyISAM AUTO_INCREMENT=1;
```

---

## 5. Development Workflow Recipes

### Adding a New Buildin

1. Copy the standard buildin template from Section 1
2. Use `playerbot_online_session_by_key()` for session lookup
3. Use `playerbot_trace_interaction()` or `playerbot_trace_combat()` for telemetry
4. Register in `script.cpp` `script_def` array
5. Add to `src/custom/script_def.inc` if using the custom hook pattern
6. Rebuild: `cmake --build build -j$(nproc)`
7. Validate: restart servers, call from NPC script, check `bot_trace_event`

### Adding a New Smoke Script

1. Source `tools/ci/playerbot-common.sh` (once created)
2. Call `setup_repo_root` and `setup_db_config`
3. Use `arm_test` to set mapreg triggers
4. Use `launch_kore_session` for OpenKore sessions
5. Use `wait_for_pattern` for result polling
6. Use `validate_signals` for pass/fail checks
7. Add to scenario catalog in `tools/ci/playerbot-scenario-catalog.sh`

### Adding a New NPC Selftest

1. Create in `npc/custom/playerbot/`
2. Use shared functions from `_common.txt` or `_selftest_common.txt`
3. Follow the manual-trigger pattern (mapreg arm → NPC poll → execute → report)
4. Add to `npc/scripts_custom.conf`
5. Validate: `@reloadscript`, trigger manually, check output

### Adding a New SQL Table

1. Follow identity triple + timestamp convention from Section 4
2. Add to `sql-files/main.sql` in the bot/headless section
3. Create a versioned upgrade file in `sql-files/upgrades/`
4. Update `doc/project/bot-state-schema.md` if the table carries state

---

# Part B: Next-Phase Architecture Patterns

## 6. Behavior Engine Architecture

### Design Basis

The playerbot behavior engine should adapt the mob AI FSM model from
`mob_ai_sub_hard()` (src/map/mob.cpp:1841–2220). The mob AI uses a state
machine with transitions:

```
MSS_IDLE → MSS_WALK → MSS_RUSH → MSS_BERSERK → MSS_ANGRY
```

The playerbot equivalent extends this to richer states:

```
IDLE → PATROL → FOLLOW → TRADING → CRAFTING → COMBAT → FLEEING → RESTING → SOCIALIZING
```

### Decision Loop Template

Adapted from `mob_ai_sub_hard` (lines 1841–2220):

```
1. Check if behavior is locked
   (skill casting, trade session, NPC dialog, loading screen)

2. Validate current goal
   (target still alive, objective still reachable, session still valid)

3. Evaluate interrupts
   (took damage, party member needs help, schedule change, operator command)

4. If no goal: run behavior selection
   (weighted action list → precondition filter → permillage roll → select)

5. Execute selected behavior
   (call into existing rAthena functions: unit_walktobl, unit_attack, etc.)

6. Emit trace event
   (playerbot_trace_interaction or playerbot_trace_combat)
```

### Existing Functions to Reuse

These are proven rAthena internals the behavior engine should call rather than
reimplement:

| Function | Location | Purpose |
|----------|----------|---------|
| `unit_walktobl()` | unit.cpp:950 | Movement with target tracking |
| `unit_attack()` | unit.cpp:2902 | Attack initiation |
| `unit_can_move()` | unit.cpp:1799 | Movement validation |
| `battle_check_target()` | battle.cpp:7981 | Target hostility check |
| `battle_check_range()` | battle.cpp:8327 | Range validation |
| `status_check_skilluse()` | status.cpp:2040 | Skill usability check |
| `skill_castend_pos2()` | skill.cpp | Ground-targeted skill execution |
| `skill_castend_damage_id()` | skill.cpp | Single-target damage skill |
| `pc_useitem()` | pc.cpp | Item consumption |
| `clif_emotion()` | clif.cpp | Emote display |

---

## 7. Weighted Decision / Action Selection System

### Design Basis

rAthena uses permillage-weighted selection in `mobskill_use()`
(src/map/mob.cpp:4275–4530). Each possible action has a weight from 0 to 10000.
Selection logic:

```cpp
if (rnd() % 10000 > action.permillage)
    continue;  // skip this action
```

Actions are filtered by current state, cooldown timers, and preconditions
before the weight roll.

### Playerbot Behavior Entry Structure

```
bot_behavior_entry:
  behavior_id       — unique identifier
  bot_role           — which roles can use this (merchant, social, combat, etc.)
  state_mask         — which FSM states allow this behavior
  permillage         — probability weight (0–10000)
  cooldown_ms        — minimum time between executions
  priority           — tiebreaker when multiple behaviors pass the roll
  preconditions[]    — list of conditions that must all be true
  action             — what to do (walk, attack, cast, trade, chat, etc.)
  action_params      — action-specific parameters (target type, skill id, etc.)
```

### Precondition Types

Adapted from the MSC_* condition enum (mob.cpp:4318–4382):

| Condition | rAthena Equivalent | Playerbot Use |
|-----------|-------------------|---------------|
| HP below threshold | MSC_MYHPLTMAXRATE | Flee, heal, use potion |
| HP in range | MSC_MYHPINRATE | Stay fighting vs. disengage |
| SP below threshold | (derived) | Stop casting, use SP item |
| Status active | MSC_MYSTATUSON | React to own buff/debuff |
| Status inactive | MSC_MYSTATUSOFF | Rebuff when buff expires |
| Ally HP below threshold | MSC_FRIENDHPLTMAXRATE | Support heal, party assist |
| Ally status active | MSC_FRIENDSTATUSON | Cleanse ally debuffs |
| Ally status inactive | MSC_FRIENDSTATUSOFF | Buff ally |
| Nearby enemy count > N | MSC_ATTACKPCGT | Retreat if outnumbered |
| Nearby ally count < N | MSC_SLAVELT | Call for help |
| After using skill | MSC_AFTERSKILL | Skill combos, follow-up actions |
| Target unreachable | MSC_RUDEATTACKED | Disengage, find new target |
| Time of day | (new) | Routine / schedule behavior |
| Map demand level | (new) | Respond to player population |
| Inventory fullness | (new) | Restock, sell, return to storage |
| Zeny above/below threshold | (new) | Market participation decisions |
| Party role assigned | (new) | Role-specific behavior activation |
| Current map type | (new) | Town vs. field vs. dungeon behavior |

### Selection Flow

```
1. Collect all behavior entries for this bot's role
2. Filter by state_mask (current FSM state must match)
3. Filter by cooldown (last execution + cooldown_ms < now)
4. Filter by preconditions (all conditions must pass)
5. For each surviving entry: roll rnd() % 10000 against permillage
6. Among entries that pass the roll: select highest priority
7. Execute the selected action
8. Record execution timestamp for cooldown tracking
9. Emit trace event
```

---

## 8. Target Selection and Priority System

### Design Basis

rAthena's target selection in `mob_ai_sub_hard_activesearch()`
(mob.cpp:1314–1364):

1. Filter candidates by hostility (`battle_check_target`)
2. Filter by reachability (`mob_can_reach`)
3. Filter by level/strength (`MD_TARGETWEAK` — prefer weaker targets)
4. Select closest valid target

### Playerbot Adaptation: Scoring Function

Instead of closest-only selection, use a scoring function that accounts for
bot role and objectives:

```
target_score = base_priority
             + distance_penalty * -1
             + hp_ratio_bonus        (healers: lower HP ally = higher score)
             + threat_bonus          (tanks: higher-damage enemy = higher score)
             + quest_bonus           (if target matches active quest objective)
             + loot_bonus            (if target drops needed item)
             + element_bonus         (if bot has elemental advantage)
             + level_penalty         (large level gap = lower score)
```

### Role-Specific Targeting

| Role | Primary Target | Scoring Bias |
|------|---------------|--------------|
| Tank | Highest-threat enemy | +threat_bonus, +proximity to allies |
| DPS | Assist target or weakest enemy | +hp_ratio (prefer low HP), +quest_bonus |
| Healer | Lowest-HP ally | +inverse_hp_ratio, +status_severity |
| Support | Ally missing buffs | +buff_deficit, +role_priority (heal tank first) |
| Merchant | N/A (non-combat) | Disengage and flee |

### Implementation Notes

- Reuse `battle_check_target()` for hostility filtering — do not reimplement
- Reuse `path_search()` or `unit_can_reach_bl()` for reachability checks
- Score computation should be a standalone function for easy tuning
- Store scoring weights in a config table, not hardcoded, to enable RL tuning

---

## 9. Combat AI Architecture

### Layer 1: Combat State Machine

Adapted from the MSS enum (mob.hpp:92–104):

```
NONCOMBAT → ENGAGING → FIGHTING → DISENGAGING → FLEEING → RECOVERING
```

Transitions:

| From | To | Trigger |
|------|----|---------|
| NONCOMBAT | ENGAGING | Enemy detected within aggro range |
| ENGAGING | FIGHTING | Reached attack range |
| FIGHTING | DISENGAGING | HP below flee threshold |
| FIGHTING | FIGHTING | Target died, new target available |
| FIGHTING | NONCOMBAT | All targets dead, no new targets |
| DISENGAGING | FLEEING | Distance from threat < safety margin |
| FLEEING | RECOVERING | Reached safe distance or safe zone |
| RECOVERING | NONCOMBAT | HP restored above re-engage threshold |
| RECOVERING | ENGAGING | HP above threshold, threats remain |

### Layer 2: Skill Selection

Adapted from `mobskill_use()` (mob.cpp:4275–4530):

Maintain a skill priority list per bot role:

```
bot_skill_entry:
  skill_id        — rAthena skill ID
  skill_level     — level to cast at
  state_mask      — which combat states allow this skill
  permillage      — probability weight
  cooldown_ms     — minimum time between uses
  preconditions[] — HP/SP/status/range conditions
  target_type     — self, enemy, ally, ground
```

Selection follows the same flow as behavior selection (Section 7) but operates
within the combat state machine rather than the top-level behavior FSM.

### Layer 3: Party Coordination

Not present in mob AI — this is new for playerbots:

- **Role assignment**: tank / healer / DPS / support per party member
- **Threat tracking**: record which enemies target which party members
- **Assist targeting**: healer watches party HP, tank watches threat, DPS
  follows the assist target set by the party leader or tank
- **State**: stored in transient controller-local state or a lightweight
  `bot_runtime_state` table

### Layer 4: Retreat and Recovery

```
1. HP drops below flee threshold → transition to DISENGAGING
2. Move away from threat (walk toward party leader or save point)
3. Use potions or self-heal skills during RECOVERING
4. When HP exceeds re-engage threshold:
   a. If threats remain and party is fighting → re-engage
   b. Otherwise → transition to NONCOMBAT
```

---

## 10. Reinforcement Learning Integration Points

### Project Rule

From `playerbot-future-design-notes.md`:

> Core control logic should remain state machines, weighted choices,
> deterministic policy. ML is optional enhancement, not core authority.

RL layers on top of the deterministic system. It never replaces it.

### Safe Integration Points

1. **Weight tuning** — RL adjusts `permillage` values in the behavior table
   based on observed outcomes (survival rate, objective completion, zeny earned)

2. **Priority adjustment** — RL tunes target scoring weights based on combat
   success rates per target type

3. **Route optimization** — RL learns preferred patrol paths based on player
   encounter rates and objective completion frequency

4. **Market pricing** — RL adjusts buy/sell price margins based on trade
   success rates and inventory turnover

5. **Schedule optimization** — RL tunes activity routine windows based on when
   bots generate the most value (player interaction, economy throughput)

### Architecture Constraints

- RL **proposes** weight adjustments; the deterministic engine makes the final
  decision
- RL state is stored in a dedicated table (`bot_rl_weights` or similar), not
  in runtime memory
- RL updates happen **offline** (batch) or on cooldown intervals, not per-tick
- RL can be **disabled entirely** without breaking behavior — base weights
  remain valid and functional
- RL **never overrides** safety checks (movement validation, attack legality,
  session ownership, rate limits)

### Available Reward Signals

The existing telemetry infrastructure provides these signals for RL training:

| Signal Source | What It Measures |
|---------------|-----------------|
| `bot_trace_event` | Action success/failure rates by phase |
| `bot_recovery_audit` | Failure frequency and recovery patterns |
| `bot_item_audit` | Economic activity success (trades, purchases) |
| `bot_merchant_activity_log` | Vending/buying store outcomes |
| `bot_guild_activity_log` | Social participation frequency |
| HP/death from combat traces | Combat survival rate |
| Zeny delta from bank/trade | Economic performance over time |
| Map population from demand signals | Social presence effectiveness |

### Weight Table Schema

```sql
CREATE TABLE IF NOT EXISTS `bot_rl_weights` (
  `weight_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `bot_role` varchar(32) NOT NULL DEFAULT '',
  `rule_id` int(11) unsigned NOT NULL DEFAULT '0',
  `learned_permillage` smallint(5) unsigned NOT NULL DEFAULT '0',
  `confidence` float NOT NULL DEFAULT '0',
  `sample_count` int(11) unsigned NOT NULL DEFAULT '0',
  `last_updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`weight_id`),
  KEY `idx_role_rule` (`bot_role`, `rule_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1;
```

---

## 11. Behavior Family Templates

### Social / Town Behavior

```
States: IDLE, WALKING, CHATTING, EMOTING, RESTING
Triggers: nearby player count, time of day, anchor occupancy
Actions: walk to anchor, emote, overhead chat, sit/stand
```

Entry conditions:
- Bot is on a town map
- No combat or trade session active
- Schedule permits social behavior

Key behaviors:
- Walk between town anchors on a timer
- Emote when near players (permillage-gated)
- Sit at rest points during low-activity windows
- Chat using predefined phrase pools (not free-text)

### Merchant Behavior

```
States: IDLE, TRAVELING, SETTING_UP, VENDING, RESTOCKING, CLOSING
Triggers: inventory level, zeny threshold, map demand, schedule
Actions: open shop, adjust prices, close shop, travel to market, restock
```

Entry conditions:
- Bot has merchant role assigned
- Inventory contains vendable items or zeny for buying store

Key behaviors:
- Travel to designated market map
- Open vending or buying store with configured items/prices
- Monitor stock levels; close and restock when empty or full
- Respond to demand signals (more players → stay open longer)

### Combat Behavior

```
States: NONCOMBAT, ENGAGING, FIGHTING, DISENGAGING, FLEEING, RECOVERING, LOOTING
Triggers: enemy proximity, HP threshold, party assist, target death
Actions: attack, cast skill, use item, flee, loot, return to party
```

See Section 9 for the full combat AI architecture.

### Party / Support Behavior

```
States: FOLLOWING, ASSISTING, HEALING, BUFFING, COMBAT_SUPPORT
Triggers: party member HP, buff expiry, leader movement, combat start
Actions: follow leader, heal, buff, cleanse, resurrect
```

Entry conditions:
- Bot is in a party
- Bot has support role (healer, buffer, or tank)

Key behaviors:
- Follow party leader within configurable distance
- Monitor party HP; heal when any member drops below threshold
- Maintain buff rotation on party members
- Switch to combat support when party enters combat

### Travel / Courier Behavior

```
States: IDLE, TRAVELING, WAITING, DELIVERING
Triggers: route schedule, destination reached, obstacle, map change
Actions: walk route, warp, wait at checkpoint, deliver item
```

Entry conditions:
- Bot has a route assignment (waypoint list or destination)
- No higher-priority behavior active

Key behaviors:
- Follow waypoint route across maps
- Use warps and Kafra teleports for cross-map travel
- Wait at checkpoints for configurable duration
- Deliver items via trade when reaching destination

---

## 12. Data Schema Patterns for Behavior Phase

These tables should be created when the behavior phase begins. Documented here
for planning and consistency.

### `bot_behavior_rule` — Weighted Action Definitions

```sql
CREATE TABLE IF NOT EXISTS `bot_behavior_rule` (
  `rule_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `bot_role` varchar(32) NOT NULL DEFAULT '',
  `behavior_family` varchar(32) NOT NULL DEFAULT '',
  `state_mask` int(11) unsigned NOT NULL DEFAULT '0',
  `permillage` smallint(5) unsigned NOT NULL DEFAULT '5000',
  `priority` tinyint(3) unsigned NOT NULL DEFAULT '50',
  `cooldown_ms` int(11) unsigned NOT NULL DEFAULT '0',
  `action_type` varchar(32) NOT NULL DEFAULT '',
  `action_params` text,
  `enabled` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`rule_id`),
  KEY `idx_role_family` (`bot_role`, `behavior_family`)
) ENGINE=MyISAM AUTO_INCREMENT=1;
```

### `bot_behavior_condition` — Preconditions per Rule

```sql
CREATE TABLE IF NOT EXISTS `bot_behavior_condition` (
  `condition_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `rule_id` int(11) unsigned NOT NULL DEFAULT '0',
  `condition_type` varchar(32) NOT NULL DEFAULT '',
  `operator` varchar(8) NOT NULL DEFAULT '>=',
  `threshold` int(11) NOT NULL DEFAULT '0',
  `target_scope` varchar(16) NOT NULL DEFAULT 'self',
  PRIMARY KEY (`condition_id`),
  KEY `idx_rule` (`rule_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1;
```

### `bot_behavior_state` — Runtime FSM State per Bot

```sql
CREATE TABLE IF NOT EXISTS `bot_behavior_state` (
  `bot_id` int(11) NOT NULL,
  `current_state` varchar(32) NOT NULL DEFAULT 'IDLE',
  `previous_state` varchar(32) NOT NULL DEFAULT '',
  `state_entered_at` datetime DEFAULT NULL,
  `current_goal` varchar(64) NOT NULL DEFAULT '',
  `current_target_id` int(11) NOT NULL DEFAULT '0',
  `last_action_at` datetime DEFAULT NULL,
  `action_cooldowns_json` text,
  PRIMARY KEY (`bot_id`)
) ENGINE=MyISAM;
```

### `bot_rl_weights` — RL Weight Overrides

See Section 10 for the schema.

---

## Summary

### Part A Impact

| Area | Reuse Target | Time Savings |
|------|-------------|--------------|
| New buildin | Standard template + 6 shared helpers | ~30 min per buildin |
| New smoke script | `playerbot-common.sh` library | ~20 min per script |
| New NPC selftest | Shared selftest functions | ~15 min per script |
| New SQL table | Schema templates | ~10 min per table |
| New recovery path | Bundled cleanup function | ~80 lines saved per path |

### Part B Readiness

The behavior-phase architecture is grounded in three proven rAthena patterns:

1. **Mob AI FSM** — state machine with clear transitions (mob.cpp:1841)
2. **Permillage-weighted selection** — probabilistic action choice (mob.cpp:4275)
3. **MSC_* condition system** — precondition evaluation (mob.cpp:4318)

These are not hypothetical designs. They are adaptations of code that already
runs every tick for every mob on the server. The playerbot behavior engine
extends them with richer states, role awareness, party coordination, and
optional RL tuning while preserving the deterministic core.

### Project Rule Compliance

- Core control logic remains state machines and weighted choices
- ML/RL is optional enhancement, never core authority
- RL can be disabled without breaking any behavior
- All patterns documented here are consistent with
  `playerbot-future-design-notes.md` design rules
