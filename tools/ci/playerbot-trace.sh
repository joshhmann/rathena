#!/usr/bin/env bash
set -euo pipefail

# Playerbot Trace Tool
# CLI helper for inspecting bot_trace_event data
# Answers: why was a bot assigned, why did an interaction fail,
# why was a reservation denied, why was a bot parked or reconciled

DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-rathena}
DB_USER=${DB_USER:-rathena}
DB_PASS=${DB_PASS:-rathena_secure_2024}

# Default limits
DEFAULT_LIMIT=20
MAX_LIMIT=200

usage() {
	cat <<'EOF'
Usage: tools/ci/playerbot-trace.sh [options] [command]

Playerbot Trace Tool - Inspect structured trace events from bot_trace_event

COMMANDS:
  recent [N]                 Show N most recent traces (default: 20)
  failures [N]               Show N most recent failures only
  bot <bot_id|char_id> [N]   Show timeline for a specific bot
  controller <id> [N]        Show timeline for a specific controller
  map <map_name> [N]         Show traces for a specific map
  action <action_name> [N]   Show traces for a specific action type
  why-assigned <bot_id>      Explain why a bot was assigned
  why-failed <bot_id>        Explain recent failures for a bot
  why-parked <bot_id>        Explain why a bot was parked
  stats                      Show aggregate statistics
  
ACTION FILTERS:
  controller.assigned, controller.released
  scheduler.spawned, scheduler.parked
  move.started, move.completed, move.failed
  interaction.requested, interaction.completed, interaction.failed
  reservation.acquired, reservation.denied, reservation.released
  reconcile.started, reconcile.fixed, reconcile.failed

OPTIONS:
  -l, --limit N              Limit results to N rows (max: 200)
  -s, --since MINUTES        Only show traces from last N minutes
  -r, --reason CODE          Filter by reason_code
  --result RESULT            Filter by result (ok, denied, failed, etc.)
  --raw                      Output raw SQL results (tab-separated)
  --no-color                 Disable colorized output
  -h, --help                 Show this help

EXAMPLES:
  # Recent traces
  tools/ci/playerbot-trace.sh recent
  
  # Recent failures
  tools/ci/playerbot-trace.sh failures 50
  
  # Timeline for a bot (by char_id)
  tools/ci/playerbot-trace.sh bot 150010
  
  # Timeline for a bot (by bot_id)
  tools/ci/playerbot-trace.sh bot 1
  
  # Controller timeline
  tools/ci/playerbot-trace.sh controller "social.prontera"
  
  # Why was this bot assigned?
  tools/ci/playerbot-trace.sh why-assigned 150010
  
  # Recent failures for a bot
  tools/ci/playerbot-trace.sh why-failed 150010
  
  # Filter by action with time window
  tools/ci/playerbot-trace.sh action "interaction.failed" -s 60
  
  # Raw output for scripting
  tools/ci/playerbot-trace.sh recent --raw -l 100

ENVIRONMENT:
  DB_HOST, DB_NAME, DB_USER, DB_PASS  Database connection settings
EOF
}

# Parse global options
limit=$DEFAULT_LIMIT
since_minutes=0
reason_filter=""
result_filter=""
raw_output=0
no_color=0

while [[ $# -gt 0 ]]; do
	case "$1" in
		-l|--limit)
			limit="${2:-$DEFAULT_LIMIT}"
			shift 2
			;;
		-s|--since)
			since_minutes="${2:-0}"
			shift 2
			;;
		-r|--reason)
			reason_filter="${2:-}"
			shift 2
			;;
		--result)
			result_filter="${2:-}"
			shift 2
			;;
		--raw)
			raw_output=1
			shift
			;;
		--no-color)
			no_color=1
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		-*)
			echo "Unknown option: $1" >&2
			usage >&2
			exit 1
			;;
		*)
			break
			;;
	esac
done

