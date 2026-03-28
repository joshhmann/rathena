# Playerbot Reservation Inspector

CLI and operator tooling for inspecting `bot_reservation` data and diagnosing
contention issues. This tooling answers:

- What leases/locks are currently active?
- Who holds them?
- What is stale or expired?
- Why is contention happening?
- Which resources are hot?

## Quick Start

```bash
# Show active reservations
tools/ci/playerbot-reservations.sh active

# Show expired reservations
tools/ci/playerbot-reservations.sh expired

# Show reservations held by a bot
tools/ci/playerbot-reservations.sh holder quick_social_01

# Show most contested resources
tools/ci/playerbot-reservations.sh hot

# Explain why a resource was denied
tools/ci/playerbot-reservations.sh why-denied "npc:Kafra"

# Show statistics
tools/ci/playerbot-reservations.sh stats
```

## Commands

### `active [N]`

Show currently active reservations (lease_until > now).

```bash
tools/ci/playerbot-reservations.sh active
tools/ci/playerbot-reservations.sh active 50
tools/ci/playerbot-reservations.sh active -t dialog_target
```

### `recent [N]`

Show recent reservation trace events from `bot_trace_event`.

```bash
tools/ci/playerbot-reservations.sh recent
tools/ci/playerbot-reservations.sh recent 50 --since 60
```

### `expired [N]`

Show expired reservations (lease_until <= now). These should be cleaned up
by the reservation reaper but may linger if cleanup is delayed.

```bash
tools/ci/playerbot-reservations.sh expired
tools/ci/playerbot-reservations.sh expired --raw
```

### `stale [N]`

Show stale reservations where the holder bot no longer exists in
`bot_profile`. These are orphan reservations that need cleanup.

```bash
tools/ci/playerbot-reservations.sh stale
```

### `holder <id> [N]`

Show reservations held by a specific bot or controller. Accepts:
- Bot key (e.g., `quick_social_01`)
- Bot ID
- Controller ID (e.g., `social.prontera`)

```bash
tools/ci/playerbot-reservations.sh holder quick_social_01
tools/ci/playerbot-reservations.sh holder 42
tools/ci/playerbot-reservations.sh holder "social.prontera"
```

### `resource <key> [N]`

Show reservations for a specific resource key.

```bash
tools/ci/playerbot-reservations.sh resource "npc:Kafra"
tools/ci/playerbot-reservations.sh resource "anchor:prontera:150:180"
```

### `hot [N]`

Show the most contested resources based on reservation denial counts from
trace history.

```bash
tools/ci/playerbot-reservations.sh hot
tools/ci/playerbot-reservations.sh hot 20
```

### `denied [N]`

Show recent reservation denials from trace history.

```bash
tools/ci/playerbot-reservations.sh denied
tools/ci/playerbot-reservations.sh denied --since 30
```

### `why-denied <resource_key>`

Explain why a resource was denied by correlating current reservation state
with recent denial traces. Shows:
- Current holder (if any)
- Recent denials for this resource
- Contention pattern by controller

```bash
tools/ci/playerbot-reservations.sh why-denied "npc:Kafra"
tools/ci/playerbot-reservations.sh why-denied "anchor:prontera:150:180"
```

### `stats`

Show comprehensive reservation statistics:
- Total/active/expired counts
- Breakdown by type
- Breakdown by lock mode
- Recent trace activity
- Top holders

```bash
tools/ci/playerbot-reservations.sh stats
```

## Global Options

| Option | Description |
|--------|-------------|
| `-l, --limit N` | Limit results (default: 20, max: 200) |
| `-t, --type TYPE` | Filter by resource type |
| `-m, --mode MODE` | Filter by lock mode (`lease` or `hard_lock`) |
| `--holder-bot ID` | Filter by holder_bot_id |
| `--holder-ctl ID` | Filter by holder_controller_id |
| `--since MINUTES` | Only show traces from last N minutes |
| `--raw` | Output raw SQL results (tab-separated) |
| `--no-color` | Disable colorized output |
| `-h, --help` | Show help |

