#!/usr/bin/env bash
set -euo pipefail

# Playerbot Reservation Inspector
# CLI helper for inspecting bot_reservation and reservation traces
# Answers: what leases/locks are active, who holds them, what is stale/expired,
# why contention is happening, which resources are hot

DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-rathena}
DB_USER=${DB_USER:-rathena}
DB_PASS=${DB_PASS:-rathena_secure_2024}

# Default limits
DEFAULT_LIMIT=20
MAX_LIMIT=200

usage() {
	cat <<'EOF'
Usage: tools/ci/playerbot-reservations.sh [options] [command]

Playerbot Reservation Inspector - Inspect bot_reservation and trace data

COMMANDS:
  active [N]                 Show currently active reservations
  recent [N]                 Show recent reservation trace events
  expired [N]                Show expired reservations (lease_until < now)
  stale [N]                  Show stale reservations (holder offline/invalid)
  holder <id> [N]            Show reservations held by bot/char/controller
  resource <key> [N]         Show reservations for specific resource
  hot [N]                    Show most contested resources (denial counts)
  denied [N]                 Show recent reservation denials
  why-denied <resource_key>  Explain why a resource was denied
  stats                      Show reservation statistics

RESOURCE TYPES:
  anchor, dialog_target, social_target, merchant_spot, party_role

LOCK MODES:
  lease      - Time-bounded lease
  hard_lock  - Hard lock with timeout

OPTIONS:
  -l, --limit N              Limit results to N rows (max: 200)
  -t, --type TYPE            Filter by resource type
  -m, --mode MODE            Filter by lock mode (lease|hard_lock)
  --holder-bot ID            Filter by holder_bot_id
  --holder-ctl ID            Filter by holder_controller_id
  --since MINUTES            Only show traces from last N minutes
  --raw                      Output raw SQL results (tab-separated)
  --no-color                 Disable colorized output
  -h, --help                 Show this help

EXAMPLES:
  # Show active reservations
  tools/ci/playerbot-reservations.sh active
  
  # Show expired reservations
  tools/ci/playerbot-reservations.sh expired
  
  # Show reservations held by a bot
  tools/ci/playerbot-reservations.sh holder quick_social_01
  
  # Show reservations for a specific resource
  tools/ci/playerbot-reservations.sh resource "npc:Kafra"
  
  # Show most contested resources
  tools/ci/playerbot-reservations.sh hot 10
  
  # Explain why a resource was denied
  tools/ci/playerbot-reservations.sh why-denied "anchor:prontera:150:180"
  
  # Show stats
  tools/ci/playerbot-reservations.sh stats
  
  # Filter by type
  tools/ci/playerbot-reservations.sh active -t dialog_target

ENVIRONMENT:
  DB_HOST, DB_NAME, DB_USER, DB_PASS  Database connection settings
EOF
}

# Parse global options
limit=$DEFAULT_LIMIT
since_minutes=0
res_type=""
lock_mode=""
holder_bot=""
holder_ctl=""
raw_output=0
no_color=0

while [[ $# -gt 0 ]]; do
	case "$1" in
		-l|--limit)
			limit="${2:-$DEFAULT_LIMIT}"
			shift 2
			;;
		-t|--type)
			res_type="${2:-}"
			shift 2
			;;
		-m|--mode)
			lock_mode="${2:-}"
			shift 2
			;;
		--holder-bot)
			holder_bot="${2:-}"
			shift 2
			;;
		--holder-ctl)
			holder_ctl="${2:-}"
			shift 2
			;;
		--since)
			since_minutes="${2:-0}"
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
	C_WHITE='\033[37m'
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
	C_WHITE=''
fi

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

# Format remaining time
format_remaining() {
	local lease_until="$1"
	local now
	now=$(date +%s)
	local remaining=$((lease_until - now))
	
	if [[ "$remaining" -lt 0 ]]; then
		echo "${C_RED}expired${C_RESET}"
	elif [[ "$remaining" -lt 60 ]]; then
		echo "${C_YELLOW}${remaining}s${C_RESET}"
	elif [[ "$remaining" -lt 3600 ]]; then
		echo "$((remaining / 60))m"
	else
		echo "$((remaining / 3600))h $(((remaining % 3600) / 60))m"
	fi
}