# Validate limit
if [[ "$limit" -gt "$MAX_LIMIT" ]]; then
	limit=$MAX_LIMIT
fi

# Colors
if [[ "$no_color" -eq 0 && -t 1 ]]; then
	C_RESET='\033[0m'
	C_BOLD='\033[1m'
	C_DIM='\033[2m'
	C_UNDERLINE='\033[4m'
	C_RED='\033[31m'
	C_GREEN='\033[32m'
	C_YELLOW='\033[33m'
	C_BLUE='\033[34m'
	C_MAGENTA='\033[35m'
	C_CYAN='\033[36m'
else
	C_RESET=''
	C_BOLD=''
	C_DIM=''
	C_UNDERLINE=''
	C_RED=''
	C_GREEN=''
	C_YELLOW=''
	C_BLUE=''
	C_MAGENTA=''
	C_CYAN=''
fi

# Build WHERE clause for filters
build_filters() {
	local where="1=1"
	
	if [[ "$since_minutes" -gt 0 ]]; then
		where="$where AND ts >= UNIX_TIMESTAMP(NOW() - INTERVAL $since_minutes MINUTE)"
	fi
	
	if [[ -n "$reason_filter" ]]; then
		where="$where AND reason_code = '$reason_filter'"
	fi
	
	if [[ -n "$result_filter" ]]; then
		where="$where AND result = '$result_filter'"
	fi
	
	echo "$where"
}

# Execute query
query() {
	local sql="$1"
	mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$sql" 2>/dev/null
}

# Format timestamp
format_ts() {
	local ts="$1"
	date -d "@$ts" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$ts"
}

# Get bot info from char_id or bot_id
resolve_bot() {
	local id="$1"
	local sql
	
	# Try as char_id first via bot_identity_link
	sql="SELECT p.bot_id, p.bot_key, l.char_id 
		 FROM bot_profile p 
		 JOIN bot_identity_link l ON l.bot_id = p.bot_id 
		 WHERE l.char_id = '$id' 
		 LIMIT 1"
	local result=$(query "$sql" | tail -n +2)
	
	if [[ -z "$result" ]]; then
		# Try as bot_id
		sql="SELECT p.bot_id, p.bot_key, l.char_id 
			 FROM bot_profile p 
			 JOIN bot_identity_link l ON l.bot_id = p.bot_id 
			 WHERE p.bot_id = '$id' 
			 LIMIT 1"
		result=$(query "$sql" | tail -n +2)
	fi
	
	echo "$result"
}

# Print trace row in human format
print_trace_row() {
	local ts="$1"
	local action="$2"
	local controller="$3"
	local map_name="$4"
	local x="$5"
	local y="$6"
	local reason="$7"
	local result="$8"
	local error_code="$9"
	local char_id="${10}"
	local bot_key="${11}"
	
	local ts_fmt
	ts_fmt=$(format_ts "$ts")
	
	# Color result
	local result_color="$C_RESET"
	case "$result" in
		ok|noop) result_color="$C_GREEN" ;;
		denied|aborted|failed) result_color="$C_RED" ;;
		retry|fallback|timeout) result_color="$C_YELLOW" ;;
		desynced|fatal) result_color="$C_MAGENTA" ;;
	esac
	
	# Format location
	local loc="${map_name}(${x},${y})"
	
	# Format bot identifier
	local bot_id="${bot_key:-$char_id}"
	
	printf "${C_DIM}%s${C_RESET}  " "$ts_fmt"
	printf "${C_BOLD}%-25s${C_RESET}  " "$action"
	printf "${C_CYAN}%-20s${C_RESET}  " "$bot_id"
	printf "${C_BLUE}%-18s${C_RESET}  " "$controller"
	printf "%s  " "$loc"
	printf "${result_color}%-8s${C_RESET}" "$result"
	
	if [[ -n "$reason" && "$reason" != "none" ]]; then
		printf "  [${C_YELLOW}%s${C_RESET}]" "$reason"
	fi
	
	if [[ -n "$error_code" ]]; then
		printf "  (${C_RED}%s${C_RESET})" "$error_code"
	fi
	
	printf "\n"
}