## Resource Types

The reservation system supports these resource types:

| Type | Description |
|------|-------------|
| `anchor` | Map position anchors |
| `dialog_target` | NPC/dialog targets |
| `social_target` | Social interaction targets |
| `merchant_spot` | Merchant/vending spots |
| `party_role` | Party role reservations |

## Lock Modes

| Mode | Description |
|------|-------------|
| `lease` | Time-bounded lease that expires automatically |
| `hard_lock` | Hard lock with explicit timeout |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | localhost | Database host |
| `DB_NAME` | rathena | Database name |
| `DB_USER` | rathena | Database user |
| `DB_PASS` | rathena_secure_2024 | Database password |

## Examples

### Debugging Contention

```bash
# See what's being contested
tools/ci/playerbot-reservations.sh hot 10

# Investigate a specific resource
tools/ci/playerbot-reservations.sh why-denied "npc:Kafra"

# See who's trying to claim it
tools/ci/playerbot-reservations.sh denied --since 60
```

### Finding Stale Reservations

```bash
# Check for orphaned reservations
tools/ci/playerbot-reservations.sh stale

# Check for expired but not cleaned up
tools/ci/playerbot-reservations.sh expired
```

### Monitoring Active Reservations

```bash
# Watch dialog_target reservations specifically
tools/ci/playerbot-reservations.sh active -t dialog_target

# See what a specific controller holds
tools/ci/playerbot-reservations.sh holder "social.prontera"
```

### Raw Output for Scripting

```bash
# Export active reservations for external processing
tools/ci/playerbot-reservations.sh active --raw > active_reservations.tsv

# Count hard locks
tools/ci/playerbot-reservations.sh active --raw | grep "hard_lock" | wc -l
```

## Color Legend

Output is colorized for readability:

- **Green**: Active leases, successful operations
- **Red**: Expired leases, hard locks, failures, denials
- **Yellow**: Warning states, short remaining times
- **Blue**: Anchor resources
- **Cyan**: Dialog targets, bot identifiers
- **Magenta**: Party roles
- **Dim gray**: Timestamps, metadata

Use `--no-color` when piping to other tools.

## Related Documentation

- `playerbot-reservation-model.md` - Reservation design and record schema
- `playerbot-perception-contract.md` - Shared perception facade
- `playerbot-observability-contract.md` - Trace event schema
- `playerbot-trace-tooling.md` - General trace inspection tooling
- `headless-pc-v1-slice-log.md` - Implementation history
- `headless-pc-edge-cases.md` - Edge cases and handling

## SQL Schema Reference

The inspector queries `bot_reservation`:

```sql
CREATE TABLE `bot_reservation` (
  `reservation_id` bigint(20) unsigned NOT NULL auto_increment,
  `type` enum('anchor','dialog_target','social_target','merchant_spot','party_role') NOT NULL,
  `resource_key` varchar(96) NOT NULL,
  `holder_bot_id` int(10) unsigned NOT NULL,
  `holder_controller_id` varchar(64) NOT NULL,
  `lock_mode` enum('lease','hard_lock') NOT NULL,
  `lease_until` int(10) unsigned NOT NULL,
  `epoch` int(10) unsigned NOT NULL,
  `priority` smallint(5) unsigned NOT NULL,
  `reason` varchar(64) NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  `updated_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`reservation_id`),
  UNIQUE KEY `type_resource` (`type`,`resource_key`),
  KEY `holder_bot_id` (`holder_bot_id`),
  KEY `holder_controller_id` (`holder_controller_id`),
  KEY `lease_until` (`lease_until`)
);
```

And correlates with `bot_trace_event` for denial analysis and history.

## Implementation Notes

- The inspector is read-only and does not modify reservations
- Use the in-game `Playerbot Reservation Lab` for interactive inspection
- Use this CLI tool for scripting and batch analysis
- Stale reservations (orphan holders) indicate cleanup issues
- Expired reservations should be automatically reaped
- Hard locks are shown in red to indicate stronger contention potential