# Build WHERE clause for filters
build_filters() {
	local where="1=1"
	
	if [[ -n "$res_type" ]]; then
		where="$where AND type = '$res_type'"
	fi
	
	if [[ -n "$lock_mode" ]]; then
		where="$where AND lock_mode = '$lock_mode'"
	fi
	
	if [[ -n "$holder_bot" ]]; then
		where="$where AND holder_bot_id = '$holder_bot'"
	fi
	
	if [[ -n "$holder_ctl" ]]; then
		where="$where AND holder_controller_id = '$holder_ctl'"
	fi
	
	echo "$where"
}

# Print reservation row
print_res_row() {
	local res_id="$1"
	local type="$2"
	local resource_key="$3"
	local holder_bot_id="$4"
	local holder_ctl="$5"
	local lock_mode="$6"
	local lease_until="$7"
	local epoch="$8"
	local priority="$9"
	local reason="${10}"
	
	# Format type with color
	local type_color="$C_RESET"
	case "$type" in
		anchor) type_color="$C_BLUE" ;;
		dialog_target) type_color="$C_CYAN" ;;
		social_target) type_color="$C_GREEN" ;;
		merchant_spot) type_color="$C_YELLOW" ;;
		party_role) type_color="$C_MAGENTA" ;;
	esac
	
	# Format lock mode
	local mode_str="$lock_mode"
	if [[ "$lock_mode" == "hard_lock" ]]; then
		mode_str="${C_RED}HARD${C_RESET}"
	else
		mode_str="${C_GREEN}lease${C_RESET}"
	fi
	
	# Get bot key if possible
	local bot_key
	bot_key=$(query "SELECT bot_key FROM bot_profile WHERE bot_id = '$holder_bot_id' LIMIT 1" | tail -n +2)
	local holder_str
	if [[ -n "$bot_key" ]]; then
		holder_str="${bot_key}"
	else
		holder_str="bot:${holder_bot_id}"
	fi
	
	printf "${C_DIM}#%s${C_RESET}  " "$res_id"
	printf "${type_color}%-15s${C_RESET}  " "$type"
	printf "%-30s  " "${resource_key:0:30}"
	printf "${C_CYAN}%-20s${C_RESET}  " "$holder_str"
	printf "${C_YELLOW}%-18s${C_RESET}  " "${holder_ctl:0:18}"
	printf "%s  " "$mode_str"
	printf "(%s)  " "$(format_remaining "$lease_until")"
	printf "${C_DIM}p=%s e=%s${C_RESET}" "$priority" "$epoch"
	if [[ -n "$reason" && "$reason" != "none" ]]; then
		printf "  [${C_DIM}%s${C_RESET}]" "$reason"
	fi
	printf "\n"
}

# Print header
print_header() {
	if [[ "$raw_output" -eq 1 ]]; then
		return
	fi
	printf "${C_BOLD}${C_UNDERLINE}%-6s  %-15s  %-30s  %-20s  %-18s  %-6s  %-10s  %s${C_RESET}\n" \
		"ID" "TYPE" "RESOURCE" "HOLDER" "CONTROLLER" "MODE" "REMAINING" "META"
}

# Active reservations command
cmd_active() {
	local n="${1:-$limit}"
	local now
	now=$(date +%s)
	local where
	where=$(build_filters)
	where="$where AND lease_until > $now"
	
	local sql="SELECT r.reservation_id, r.type, r.resource_key, r.holder_bot_id, r.holder_controller_id, 
			   r.lock_mode, r.lease_until, r.epoch, r.priority, r.reason
			   FROM bot_reservation r
			   WHERE $where
			   ORDER BY r.lease_until ASC
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Active Reservations${C_RESET}\n"
	printf "${C_DIM}Current time: %s${C_RESET}\n\n" "$(date '+%Y-%m-%d %H:%M:%S')"
	print_header
	
	local count=0
	while IFS=$'\t' read -r res_id type resource_key holder_bot_id holder_ctl lock_mode lease_until epoch priority reason; do
		print_res_row "$res_id" "$type" "$resource_key" "$holder_bot_id" "$holder_ctl" "$lock_mode" "$lease_until" "$epoch" "$priority" "$reason"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$count" -eq 0 ]]; then
		printf "${C_DIM}No active reservations found.${C_RESET}\n"
	fi
	
	printf "\n${C_DIM}Showing %d active reservations${C_RESET}\n" "$count"
}