# Print header
print_header() {
	if [[ "$raw_output" -eq 1 ]]; then
		return
	fi
	printf "${C_BOLD}${C_UNDERLINE}%-19s  %-25s  %-20s  %-18s  %-20s  %-8s  %s${C_RESET}\n" \
		"TIMESTAMP" "ACTION" "BOT" "CONTROLLER" "LOCATION" "RESULT" "DETAILS"
}

# Recent traces command
cmd_recent() {
	local n="${1:-$limit}"
	local where
	where=$(build_filters)
	
	local sql="SELECT ts, action, controller_id, map_name, x, y, reason_code, result, error_code, char_id, '' 
			   FROM bot_trace_event 
			   WHERE $where 
			   ORDER BY id DESC 
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Recent %d Trace Events${C_RESET}\n\n" "$n"
	print_header
	
	local count=0
	while IFS=$'\t' read -r ts action controller map_name x y reason result error_code char_id bot_key; do
		print_trace_row "$ts" "$action" "$controller" "$map_name" "$x" "$y" "$reason" "$result" "$error_code" "$char_id" "$bot_key"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	printf "\n${C_DIM}Showing %d rows${C_RESET}\n" "$count"
}

# Failures command
cmd_failures() {
	local n="${1:-$limit}"
	local where
	where=$(build_filters)
	
	local sql="SELECT ts, action, controller_id, map_name, x, y, reason_code, result, error_code, char_id, '' 
			   FROM bot_trace_event 
			   WHERE $where AND result NOT IN ('ok', 'noop') 
			   ORDER BY id DESC 
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}${C_RED}Recent %d Failed Trace Events${C_RESET}\n\n" "$n"
	print_header
	
	local count=0
	while IFS=$'\t' read -r ts action controller map_name x y reason result error_code char_id bot_key; do
		print_trace_row "$ts" "$action" "$controller" "$map_name" "$x" "$y" "$reason" "$result" "$error_code" "$char_id" "$bot_key"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	printf "\n${C_DIM}Showing %d rows${C_RESET}\n" "$count"
}

# Bot timeline command
cmd_bot() {
	local id="$1"
	local n="${2:-$limit}"
	
	local bot_info
	bot_info=$(resolve_bot "$id")
	local bot_id=$(echo "$bot_info" | cut -f1)
	local bot_key=$(echo "$bot_info" | cut -f2)
	local char_id=$(echo "$bot_info" | cut -f3)
	
	if [[ -z "$bot_id" ]]; then
		echo "Error: Bot not found: $id" >&2
		exit 1
	fi
	
	local where="char_id = '$char_id'"
	if [[ "$since_minutes" -gt 0 ]]; then
		where="$where AND ts >= UNIX_TIMESTAMP(NOW() - INTERVAL $since_minutes MINUTE)"
	fi
	
	local sql="SELECT ts, action, controller_id, map_name, x, y, reason_code, result, error_code, char_id, 
			   (SELECT p.bot_key FROM bot_profile p JOIN bot_identity_link l2 ON l2.bot_id = p.bot_id WHERE l2.char_id = bot_trace_event.char_id LIMIT 1) 
			   FROM bot_trace_event 
			   WHERE $where 
			   ORDER BY id DESC 
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Bot Timeline: %s (char_id: %s, bot_id: %s)${C_RESET}\n\n" "$bot_key" "$char_id" "$bot_id"
	print_header
	
	local count=0
	while IFS=$'\t' read -r ts action controller map_name x y reason result error_code char_id bot_key; do
		print_trace_row "$ts" "$action" "$controller" "$map_name" "$x" "$y" "$reason" "$result" "$error_code" "$char_id" "$bot_key"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	printf "\n${C_DIM}Showing %d rows${C_RESET}\n" "$count"
}

