# Playerbot Trace Tooling

CLI and operator tooling for inspecting `bot_trace_event` data. This tooling
answers the key operator questions:

- Why was a bot assigned?
- Why did an interaction fail?
- Why was a reservation denied?
- Why was a bot parked or reconciled?

## Quick Start

```bash
# Recent traces
tools/ci/playerbot-trace.sh recent

# Recent failures
tools/ci/playerbot-trace.sh failures

# Timeline for a specific bot (by char_id or bot_id)
tools/ci/playerbot-trace.sh bot 150010

# Controller timeline
tools/ci/playerbot-trace.sh controller "social.prontera"

# Why was this bot assigned?
tools/ci/playerbot-trace.sh why-assigned 150010

# Why did this bot fail recently?
tools/ci/playerbot-trace.sh why-failed 150010

# Statistics overview
tools/ci/playerbot-trace.sh stats
```

## Commands

### `recent [N]`

Show the N most recent trace events (default: 20, max: 200).

```bash
tools/ci/playerbot-trace.sh recent 50
tools/ci/playerbot-trace.sh recent --raw -l 100  # Raw output for scripting
```

### `failures [N]`

Show only failed trace events (result not 'ok' or 'noop').

```bash
tools/ci/playerbot-trace.sh failures
tools/ci/playerbot-trace.sh failures 50 --since 60  # Last hour only
```

### `bot <id> [N]`

Show timeline for a specific bot. Accepts either `bot_id` or `char_id`.

```bash
tools/ci/playerbot-trace.sh bot 150010
tools/ci/playerbot-trace.sh bot 1  # By bot_id
```

### `controller <id> [N]`

Show all traces for a specific controller.

```bash
tools/ci/playerbot-trace.sh controller "social.prontera"
tools/ci/playerbot-trace.sh controller "merchant.alberta"
```

### `map <name> [N]`

Show traces for a specific map.

```bash
tools/ci/playerbot-trace.sh map prontera
tools/ci/playerbot-trace.sh map alberta
```

### `action <name> [N]`

Filter by specific action type.

```bash
# Valid actions:
# controller.assigned, controller.released
# scheduler.spawned, scheduler.parked
# move.started, move.completed, move.failed
# interaction.requested, interaction.completed, interaction.failed
# reservation.acquired, reservation.denied, reservation.released
# reconcile.started, reconcile.fixed, reconcile.failed

tools/ci/playerbot-trace.sh action "interaction.failed"
tools/ci/playerbot-trace.sh action "reservation.denied"
```

### `why-assigned <bot_id>`

Explains why a bot was assigned to a controller, showing:
- Recent controller.assigned events
- Reason codes
- Related scheduler.spawned events

```bash
tools/ci/playerbot-trace.sh why-assigned 150010
```

### `why-failed <bot_id>`

Analyzes recent failures for a bot, showing:
- Grouped failure summary by action/reason
- Most recent failure details
- Error codes and details

```bash
tools/ci/playerbot-trace.sh why-failed 150010
```

### `why-parked <bot_id>`

Explains why a bot was parked, showing:
- Recent scheduler.parked events
- Reason codes
- Related controller.released events

```bash
tools/ci/playerbot-trace.sh why-parked 150010
```

### `stats`

Show aggregate statistics:
- Total event count
- Events by phase
- Recent failures by action (last hour)
- Top controllers by event count

```bash
tools/ci/playerbot-trace.sh stats
```

### `correlate <id1> [id2 ...]`

Interleave trace timelines for multiple bots, sorted by timestamp, with each bot color-coded.
Useful for debugging contention: two bots competing for the same anchor or dialog target will
show their `reservation.denied` / `reservation.acquired` rows interleaved by wall-clock time.

```bash
# See what two bots were doing at the same time
tools/ci/playerbot-trace.sh correlate 150010 150011

# With --json for scripting
tools/ci/playerbot-trace.sh correlate 150010 150011 --json

# Last 30 minutes only
tools/ci/playerbot-trace.sh correlate 150010 150011 -s 30
```

### `reservation <resource_key>`

Show all trace events whose `reservation_refs` column references a given resource key.
Reveals the complete history of who acquired, was denied, and released a resource.

```bash
# Full history of a specific anchor
tools/ci/playerbot-trace.sh reservation "prontera:anchor:152:179"

# Merchant spot history
tools/ci/playerbot-trace.sh reservation "alberta:merchant_spot:163:121"

# With JSON output
tools/ci/playerbot-trace.sh reservation "prontera:anchor:152:179" --json
```

For the current ledger state of a resource (who holds it now, TTL), use
`tools/ci/playerbot-reservations-inspector.sh contended <resource_key>` instead.

### `path <bot_id> [N]`

Show the N events (default: 15) immediately preceding the most recent non-ok result for a bot.
Unlike `why-failed` (which summarizes grouped failure types), `path` shows the causal sequence
— what the bot was doing in the moments before it failed.

```bash
# What was BotPc01 doing before its last failure?
tools/ci/playerbot-trace.sh path 150010

# Show more context (20 events)
tools/ci/playerbot-trace.sh path 150010 20

# With JSON output
tools/ci/playerbot-trace.sh path 150010 --json
```

## Global Options

| Option | Description |
|--------|-------------|
| `-l, --limit N` | Limit results (default: 20, max: 200) |
| `-s, --since MINUTES` | Only show traces from last N minutes |
| `-r, --reason CODE` | Filter by reason_code |
| `--result RESULT` | Filter by result (ok, denied, failed, etc.) |
| `--raw` | Output raw SQL results (tab-separated) |
| `--json` | Output as JSON array (`correlate`, `reservation`, `path`); falls back to `--raw` for other commands |
| `--no-color` | Disable colorized output |
| `-h, --help` | Show help |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | localhost | Database host |
| `DB_NAME` | rathena | Database name |
| `DB_USER` | rathena | Database user |
| `DB_PASS` | rathena_secure_2024 | Database password |