# Recent reservation traces command
cmd_recent() {
	local n="${1:-$limit}"
	local where="phase = 'reservation'"
	
	if [[ "$since_minutes" -gt 0 ]]; then
		local now
		now=$(date +%s)
		local since_ts=$((now - since_minutes * 60))
		where="$where AND ts >= $since_ts"
	fi
	
	if [[ -n "$res_type" ]]; then
		where="$where AND target_type = '$res_type'"
	fi
	
	local sql="SELECT ts, action, target_type, target_id, bot_id, char_id, controller_id, reason_code, result, error_code
			   FROM bot_trace_event
			   WHERE $where
			   ORDER BY id DESC
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Recent Reservation Trace Events${C_RESET}\n\n"
	printf "${C_BOLD}${C_UNDERLINE}%-19s  %-25s  %-15s  %-30s  %-20s  %-10s  %s${C_RESET}\n" \
		"TIMESTAMP" "ACTION" "TYPE" "RESOURCE" "CONTROLLER" "RESULT" "REASON"
	
	local count=0
	while IFS=$'\t' read -r ts action target_type target_id bot_id char_id controller_id reason_code result error_code; do
		local ts_fmt
		ts_fmt=$(format_ts "$ts")
		
		local result_color="$C_RESET"
		case "$result" in
			ok) result_color="$C_GREEN" ;;
			denied|failed) result_color="$C_RED" ;;
			noop) result_color="$C_YELLOW" ;;
		esac
		
		printf "${C_DIM}%s${C_RESET}  " "$ts_fmt"
		printf "%-25s  " "$action"
		printf "%-15s  " "$target_type"
		printf "%-30s  " "${target_id:0:30}"
		printf "${C_CYAN}%-20s${C_RESET}  " "${controller_id:0:20}"
		printf "${result_color}%-10s${C_RESET}" "$result"
		if [[ -n "$reason_code" && "$reason_code" != "none" ]]; then
			printf "  [${C_YELLOW}%s${C_RESET}]" "$reason_code"
		fi
		printf "\n"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	printf "\n${C_DIM}Showing %d trace events${C_RESET}\n" "$count"
}

# Expired reservations command
cmd_expired() {
	local n="${1:-$limit}"
	local now
	now=$(date +%s)
	local where
	where=$(build_filters)
	where="$where AND lease_until <= $now"
	
	local sql="SELECT r.reservation_id, r.type, r.resource_key, r.holder_bot_id, r.holder_controller_id, 
			   r.lock_mode, r.lease_until, r.epoch, r.priority, r.reason
			   FROM bot_reservation r
			   WHERE $where
			   ORDER BY r.lease_until ASC
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}${C_RED}Expired Reservations${C_RESET}\n"
	printf "${C_DIM}Current time: %s${C_RESET}\n\n" "$(date '+%Y-%m-%d %H:%M:%S')"
	print_header
	
	local count=0
	while IFS=$'\t' read -r res_id type resource_key holder_bot_id holder_ctl lock_mode lease_until epoch priority reason; do
		print_res_row "$res_id" "$type" "$resource_key" "$holder_bot_id" "$holder_ctl" "$lock_mode" "$lease_until" "$epoch" "$priority" "$reason"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$count" -eq 0 ]]; then
		printf "${C_GREEN}No expired reservations found.${C_RESET}\n"
	fi
	
	printf "\n${C_DIM}Showing %d expired reservations${C_RESET}\n" "$count"
}

# Stale reservations command (holders that no longer exist)
cmd_stale() {
	local n="${1:-$limit}"
	
	local sql="SELECT r.reservation_id, r.type, r.resource_key, r.holder_bot_id, r.holder_controller_id, 
			   r.lock_mode, r.lease_until, r.epoch, r.priority, r.reason
			   FROM bot_reservation r
			   LEFT JOIN bot_profile p ON p.bot_id = r.holder_bot_id
			   WHERE p.bot_id IS NULL"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}${C_RED}Stale Reservations (Orphan Holders)${C_RESET}\n"
	printf "${C_DIM}Reservations held by bots that no longer exist in bot_profile${C_RESET}\n\n"
	print_header
	
	local count=0
	while IFS=$'\t' read -r res_id type resource_key holder_bot_id holder_ctl lock_mode lease_until epoch priority reason; do
		print_res_row "$res_id" "$type" "$resource_key" "$holder_bot_id" "$holder_ctl" "$lock_mode" "$lease_until" "$epoch" "$priority" "$reason"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$count" -eq 0 ]]; then
		printf "${C_GREEN}No stale reservations found.${C_RESET}\n"
	fi
	
	printf "\n${C_DIM}Showing %d stale reservations${C_RESET}\n" "$count"
}