# Controller timeline command
cmd_controller() {
	local controller_id="$1"
	local n="${2:-$limit}"
	
	local where="controller_id = '$controller_id'"
	if [[ "$since_minutes" -gt 0 ]]; then
		where="$where AND ts >= UNIX_TIMESTAMP(NOW() - INTERVAL $since_minutes MINUTE)"
	fi
	
	local sql="SELECT ts, action, controller_id, map_name, x, y, reason_code, result, error_code, char_id,
			   (SELECT p.bot_key FROM bot_profile p JOIN bot_identity_link l ON l.bot_id = p.bot_id WHERE l.char_id = bot_trace_event.char_id LIMIT 1)
			   FROM bot_trace_event 
			   WHERE $where 
			   ORDER BY id DESC 
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Controller Timeline: %s${C_RESET}\n\n" "$controller_id"
	print_header
	
	local count=0
	while IFS=$'\t' read -r ts action controller map_name x y reason result error_code char_id bot_key; do
		print_trace_row "$ts" "$action" "$controller" "$map_name" "$x" "$y" "$reason" "$result" "$error_code" "$char_id" "$bot_key"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	printf "\n${C_DIM}Showing %d rows${C_RESET}\n" "$count"
}

# Map traces command
cmd_map() {
	local map_name="$1"
	local n="${2:-$limit}"
	
	local where="map_name = '$map_name'"
	if [[ "$since_minutes" -gt 0 ]]; then
		where="$where AND ts >= UNIX_TIMESTAMP(NOW() - INTERVAL $since_minutes MINUTE)"
	fi
	
	local sql="SELECT ts, action, controller_id, map_name, x, y, reason_code, result, error_code, char_id,
			   (SELECT p.bot_key FROM bot_profile p JOIN bot_identity_link l ON l.bot_id = p.bot_id WHERE l.char_id = bot_trace_event.char_id LIMIT 1)
			   FROM bot_trace_event 
			   WHERE $where 
			   ORDER BY id DESC 
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Map Traces: %s${C_RESET}\n\n" "$map_name"
	print_header
	
	local count=0
	while IFS=$'\t' read -r ts action controller map_name x y reason result error_code char_id bot_key; do
		print_trace_row "$ts" "$action" "$controller" "$map_name" "$x" "$y" "$reason" "$result" "$error_code" "$char_id" "$bot_key"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	printf "\n${C_DIM}Showing %d rows${C_RESET}\n" "$count"
}

# Action filter command
cmd_action() {
	local action="$1"
	local n="${2:-$limit}"
	
	local where
	where=$(build_filters)
	where="$where AND action = '$action'"
	
	local sql="SELECT ts, action, controller_id, map_name, x, y, reason_code, result, error_code, char_id,
			   (SELECT p.bot_key FROM bot_profile p JOIN bot_identity_link l ON l.bot_id = p.bot_id WHERE l.char_id = bot_trace_event.char_id LIMIT 1)
			   FROM bot_trace_event 
			   WHERE $where 
			   ORDER BY id DESC 
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Action Filter: %s${C_RESET}\n\n" "$action"
	print_header
	
	local count=0
	while IFS=$'\t' read -r ts action controller map_name x y reason result error_code char_id bot_key; do
		print_trace_row "$ts" "$action" "$controller" "$map_name" "$x" "$y" "$reason" "$result" "$error_code" "$char_id" "$bot_key"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	printf "\n${C_DIM}Showing %d rows${C_RESET}\n" "$count"
}

