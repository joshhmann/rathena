#!/usr/bin/env bash
set -euo pipefail

# Playerbot Pool Observability Tool
# CLI helper for inspecting pool state and bot supply
#
# IMPORTANT LIMITATIONS (current as of master):
# - This tool reads SQL config tables, NOT live runtime scheduler state
# - "Configured threshold" = min_demand_users from bot_controller_slot (static config)
# - "Configured slots" = enabled slot rows per pool
# - Live requested demand (runtime slot activation) is NOT directly queryable from SQL
# - For live scheduler truth, use in-game scheduler NPCs or trace inspection
#
# What this tool CAN answer accurately:
# - Which pools are defined and their configured slot counts
# - How many bots are assigned to each pool (via routine_pool on bot_profile)
# - How many bots are parked vs active (via bot_runtime_state)
# - Which controllers reference each pool
# - Supply gaps relative to configured thresholds

DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-rathena}
DB_USER=${DB_USER:-rathena}
DB_PASS=${DB_PASS:-rathena_secure_2024}

# Default limits
DEFAULT_LIMIT=20
MAX_LIMIT=200

usage() {
	cat <<'EOF'
Usage: tools/ci/playerbot-pool.sh [options] [command]

Playerbot Pool Observability Tool - Inspect pool state and bot supply

LIMITATIONS:
  This tool queries SQL config tables, NOT live runtime scheduler state.
  "Configured threshold" = static min_demand_users from slot config.
  For live scheduler truth, use in-game scheduler NPCs or trace inspection.

COMMANDS:
  status                     Show pool inventory and configured thresholds
  pools [N]                  List all pools with supply counts
  constrained                Show pools where supply < configured threshold
  supply                     Show parked vs active bot supply by pool
  controller <name> [N]      Show pool bindings for a controller
  pool <name> [N]            Show details for a specific pool
  stats                      Show pool statistics summary

OPTIONS:
  -l, --limit N              Limit results to N rows (max: 200)
  --raw                      Output raw SQL results (tab-separated)
  --no-color                 Disable colorized output
  -h, --help                 Show this help

EXAMPLES:
  # Pool inventory with supply counts
  tools/ci/playerbot-pool.sh status
  
  # Pools where supply is below configured threshold
  tools/ci/playerbot-pool.sh constrained
  
  # Bot supply breakdown (parked vs active)
  tools/ci/playerbot-pool.sh supply
  
  # Controller pool bindings
  tools/ci/playerbot-pool.sh controller "social.prontera"
  
  # Specific pool details
  tools/ci/playerbot-pool.sh pool "pool.social.prontera"
  
  # Statistics
  tools/ci/playerbot-pool.sh stats

ENVIRONMENT:
  DB_HOST, DB_NAME, DB_USER, DB_PASS  Database connection settings

NOTES:
  - Configured threshold = minimum users configured for slot activation
  - This is NOT live requested demand (which depends on runtime signals)
  - Parked bots = offline/parked in bot_runtime_state
  - Active bots = online (any non-offline state in bot_runtime_state)
EOF
}

# Parse global options
limit=$DEFAULT_LIMIT
raw_output=0
no_color=0