# Holder command
cmd_holder() {
	local holder="$1"
	local n="${2:-$limit}"
	
	# Try to resolve as bot_key first
	local bot_id
	bot_id=$(query "SELECT bot_id FROM bot_profile WHERE bot_key = '$holder' LIMIT 1" | tail -n +2)
	
	local where="1=1"
	if [[ -n "$bot_id" ]]; then
		where="holder_bot_id = '$bot_id'"
	else
		# Try as controller_id
		where="holder_controller_id = '$holder'"
	fi
	
	local sql="SELECT r.reservation_id, r.type, r.resource_key, r.holder_bot_id, r.holder_controller_id, 
			   r.lock_mode, r.lease_until, r.epoch, r.priority, r.reason
			   FROM bot_reservation r
			   WHERE $where
			   ORDER BY r.lease_until ASC
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Reservations Held by: %s${C_RESET}\n\n" "$holder"
	print_header
	
	local count=0
	while IFS=$'\t' read -r res_id type resource_key holder_bot_id holder_ctl lock_mode lease_until epoch priority reason; do
		print_res_row "$res_id" "$type" "$resource_key" "$holder_bot_id" "$holder_ctl" "$lock_mode" "$lease_until" "$epoch" "$priority" "$reason"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$count" -eq 0 ]]; then
		printf "${C_DIM}No reservations found for this holder.${C_RESET}\n"
	fi
	
	printf "\n${C_DIM}Showing %d reservations${C_RESET}\n" "$count"
}

# Resource command
cmd_resource() {
	local resource_key="$1"
	local n="${2:-$limit}"
	
	local sql="SELECT r.reservation_id, r.type, r.resource_key, r.holder_bot_id, r.holder_controller_id, 
			   r.lock_mode, r.lease_until, r.epoch, r.priority, r.reason
			   FROM bot_reservation r
			   WHERE r.resource_key = '$resource_key'
			   ORDER BY r.lease_until ASC
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Reservations for Resource: %s${C_RESET}\n\n" "$resource_key"
	print_header
	
	local count=0
	while IFS=$'\t' read -r res_id type resource_key holder_bot_id holder_ctl lock_mode lease_until epoch priority reason; do
		print_res_row "$res_id" "$type" "$resource_key" "$holder_bot_id" "$holder_ctl" "$lock_mode" "$lease_until" "$epoch" "$priority" "$reason"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$count" -eq 0 ]]; then
		printf "${C_DIM}No reservations found for this resource.${C_RESET}\n"
	fi
	
	printf "\n${C_DIM}Showing %d reservations${C_RESET}\n" "$count"
}

# Hot resources command (most contested)
cmd_hot() {
	local n="${1:-10}"
	
	local sql="SELECT target_id, target_type, COUNT(*) as denial_count
			   FROM bot_trace_event
			   WHERE phase = 'reservation' AND action = 'reservation.denied'
			   GROUP BY target_id, target_type
			   ORDER BY denial_count DESC
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}${C_YELLOW}Most Contested Resources (Top Denials)${C_RESET}\n\n"
	printf "${C_BOLD}${C_UNDERLINE}%-6s  %-15s  %-40s  %s${C_RESET}\n" \
		"RANK" "TYPE" "RESOURCE" "DENIALS"
	
	local rank=1
	while IFS=$'\t' read -r target_id target_type denial_count; do
		local type_color="$C_RESET"
		case "$target_type" in
			anchor) type_color="$C_BLUE" ;;
			dialog_target) type_color="$C_CYAN" ;;
			social_target) type_color="$C_GREEN" ;;
			merchant_spot) type_color="$C_YELLOW" ;;
			party_role) type_color="$C_MAGENTA" ;;
		esac
		
		printf "${C_BOLD}#%-4s${C_RESET}  " "$rank"
		printf "${type_color}%-15s${C_RESET}  " "$target_type"
		printf "%-40s  " "${target_id:0:40}"
		printf "${C_RED}%s${C_RESET}\n" "$denial_count"
		((rank++))
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$rank" -eq 1 ]]; then
		printf "${C_DIM}No reservation denials found in trace history.${C_RESET}\n"
	fi
}