# Why assigned command - explains assignment decisions
cmd_why_assigned() {
	local id="$1"
	
	local bot_info
	bot_info=$(resolve_bot "$id")
	local bot_id=$(echo "$bot_info" | cut -f1)
	local bot_key=$(echo "$bot_info" | cut -f2)
	local char_id=$(echo "$bot_info" | cut -f3)
	
	if [[ -z "$bot_id" ]]; then
		echo "Error: Bot not found: $id" >&2
		exit 1
	fi
	
	printf "${C_BOLD}Why Assigned Analysis: %s${C_RESET}\n\n" "$bot_key"
	
	# Find most recent controller.assigned event
	local sql="SELECT ts, controller_id, reason_code, map_name, x, y, inputs
			   FROM bot_trace_event 
			   WHERE char_id = '$char_id' AND action = 'controller.assigned' 
			   ORDER BY id DESC 
			   LIMIT 5"
	
	printf "${C_BOLD}Recent Controller Assignments:${C_RESET}\n"
	local found=0
	while IFS=$'\t' read -r ts controller_id reason_code map_name x y inputs; do
		found=1
		printf "\n  ${C_DIM}%s${C_RESET}\n" "$(format_ts "$ts")"
		printf "  Controller: ${C_CYAN}%s${C_RESET}\n" "$controller_id"
		printf "  Location: %s(%s, %s)\n" "$map_name" "$x" "$y"
		printf "  Reason: ${C_YELLOW}%s${C_RESET}\n" "$reason_code"
		if [[ -n "$inputs" ]]; then
			printf "  Inputs: %s\n" "$inputs"
		fi
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "  ${C_DIM}No controller.assigned events found${C_RESET}\n"
	fi
	
	# Also show scheduler.spawned events
	printf "\n${BOLD}Related Scheduler Spawn Events:${RESET}\n"
	sql="SELECT ts, controller_id, reason_code, map_name 
		 FROM bot_trace_event 
		 WHERE char_id = '$char_id' AND action = 'scheduler.spawned' 
		 ORDER BY id DESC 
		 LIMIT 3"
	
	found=0
	while IFS=$'\t' read -r ts controller_id reason_code map_name; do
		found=1
		printf "  ${C_DIM}%s${C_RESET} - %s on %s (${C_YELLOW}%s${C_RESET})\n" \
			"$(format_ts "$ts")" "$controller_id" "$map_name" "$reason_code"
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "  ${C_DIM}No scheduler.spawned events found${C_RESET}\n"
	fi
}