while [[ $# -gt 0 ]]; do
	case "$1" in
		-l|--limit)
			limit="${2:-$DEFAULT_LIMIT}"
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

# Get pool supply counts (parked vs active)
get_pool_supply() {
	local pool_key="$1"
	
	# Total active bots in this pool (routine_pool match)
	local total parked active
	
	total=$(query "SELECT COUNT(DISTINCT p.bot_id) 
			   FROM bot_profile p
			   WHERE p.routine_pool = '$pool_key'
			   AND p.status = 'active'" | tail -n +2)
	
	# Parked = offline/parked bots
	parked=$(query "SELECT COUNT(DISTINCT p.bot_id) 
				   FROM bot_profile p
				   JOIN bot_runtime_state r ON r.bot_id = p.bot_id
				   WHERE p.routine_pool = '$pool_key' 
				   AND p.status = 'active'
				   AND r.current_state = 'offline' 
				   AND r.park_state = 'parked'" | tail -n +2)
	
	# Active = online bots (any non-offline state)
	active=$(query "SELECT COUNT(DISTINCT p.bot_id) 
				 FROM bot_profile p
				 JOIN bot_runtime_state r ON r.bot_id = p.bot_id
				 WHERE p.routine_pool = '$pool_key' 
				 AND p.status = 'active'
				 AND r.current_state != 'offline'" | tail -n +2)
	
	echo -e "${total:-0}\t${parked:-0}\t${active:-0}"
}

# Get configured threshold for a pool
get_pool_threshold() {
	local pool_key="$1"
	
	# Sum of min_demand_users from enabled slots for this pool
	local threshold slots
	threshold=$(query "SELECT COALESCE(SUM(min_demand_users), 0)
				   FROM bot_controller_slot
				   WHERE pool_key = '$pool_key' AND enabled = 1" | tail -n +2)
	
	slots=$(query "SELECT COUNT(*)
			   FROM bot_controller_slot
			   WHERE pool_key = '$pool_key' AND enabled = 1" | tail -n +2)
	
	echo -e "${threshold:-0}\t${slots:-0}"
}

# Print pool header
print_pool_header() {
	if [[ "$raw_output" -eq 1 ]]; then
		return
	fi
	printf "${C_BOLD}${C_UNDERLINE}%-30s  %-6s  %-10s  %-10s  %-10s  %-12s  %s${C_RESET}\n" \
		"POOL" "SLOTS" "TOTAL" "PARKED" "ACTIVE" "THRESHOLD" "STATUS"
}

# Status command - comprehensive overview
cmd_status() {
	if [[ "$raw_output" -eq 1 ]]; then
		query "SELECT DISTINCT pool_key, COUNT(*) as slot_count
			   FROM bot_controller_slot 
			   WHERE enabled = 1
			   GROUP BY pool_key
			   ORDER BY pool_key"
		return
	fi
	
	printf "${C_BOLD}Pool Inventory and Configured Thresholds${C_RESET}\n"
	printf "${C_DIM}Current time: %s${C_RESET}\n" "$(date '+%Y-%m-%d %H:%M:%S')"
	printf "${C_DIM}Note: Threshold = configured min_demand_users (not live demand)${C_RESET}\n\n"
	
	# Pool state
	print_pool_header
	
	local sql="SELECT DISTINCT pool_key
			   FROM bot_controller_slot
			   WHERE enabled = 1
			   ORDER BY pool_key"
	
	while IFS=$'	' read -r pool; do
		# Get supply counts
		local supply
		supply=$(get_pool_supply "$pool")
		local total=$(echo "$supply" | cut -f1)
		local parked=$(echo "$supply" | cut -f2)
		local active=$(echo "$supply" | cut -f3)
		
		# Get configured threshold
		local config
		config=$(get_pool_threshold "$pool")
		local threshold=$(echo "$config" | cut -f1)
		local slots=$(echo "$config" | cut -f2)
		
		# Status based on parked supply vs configured threshold
		local status_color="$C_GREEN"
		local status="OK"
		
		if [[ "$parked" -eq 0 ]]; then
			status_color="$C_RED"
			status="NO_PARKED"
		elif [[ "$parked" -lt "$threshold" ]]; then
			status_color="$C_YELLOW"
			status="LOW"
		fi
		
		printf "%-30s  %-6s  %-10s  %-10s  %-10s  %-12s  ${status_color}%s${C_RESET}\n" \
			"${pool:0:30}" "$slots" "$total" "$parked" "$active" "$threshold" "$status"
	done < <(query "$sql" | tail -n +2)
	
	# Summary
	printf "\n${C_BOLD}Summary:${C_RESET}\n"
	local total_pools total_slots
	total_pools=$(query "SELECT COUNT(DISTINCT pool_key) FROM bot_controller_slot WHERE enabled = 1" | tail -n +2)
	total_slots=$(query "SELECT COUNT(*) FROM bot_controller_slot WHERE enabled = 1" | tail -n +2)
	
	local total_bots parked_bots active_bots
	total_bots=$(query "SELECT COUNT(*) FROM bot_profile WHERE status = 'active'" | tail -n +2)
	parked_bots=$(query "SELECT COUNT(*) FROM bot_runtime_state WHERE current_state = 'offline' AND park_state = 'parked'" | tail -n +2)
	active_bots=$(query "SELECT COUNT(*) FROM bot_runtime_state WHERE current_state != 'offline'" | tail -n +2)
	
	printf "  Configured pools:   %s\n" "$total_pools"
	printf "  Configured slots:   %s\n" "$total_slots"
	printf "  Total bots:         %s\n" "$total_bots"
	printf "  Parked bots:        ${C_GREEN}%s${C_RESET}\n" "$parked_bots"
	printf "  Active bots:        ${C_CYAN}%s${C_RESET}\n" "$active_bots"
	return 0
}

# Pools command - list all pools
cmd_pools() {
	local n="${1:-$limit}"
	
	local sql="SELECT DISTINCT pool_key,
			   COUNT(*) as slot_count,
			   SUM(min_demand_users) as threshold,
			   GROUP_CONCAT(DISTINCT profile_key) as profiles,
			   GROUP_CONCAT(DISTINCT role_key) as roles
			   FROM bot_controller_slot
			   WHERE enabled = 1
			   GROUP BY pool_key
			   ORDER BY pool_key
			   LIMIT $n"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Pool Inventory${C_RESET}\n"
	printf "${C_DIM}Note: Threshold = configured min_demand_users (static config)${C_RESET}\n\n"
	print_pool_header
	
	while IFS=$'	' read -r pool slots threshold profiles roles; do
		# Get supply
		local supply
		supply=$(get_pool_supply "$pool")
		local total=$(echo "$supply" | cut -f1)
		local parked=$(echo "$supply" | cut -f2)
		local active=$(echo "$supply" | cut -f3)
		
		local status_color="$C_GREEN"
		local status="OK"
		
		if [[ "$parked" -eq 0 ]]; then
			status_color="$C_RED"
			status="NO_PARKED"
		elif [[ "$parked" -lt "$threshold" ]]; then
			status_color="$C_YELLOW"
			status="LOW"
		fi
		
		printf "%-30s  %-6s  %-10s  %-10s  %-10s  %-12s  ${status_color}%s${C_RESET}\n" \
			"${pool:0:30}" "$slots" "$total" "$parked" "$active" "$threshold" "$status"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Constrained command - pools where supply < configured threshold
cmd_constrained() {
	if [[ "$raw_output" -eq 1 ]]; then
		local sql="SELECT pool_key, COUNT(*) as slots, SUM(min_demand_users) as threshold
				   FROM bot_controller_slot
				   WHERE enabled = 1
				   GROUP BY pool_key"
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Supply-Constrained Pools${C_RESET}\n"
	printf "${C_DIM}Pools where parked supply < configured threshold${C_RESET}\n"
	printf "${C_DIM}(Threshold = min_demand_users from slot config)${C_RESET}\n\n"
	
	printf "${C_BOLD}${C_UNDERLINE}%-30s  %-8s  %-12s  %-12s  %-12s${C_RESET}\n" \
		"POOL" "SLOTS" "CONFIGURED" "PARKED" "GAP"
	
	local sql="SELECT DISTINCT pool_key,
			   COUNT(*) as slot_count,
			   SUM(min_demand_users) as threshold
			   FROM bot_controller_slot
			   WHERE enabled = 1
			   GROUP BY pool_key
			   ORDER BY pool_key"
	
	local found=0
	while IFS=$'	' read -r pool slots threshold; do
		# Get parked count
		local supply
		supply=$(get_pool_supply "$pool")
		local parked=$(echo "$supply" | cut -f2)
		
		# Only show if constrained
		if [[ "$parked" -lt "$threshold" ]]; then
			found=1
			local gap=$((threshold - parked))
			local gap_color="$C_YELLOW"
			[[ "$parked" -eq 0 ]] && gap_color="$C_RED"
			
			printf "%-30s  %-8s  %-12s  %-12s  ${gap_color}%-12s${C_RESET}\n" \
				"${pool:0:30}" "$slots" "$threshold" "$parked" "$gap"
		fi
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "${C_GREEN}No constrained pools. All pools meet configured thresholds.${C_RESET}\n"
	fi
	return 0
}

# Supply command - parked vs active breakdown
cmd_supply() {
	if [[ "$raw_output" -eq 1 ]]; then
		local sql="SELECT DISTINCT pool_key
				   FROM bot_controller_slot
				   WHERE enabled = 1
				   ORDER BY pool_key"
		
		while IFS=$'	' read -r pool; do
			local supply
			supply=$(get_pool_supply "$pool")
			echo -e "$pool\t$supply"
		done < <(query "$sql" | tail -n +2)
		return
	fi
	
	printf "${C_BOLD}Bot Supply by Pool${C_RESET}\n"
	printf "${C_DIM}Parked (available) vs Active (in-use) bot counts${C_RESET}\n\n"
	
	printf "${C_BOLD}${C_UNDERLINE}%-30s  %-10s  %-10s  %-10s  %s${C_RESET}\n" \
		"POOL" "TOTAL" "PARKED" "ACTIVE" "UTILIZATION"
	
	local sql="SELECT DISTINCT pool_key
			   FROM bot_controller_slot
			   WHERE enabled = 1
			   ORDER BY pool_key"
	
	while IFS=$'	' read -r pool; do
		local supply
		supply=$(get_pool_supply "$pool")
		local total=$(echo "$supply" | cut -f1)
		local parked=$(echo "$supply" | cut -f2)
		local active=$(echo "$supply" | cut -f3)
		
		local utilization=0
		[[ "$total" -gt 0 ]] && utilization=$(( active * 100 / total ))
		
		printf "%-30s  %-10s  ${C_GREEN}%-10s${C_RESET}  ${C_CYAN}%-10s${C_RESET}  %s%%\n" \
			"${pool:0:30}" "$total" "$parked" "$active" "$utilization"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Controller command
cmd_controller() {
	local controller="$1"
	local n="${2:-$limit}"
	
	local sql="SELECT controller_key, map_name, controller_type, controller_enabled
			   FROM bot_controller_policy
			   WHERE controller_key = '$controller'"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Controller Pool Bindings: %s${C_RESET}\n\n" "$controller"
	
	# Get controller info
	local ctrl_info
	ctrl_info=$(query "$sql" | tail -n +2)
	if [[ -z "$ctrl_info" ]]; then
		echo "Controller not found: $controller" >&2
		return 1
	fi
	
	local map ctype enabled
	map=$(echo "$ctrl_info" | cut -f2)
	ctype=$(echo "$ctrl_info" | cut -f3)
	enabled=$(echo "$ctrl_info" | cut -f4)
	
	local status="enabled"
	[[ "$enabled" == "0" ]] && status="disabled"
	
	printf "  Controller:  %s\n" "$controller"
	printf "  Map:         %s\n" "$map"
	printf "  Type:        %s\n" "$ctype"
	printf "  Status:      %s\n" "$status"
	
	# Get slots for this controller
	printf "\n${C_BOLD}Configured Slots:${C_RESET}\n"
	sql="SELECT slot_index, slot_label, pool_key, profile_key, role_key, mode, min_demand_users
		   FROM bot_controller_slot
		   WHERE controller_key = '$controller' AND enabled = 1
		   ORDER BY slot_index"
	
	printf "  %-6s  %-15s  %-20s  %-15s  %-12s  %s\n" "INDEX" "LABEL" "POOL" "PROFILE" "MODE" "THRESHOLD"
	printf "  %s\n" "$(printf '%.0s-' {1..85})"
	
	while IFS=$'	' read -r idx label pool profile role mode threshold; do
		printf "  %-6s  %-15s  %-20s  %-15s  %-12s  %s\n" \
			"$idx" "${label:0:15}" "${pool:0:20}" "${profile:0:15}" "$mode" "$threshold"
	done < <(query "$sql" | tail -n +2)
	
	# Get pool supply for this controller's pools
	printf "\n${C_BOLD}Pool Supply Status:${C_RESET}\n"
	sql="SELECT DISTINCT pool_key
		   FROM bot_controller_slot
		   WHERE controller_key = '$controller' AND enabled = 1"
	
	printf "  %-30s  %-10s  %-10s  %-12s  %s\n" "POOL" "PARKED" "CONFIGURED" "STATUS" "NOTE"
	printf "  %s\n" "$(printf '%.0s-' {1..75})"
	
	while IFS=$'	' read -r pool; do
		local supply
		supply=$(get_pool_supply "$pool")
		local parked=$(echo "$supply" | cut -f2)
		
		local config
		config=$(get_pool_threshold "$pool")
		local threshold=$(echo "$config" | cut -f1)
		
		local avail_color="$C_GREEN"
		local status="OK"		
		if [[ "$parked" -eq 0 ]]; then
			avail_color="$C_RED"
			status="STARVED"
		elif [[ "$parked" -lt "$threshold" ]]; then
			avail_color="$C_YELLOW"
			status="LOW"
		fi
		
		printf "  %-30s  ${avail_color}%-10s${C_RESET}  %-12s  %-12s  %s\n" \
			"${pool:0:30}" "$parked" "$threshold" "$status" "(configured)"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Pool detail command
cmd_pool() {
	local pool_name="$1"
	local n="${2:-$limit}"
	
	local sql="SELECT pool_key, profile_key, role_key, map_name, mode,
			   COUNT(*) as slot_count,
			   SUM(min_demand_users) as threshold
			   FROM bot_controller_slot
			   WHERE pool_key = '$pool_name' AND enabled = 1
			   GROUP BY pool_key, profile_key, role_key, map_name, mode"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Pool Details: %s${C_RESET}\n\n" "$pool_name"
	
	# Get supply
	local supply
	supply=$(get_pool_supply "$pool_name")
	local total=$(echo "$supply" | cut -f1)
	local parked=$(echo "$supply" | cut -f2)
	local active=$(echo "$supply" | cut -f3)
	
	printf "  Pool Key:              %s\n" "$pool_name"
	printf "\n"
	printf "  ${C_BOLD}Bot Supply:${C_RESET}\n"
	printf "    Total Bots:          %s\n" "$total"
	printf "    Parked (available):  ${C_GREEN}%s${C_RESET}\n" "$parked"
	printf "    Active (in-use):     ${C_CYAN}%s${C_RESET}\n" "$active"
	
	local utilization=0
	[[ "$total" -gt 0 ]] && utilization=$(( (total - parked) * 100 / total ))
	printf "    Utilization:         %s%%\n" "$utilization"
	
	# Get configured threshold
	local config
	config=$(get_pool_threshold "$pool_name")
	local threshold=$(echo "$config" | cut -f1)
	local slots=$(echo "$config" | cut -f2)
	
	printf "\n  ${C_BOLD}Configured Thresholds:${C_RESET}\n"
	printf "    Configured Slots:    %s\n" "$slots"
	printf "    Min Demand Total:    %s\n" "$threshold"
	printf "    ${C_DIM}(threshold = sum of min_demand_users)${C_RESET}\n"
	
	local status="HEALTHY"
	local status_color="$C_GREEN"
	if [[ "$parked" -eq 0 ]]; then
		status="NO_PARKED_SUPPLY"
		status_color="$C_RED"
	elif [[ "$parked" -lt "$threshold" ]]; then
		status="BELOW_THRESHOLD"
		status_color="$C_YELLOW"
	fi
	printf "\n  Supply Status:          ${status_color}%s${C_RESET}\n" "$status"
	
	# Show slot definitions
	printf "\n${C_BOLD}Slot Definitions:${C_RESET}\n"
	printf "  %-6s  %-15s  %-15s  %-12s  %s\n" "INDEX" "LABEL" "PROFILE" "ROLE" "THRESHOLD"
	printf "  %s\n" "$(printf '%.0s-' {1..70})"
	
	while IFS=$'	' read -r pool profile role map mode slots threshold; do
		printf "  %-6s  %-15s  %-15s  %-12s  %s\n" \
			"..." "..." "${profile:0:15}" "${role:0:12}" "$threshold"
	done < <(query "$sql" | tail -n +2)
	
	# Show controllers using this pool
	printf "\n${C_BOLD}Controllers Referencing This Pool:${C_RESET}\n"
	sql="SELECT DISTINCT c.controller_key, c.map_name
		   FROM bot_controller_policy c
		   JOIN bot_controller_slot s ON s.controller_key = c.controller_key
		   WHERE s.pool_key = '$pool_name' AND c.controller_enabled = 1 AND s.enabled = 1"
	
	while IFS=$'	' read -r controller map; do
		printf "  - %s (map: %s)\n" "$controller" "$map"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Stats command
cmd_stats() {
	printf "${C_BOLD}Pool Statistics${C_RESET}\n\n"
	
	# Overall
	printf "${C_BOLD}Overall:${C_RESET}\n"
	local total_pools total_slots
	total_pools=$(query "SELECT COUNT(DISTINCT pool_key) FROM bot_controller_slot WHERE enabled = 1" | tail -n +2)
	total_slots=$(query "SELECT COUNT(*) FROM bot_controller_slot WHERE enabled = 1" | tail -n +2)
	
	printf "  Configured Pools:    %s\n" "$total_pools"
	printf "  Configured Slots:    %s\n" "$total_slots"
	
	# Bot counts
	local total_bots parked active
	total_bots=$(query "SELECT COUNT(*) FROM bot_profile WHERE status = 'active'" | tail -n +2)
	parked=$(query "SELECT COUNT(*) FROM bot_runtime_state WHERE current_state = 'offline' AND park_state = 'parked'" | tail -n +2)
	active=$(query "SELECT COUNT(*) FROM bot_runtime_state WHERE current_state != 'offline'" | tail -n +2)
	
	printf "  Total Bots:          %s\n" "$total_bots"
	printf "  Parked Bots:         ${C_GREEN}%s${C_RESET}\n" "$parked"
	printf "  Active Bots:         ${C_CYAN}%s${C_RESET}\n" "$active"
	
	# Pools with no parked supply
	printf "\n${C_BOLD}Pools with No Parked Supply:${C_RESET}\n"
	local sql="SELECT DISTINCT pool_key FROM bot_controller_slot WHERE enabled = 1"
	
	local starved_count=0
	while IFS=$'	' read -r pool; do
		local supply
		supply=$(get_pool_supply "$pool")
		local parked=$(echo "$supply" | cut -f2)
		
		if [[ "$parked" -eq 0 ]]; then
			starved_count=$((starved_count + 1))
		fi
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$starved_count" -gt 0 ]]; then
		printf "  ${C_RED}%s pools have no parked bots${C_RESET}\n" "$starved_count"
	else
		printf "  ${C_GREEN}None - all pools have parked supply${C_RESET}\n"
	fi
	
	# By profile
	printf "\n${C_BOLD}By Profile:${C_RESET}\n"
	sql="SELECT profile_key, 
			   COUNT(DISTINCT pool_key) as pool_count,
			   COUNT(*) as slot_count
			   FROM bot_controller_slot
			   WHERE enabled = 1 AND profile_key IS NOT NULL AND profile_key != ''
			   GROUP BY profile_key
			   ORDER BY pool_count DESC"
	
	printf "  %-25s  %-8s  %-10s\n" "PROFILE" "POOLS" "SLOTS"
	printf "  %s\n" "$(printf '%.0s-' {1..50})"
	
	while IFS=$'	' read -r profile pools slots; do
		printf "  %-25s  %-8s  %-10s\n" "${profile:0:25}" "$pools" "$slots"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Main dispatcher
cmd="${1:-status}"
shift || true

case "$cmd" in
	status)
		cmd_status "$@"
		;;
	pools)
		cmd_pools "$@"
		;;
	constrained)
		cmd_constrained "$@"
		;;
	supply)
		cmd_supply "$@"
		;;
	controller)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-pool.sh controller <controller_name> [limit]" >&2
			exit 1
		fi
		cmd_controller "$@"
		;;
	pool)
		if [[ $# -lt 1 ]]; then
			echo "Usage: tools/ci/playerbot-pool.sh pool <pool_name> [limit]" >&2
			exit 1
		fi
		cmd_pool "$@"
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