# Denied command
cmd_denied() {
	local n="${1:-$limit}"
	local where="phase = 'reservation' AND action = 'reservation.denied'"
	
	if [[ "$since_minutes" -gt 0 ]]; then
		local now
		now=$(date +%s)
		local since_ts=$((now - since_minutes * 60))
		where="$where AND ts >= $since_ts"
	fi
	
	local sql="SELECT ts, target_type, target_id, bot_id, char_id, controller_id, reason_code, error_code
			   FROM bot_trace_event
			   WHERE $where
			   ORDER BY id DESC
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}${C_RED}Recent Reservation Denials${C_RESET}\n\n"
	printf "${C_BOLD}${C_UNDERLINE}%-19s  %-15s  %-30s  %-20s  %s${C_RESET}\n" \
		"TIMESTAMP" "TYPE" "RESOURCE" "CONTROLLER" "REASON"
	
	local count=0
	while IFS=$'\t' read -r ts target_type target_id bot_id char_id controller_id reason_code error_code; do
		local ts_fmt
		ts_fmt=$(format_ts "$ts")
		
		printf "${C_DIM}%s${C_RESET}  " "$ts_fmt"
		printf "%-15s  " "$target_type"
		printf "%-30s  " "${target_id:0:30}"
		printf "${C_CYAN}%-20s${C_RESET}  " "${controller_id:0:20}"
		printf "${C_YELLOW}%s${C_RESET}" "$reason_code"
		if [[ -n "$error_code" ]]; then
			printf "  (${C_RED}%s${C_RESET})" "$error_code"
		fi
		printf "\n"
		((count++))
	done < <(query "$sql" | tail -n +2)
	
	printf "\n${C_DIM}Showing %d denials${C_RESET}\n" "$count"
}

# Why denied command
cmd_why_denied() {
	local resource_key="$1"
	
	printf "${C_BOLD}Why Denied Analysis: %s${C_RESET}\n\n" "$resource_key"
	
	# Check current holder
	printf "${C_BOLD}Current Reservation Status:${C_RESET}\n"
	local sql="SELECT r.reservation_id, r.type, r.holder_bot_id, r.holder_controller_id, r.lock_mode, r.lease_until, r.reason
			   FROM bot_reservation r
			   WHERE r.resource_key = '$resource_key'
			   LIMIT 1"
	
	local found=0
	while IFS=$'\t' read -r res_id type holder_bot_id holder_ctl lock_mode lease_until reason; do
		found=1
		printf "  Resource is ${C_GREEN}CURRENTLY HELD${C_RESET}\n"
		printf "  Holder Bot ID: ${C_CYAN}%s${C_RESET}\n" "$holder_bot_id"
		printf "  Controller: ${C_CYAN}%s${C_RESET}\n" "$holder_ctl"
		printf "  Lock Mode: %s\n" "$lock_mode"
		printf "  Lease Until: %s (${C_YELLOW}%s${C_RESET})\n" \
			"$(format_ts "$lease_until")" "$(format_remaining "$lease_until")"
		printf "  Reason: ${C_DIM}%s${C_RESET}\n" "$reason"
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "  Resource is ${C_GREEN}CURRENTLY FREE${C_RESET}\n"
	fi
	
	# Recent denials for this resource
	printf "\n${C_BOLD}Recent Denials for This Resource:${C_RESET}\n"
	sql="SELECT ts, bot_id, char_id, controller_id, reason_code, error_code
		 FROM bot_trace_event
		 WHERE phase = 'reservation' AND action = 'reservation.denied' AND target_id = '$resource_key'
		 ORDER BY id DESC
		 LIMIT 5"
	
	found=0
	while IFS=$'\t' read -r ts bot_id char_id controller_id reason_code error_code; do
		found=1
		printf "\n  ${C_DIM}%s${C_RESET}\n" "$(format_ts "$ts")"
		printf "  Denied Bot: ${C_CYAN}%s${C_RESET} (char:%s)\n" "$bot_id" "$char_id"
		printf "  Controller: ${C_CYAN}%s${C_RESET}\n" "$controller_id"
		printf "  Reason: ${C_YELLOW}%s${C_RESET}\n" "$reason_code"
		if [[ -n "$error_code" ]]; then
			printf "  Error: ${C_RED}%s${C_RESET}\n" "$error_code"
		fi
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "  ${C_DIM}No recent denials for this resource.${C_RESET}\n"
	fi
	
	# Contention pattern
	printf "\n${C_BOLD}Contention Pattern (Last Hour):${C_RESET}\n"
	sql="SELECT controller_id, COUNT(*) as cnt
		 FROM bot_trace_event
		 WHERE phase = 'reservation' AND action = 'reservation.denied' 
		 AND target_id = '$resource_key' AND ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 1 HOUR)
		 GROUP BY controller_id
		 ORDER BY cnt DESC"
	
	found=0
	while IFS=$'\t' read -r controller_id cnt; do
		found=1
		printf "  ${C_CYAN}%-30s${C_RESET}  ${C_RED}%s denials${C_RESET}\n" "$controller_id" "$cnt"
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "  ${C_DIM}No contention in the last hour.${C_RESET}\n"
	fi
}