# Why failed command - explains recent failures
cmd_why_failed() {
	local id="$1"
	
	local bot_info
	bot_info=$(resolve_bot "$id")
	local bot_id=$(echo "$bot_info" | cut -f1)
	local bot_key=$(echo "$bot_info" | cut -f2)
	local char_id=$(echo "$bot_info" | cut -f3)
	
	if [[ -z "$bot_id" ]]; then
		echo "Error: Bot not found: $id" >&2
		exit 1
	fi
	
	printf "${C_BOLD}${C_RED}Failure Analysis: %s${C_RESET}\n\n" "$bot_key"
	
	# Group failures by action and reason
	local sql="SELECT action, reason_code, result, error_code, COUNT(*) as cnt, MAX(ts) as last_ts
			   FROM bot_trace_event 
			   WHERE char_id = '$char_id' AND result NOT IN ('ok', 'noop') 
			   GROUP BY action, reason_code, result, error_code
			   ORDER BY cnt DESC, last_ts DESC
			   LIMIT 10"
	
	printf "${C_BOLD}Failure Summary (grouped by action/reason):${C_RESET}\n\n"
	printf "  %-30s  %-25s  %-10s  %-20s  %s\n" "ACTION" "REASON" "RESULT" "ERROR" "COUNT"
	printf "  %s\n" "$(printf '%.0s-' {1..120})"
	
	local found=0
	while IFS=$'\t' read -r action reason_code result error_code cnt last_ts; do
		found=1
		printf "  %-30s  ${C_YELLOW}%-25s${C_RESET}  ${C_RED}%-10s${C_RESET}  %-20s  %s\n" \
			"$action" "$reason_code" "$result" "$error_code" "$cnt"
		printf "  ${C_DIM}Last: %s${C_RESET}\n\n" "$(format_ts "$last_ts")"
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "  ${C_GREEN}No failures found for this bot!${C_RESET}\n"
	else
		# Show recent failure details
		printf "\n${C_BOLD}Most Recent Failure Details:${C_RESET}\n"
		sql="SELECT ts, action, controller_id, map_name, x, y, reason_code, result, error_code, error_detail
			 FROM bot_trace_event 
			 WHERE char_id = '$char_id' AND result NOT IN ('ok', 'noop') 
			 ORDER BY id DESC 
			 LIMIT 1"
		
		while IFS=$'\t' read -r ts action controller_id map_name x y reason_code result error_code error_detail; do
			printf "\n  ${C_DIM}Time:${C_RESET}        %s\n" "$(format_ts "$ts")"
			printf "  ${C_DIM}Action:${C_RESET}      %s\n" "$action"
			printf "  ${C_DIM}Controller:${C_RESET}  %s\n" "$controller_id"
			printf "  ${C_DIM}Location:${C_RESET}    %s(%s, %s)\n" "$map_name" "$x" "$y"
			printf "  ${C_DIM}Reason:${C_RESET}      ${C_YELLOW}%s${C_RESET}\n" "$reason_code"
			printf "  ${C_DIM}Result:${C_RESET}      ${C_RED}%s${C_RESET}\n" "$result"
			printf "  ${C_DIM}Error Code:${C_RESET}  %s\n" "$error_code"
			if [[ -n "$error_detail" ]]; then
				printf "  ${C_DIM}Detail:${C_RESET}      %s\n" "$error_detail"
			fi
		done < <(query "$sql" | tail -n +2)
	fi
}

# Why parked command - explains parking decisions
cmd_why_parked() {
	local id="$1"
	
	local bot_info
	bot_info=$(resolve_bot "$id")
	local bot_id=$(echo "$bot_info" | cut -f1)
	local bot_key=$(echo "$bot_info" | cut -f2)
	local char_id=$(echo "$bot_info" | cut -f3)
	
	if [[ -z "$bot_id" ]]; then
		echo "Error: Bot not found: $id" >&2
		exit 1
	fi
	
	printf "${C_BOLD}Why Parked Analysis: %s${C_RESET}\n\n" "$bot_key"
	
	# Find most recent scheduler.parked event
	local sql="SELECT ts, controller_id, reason_code, map_name, x, y, inputs, signals
			   FROM bot_trace_event 
			   WHERE char_id = '$char_id' AND action = 'scheduler.parked' 
			   ORDER BY id DESC 
			   LIMIT 3"
	
	printf "${C_BOLD}Recent Park Events:${C_RESET}\n"
	local found=0
	while IFS=$'\t' read -r ts controller_id reason_code map_name x y inputs signals; do
		found=1
		printf "\n  ${C_DIM}Parked at: %s${C_RESET}\n" "$(format_ts "$ts")"
		printf "  Controller: ${C_CYAN}%s${C_RESET}\n" "$controller_id"
		printf "  Final Location: %s(%s, %s)\n" "$map_name" "$x" "$y"
		printf "  Reason: ${C_YELLOW}%s${C_RESET}\n" "$reason_code"
		if [[ -n "$inputs" ]]; then
			printf "  Inputs: %s\n" "$inputs"
		fi
		if [[ -n "$signals" ]]; then
			printf "  Signals: %s\n" "$signals"
		fi
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "  ${C_DIM}No scheduler.parked events found${C_RESET}\n"
	fi
	
	# Show controller.released events
	printf "\n${C_BOLD}Controller Release Events:${C_RESET}\n"
	sql="SELECT ts, controller_id, reason_code, result 
		 FROM bot_trace_event 
		 WHERE char_id = '$char_id' AND action = 'controller.released' 
		 ORDER BY id DESC 
		 LIMIT 3"
	
	found=0
	while IFS=$'\t' read -r ts controller_id reason_code result; do
		found=1
		printf "  ${C_DIM}%s${C_RESET} - %s (${C_YELLOW}%s${C_RESET}) -> %s\n" \
			"$(format_ts "$ts")" "$controller_id" "$reason_code" "$result"
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "  ${C_DIM}No controller.released events found${C_RESET}\n"
	fi
}