## Examples

### Debugging a Failed Interaction

```bash
# See recent failures for bot BotPc01
tools/ci/playerbot-trace.sh why-failed 150010

# Filter by interaction failures only
tools/ci/playerbot-trace.sh action "interaction.failed" --since 30

# See all failures in the last hour
tools/ci/playerbot-trace.sh failures --since 60
```

### Tracing Controller Decisions

```bash
# Why was BotPc01 assigned?
tools/ci/playerbot-trace.sh why-assigned 150010

# See timeline for Prontera social controller
tools/ci/playerbot-trace.sh controller "social.prontera" 50

# See scheduler decisions in the last 10 minutes
tools/ci/playerbot-trace.sh action "scheduler.spawned" --since 10
```

### Investigating Parking

```bash
# Why was BotPc01 parked?
tools/ci/playerbot-trace.sh why-parked 150010

# See all park events in the last hour
tools/ci/playerbot-trace.sh action "scheduler.parked" --since 60
```

### Debugging Reservation Contention Between Two Bots

```bash
# Step 1: find which resource is being contested (reservation.denied events)
tools/ci/playerbot-trace.sh action "reservation.denied" --since 10

# Step 2: get the full contention history for that resource
tools/ci/playerbot-trace.sh reservation "prontera:anchor:152:179"

# Step 3: correlate both bots to see interleaved timeline
tools/ci/playerbot-trace.sh correlate 150010 150011 -s 10

# Step 4: if one bot failed after the contention, inspect the path
tools/ci/playerbot-trace.sh path 150011
```

### Investigating a Failure With Full Context

```bash
# What was the bot doing before its last failure?
tools/ci/playerbot-trace.sh path 150010 20

# Cross-reference with the reservation that was involved
tools/ci/playerbot-trace.sh reservation "prontera:dialog_target:shop_npc_01"

# Export both as JSON for external diffing
tools/ci/playerbot-trace.sh path 150010 --json > path.json
tools/ci/playerbot-trace.sh reservation "prontera:dialog_target:shop_npc_01" --json > contention.json
```

### Raw Output for Scripting

```bash
# Get raw data for external processing
tools/ci/playerbot-trace.sh recent --raw -l 100 > traces.tsv

# Check for specific error pattern
tools/ci/playerbot-trace.sh failures --raw | grep "script.busy" | wc -l
```

## Color Legend

Output is colorized for readability:

- **Green**: Success results (ok, noop)
- **Red**: Failure results (denied, aborted, failed)
- **Yellow**: Retry/recoverable results (retry, fallback, timeout)
- **Magenta**: Serious errors (desynced, fatal)
- **Blue**: Controller IDs
- **Cyan**: Bot identifiers
- **Dim gray**: Timestamps

Use `--no-color` when piping to other tools.

## Related Documentation

- `playerbot-observability-contract.md` - Trace event schema and fields
- `playerbot-foundation-priorities.md` - Observability design principles
- `headless-pc-v1-slice-log.md` - Implementation history
- `openkore-test-harness.md` - Integration testing with OpenKore

## Related Tools

- `tools/ci/playerbot-reservations-inspector.sh` - Live reservation ledger inspection (active leases, expired rows, contention history, recovery audits)

## SQL Schema Reference

The trace tool queries `bot_trace_event`:

```sql
CREATE TABLE `bot_trace_event` (
  `id` bigint(20) unsigned NOT NULL auto_increment,
  `ts` int(10) unsigned NOT NULL,
  `trace_id` varchar(64) NOT NULL,
  `bot_id` int(10) unsigned,
  `char_id` int(10) unsigned,
  `account_id` int(10) unsigned,
  `map_id` int(10) unsigned,
  `map_name` varchar(32),
  `x` smallint(5) unsigned,
  `y` smallint(5) unsigned,
  `controller_id` varchar(64),
  `controller_kind` varchar(32),
  `owner_token` varchar(64),
  `phase` enum('controller','scheduler','move','interaction','reservation','reconcile'),
  `action` enum('controller.assigned', 'controller.released', ...),
  `target_type` varchar(32),
  `target_id` varchar(64),
  `reason_code` enum('none', 'operator.start', 'scheduler.select', ...),
  `inputs` text,
  `signals` text,
  `reservation_refs` text,
  `result` enum('ok','noop','retry','fallback','aborted','denied','timeout','desynced','fatal'),
  `duration_ms` int(10) unsigned,
  `fallback` varchar(64),
  `error_code` varchar(64),
  `error_detail` varchar(191),
  PRIMARY KEY (`id`),
  UNIQUE KEY `trace_id` (`trace_id`),
  KEY `ts` (`ts`),
  KEY `bot_id` (`bot_id`)
);
```

## Trace Event Families

The runtime emits these event types:

### Controller Events
- `controller.assigned` - Bot assigned to controller
- `controller.released` - Bot released from controller

### Scheduler Events
- `scheduler.spawned` - Bot spawned into world
- `scheduler.parked` - Bot parked/offline

### Movement Events
- `move.started` - Walk started
- `move.completed` - Walk completed
- `move.failed` - Walk failed

### Interaction Events
- `interaction.requested` - Interaction initiated
- `interaction.completed` - Interaction completed
- `interaction.failed` - Interaction failed

### Reservation Events
- `reservation.acquired` - Resource reserved
- `reservation.denied` - Reservation denied
- `reservation.released` - Reservation released

### Reconcile Events
- `reconcile.started` - Reconcile started
- `reconcile.fixed` - Reconcile fixed state
- `reconcile.failed` - Reconcile failed