# Stats command
cmd_stats() {
	printf "${C_BOLD}Reservation Statistics${C_RESET}\n\n"
	
	local now
	now=$(date +%s)
	
	# Total counts
	local total active expired
	total=$(query "SELECT COUNT(*) FROM bot_reservation" | tail -n +2)
	active=$(query "SELECT COUNT(*) FROM bot_reservation WHERE lease_until > $now" | tail -n +2)
	expired=$(query "SELECT COUNT(*) FROM bot_reservation WHERE lease_until <= $now" | tail -n +2)
	
	printf "${C_BOLD}Current State:${C_RESET}\n"
	printf "  Total Reservations:     %s\n" "$total"
	printf "  Active:                 ${C_GREEN}%s${C_RESET}\n" "$active"
	printf "  Expired:                ${C_RED}%s${C_RESET}\n" "$expired"
	
	# By type
	printf "\n${C_BOLD}By Type:${C_RESET}\n"
	local sql="SELECT type, COUNT(*) as cnt, 
			   SUM(CASE WHEN lease_until > $now THEN 1 ELSE 0 END) as active_cnt
			   FROM bot_reservation
			   GROUP BY type
			   ORDER BY cnt DESC"
	while IFS=$'\t' read -r type cnt active_cnt; do
		printf "  %-20s  total:%3s  active:${C_GREEN}%s${C_RESET}\n" "$type" "$cnt" "$active_cnt"
	done < <(query "$sql" | tail -n +2)
	
	# By lock mode
	printf "\n${C_BOLD}By Lock Mode:${C_RESET}\n"
	sql="SELECT lock_mode, COUNT(*) as cnt FROM bot_reservation GROUP BY lock_mode"
	while IFS=$'\t' read -r mode cnt; do
		if [[ "$mode" == "hard_lock" ]]; then
			printf "  ${C_RED}%-12s${C_RESET}  %s\n" "$mode" "$cnt"
		else
			printf "  ${C_GREEN}%-12s${C_RESET}  %s\n" "$mode" "$cnt"
		fi
	done < <(query "$sql" | tail -n +2)
	
	# Recent trace activity
	printf "\n${C_BOLD}Recent Trace Activity (Last Hour):${C_RESET}\n"
	sql="SELECT action, result, COUNT(*) as cnt
		 FROM bot_trace_event
		 WHERE phase = 'reservation' AND ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 1 HOUR)
		 GROUP BY action, result
		 ORDER BY action, result"
	while IFS=$'\t' read -r action result cnt; do
		local result_color="$C_RESET"
		case "$result" in
			ok) result_color="$C_GREEN" ;;
			denied) result_color="$C_RED" ;;
			noop) result_color="$C_YELLOW" ;;
		esac
		printf "  %-25s  ${result_color}%-10s${C_RESET}  %3s\n" "$action" "$result" "$cnt"
	done < <(query "$sql" | tail -n +2)
	
	# Top holders
	printf "\n${C_BOLD}Top Holders (by reservation count):${C_RESET}\n"
	sql="SELECT holder_controller_id, COUNT(*) as cnt
		 FROM bot_reservation
		 WHERE lease_until > $now
		 GROUP BY holder_controller_id
		 ORDER BY cnt DESC
		 LIMIT 5"
	while IFS=$'\t' read -r holder cnt; do
		printf "  ${C_CYAN}%-30s${C_RESET}  %s\n" "${holder:0:30}" "$cnt"
	done < <(query "$sql" | tail -n +2)
}

# Main dispatcher
cmd="${1:-active}"
shift || true

case "$cmd" in
	active)
		cmd_active "$@"
		;;
	recent)
		cmd_recent "$@"
		;;
	expired)
		cmd_expired "$@"
		;;
	stale)
		cmd_stale "$@"
		;;
	holder)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-reservations.sh holder <bot_key|bot_id|controller_id> [limit]" >&2
			exit 1
		fi
		cmd_holder "$@"
		;;
	resource)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-reservations.sh resource <resource_key> [limit]" >&2
			exit 1
		fi
		cmd_resource "$@"
		;;
	hot)
		cmd_hot "$@"
		;;
	denied)
		cmd_denied "$@"
		;;
	why-denied)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-reservations.sh why-denied <resource_key>" >&2
			exit 1
		fi
		cmd_why_denied "$@"
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