# Stats command
cmd_stats() {
	printf "${C_BOLD}Playerbot Trace Statistics${C_RESET}\n\n"
	
	# Total events
	local total=$(query "SELECT COUNT(*) FROM bot_trace_event" | tail -n +2)
	printf "Total Events: ${C_BOLD}%s${C_RESET}\n\n" "$total"
	
	# Events by phase
	printf "${C_BOLD}Events by Phase:${C_RESET}\n"
	local sql="SELECT phase, COUNT(*) as cnt 
			   FROM bot_trace_event 
			   GROUP BY phase 
			   ORDER BY cnt DESC"
	while IFS=$'\t' read -r phase cnt; do
		printf "  %-20s  %6s\n" "$phase" "$cnt"
	done < <(query "$sql" | tail -n +2)
	
	# Recent failures by action
	printf "\n${C_BOLD}Recent Failures by Action (last hour):${C_RESET}\n"
	sql="SELECT action, COUNT(*) as cnt 
		 FROM bot_trace_event 
		 WHERE result NOT IN ('ok', 'noop') AND ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 1 HOUR)
		 GROUP BY action 
		 ORDER BY cnt DESC 
		 LIMIT 10"
	while IFS=$'\t' read -r action cnt; do
		printf "  ${C_RED}%-40s  %6s${C_RESET}\n" "$action" "$cnt"
	done < <(query "$sql" | tail -n +2)
	
	# Top controllers by event count
	printf "\n${C_BOLD}Top Controllers by Event Count:${C_RESET}\n"
	sql="SELECT controller_id, COUNT(*) as cnt 
		 FROM bot_trace_event 
		 WHERE controller_id != ''
		 GROUP BY controller_id 
		 ORDER BY cnt DESC 
		 LIMIT 10"
	while IFS=$'\t' read -r controller cnt; do
		printf "  %-40s  %6s\n" "$controller" "$cnt"
	done < <(query "$sql" | tail -n +2)
}

# Main dispatcher
cmd="${1:-recent}"
shift || true

case "$cmd" in
	recent)
		cmd_recent "$@"
		;;
	failures)
		cmd_failures "$@"
		;;
	bot)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-trace.sh bot <bot_id|char_id> [limit]" >&2
			exit 1
		fi
		cmd_bot "$@"
		;;
	controller)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-trace.sh controller <controller_id> [limit]" >&2
			exit 1
		fi
		cmd_controller "$@"
		;;
	map)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-trace.sh map <map_name> [limit]" >&2
			exit 1
		fi
		cmd_map "$@"
		;;
	action)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-trace.sh action <action_name> [limit]" >&2
			exit 1
		fi
		cmd_action "$@"
		;;
	why-assigned)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-trace.sh why-assigned <bot_id|char_id>" >&2
			exit 1
		fi
		cmd_why_assigned "$@"
		;;
	why-failed)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-trace.sh why-failed <bot_id|char_id>" >&2
			exit 1
		fi
		cmd_why_failed "$@"
		;;
	why-parked)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-trace.sh why-parked <bot_id|char_id>" >&2
			exit 1
		fi
		cmd_why_parked "$@"
		;;
	stats)
		cmd_stats
		;;
	-h|--help|help)
		usage
		exit 0
		;;
	*)
		echo "Unknown command: $cmd" >&2
		usage >&2
		exit 1
		;;
esac
