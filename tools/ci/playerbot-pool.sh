#!/usr/bin/env bash
set -euo pipefail

# Playerbot Pool Observability Tool
# CLI helper for inspecting pool state and diagnosing supply shortages
# Answers: what pools are available, supply vs demand, shortages, unassigned slots

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

Playerbot Pool Observability Tool - Inspect pool state and diagnose shortages

COMMANDS:
  status                     Show complete pool and scheduler status
  pools [N]                  Show all pools and their availability
  shortage                   Show pools with supply shortages
  unassigned [N]             Show controllers with unassigned slots
  supply-demand              Show supply vs demand analysis
  controller <name> [N]      Show pool state for specific controller
  pool <name> [N]            Show specific pool details
  stats                      Show pool statistics summary

OPTIONS:
  -l, --limit N              Limit results to N rows (max: 200)
  --since MINUTES            Only show recent trace events
  --raw                      Output raw SQL results (tab-separated)
  --no-color                 Disable colorized output
  -h, --help                 Show this help

EXAMPLES:
  # Complete pool status
  tools/ci/playerbot-pool.sh status
  
  # Show pools with shortages
  tools/ci/playerbot-pool.sh shortage
  
  # Show unassigned slots
  tools/ci/playerbot-pool.sh unassigned
  
  # Supply vs demand analysis
  tools/ci/playerbot-pool.sh supply-demand
  
  # Specific controller pool state
  tools/ci/playerbot-pool.sh controller "social.prontera"
  
  # Specific pool details
  tools/ci/playerbot-pool.sh pool "pool.social.prontera"
  
  # Statistics
  tools/ci/playerbot-pool.sh stats

ENVIRONMENT:
  DB_HOST, DB_NAME, DB_USER, DB_PASS  Database connection settings
EOF
}

# Parse global options
limit=$DEFAULT_LIMIT
since_minutes=0
raw_output=0
no_color=0

while [[ $# -gt 0 ]]; do
	case "$1" in
		-l|--limit)
			limit="${2:-$DEFAULT_LIMIT}"
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
	date -d "$ts" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$ts"
}

# Get pool summary data
get_pool_summary() {
	local pool_key="$1"
	
	# Total bots in this pool (routine_pool matches pool_key)
	local total available claimed
	
	# Query to count bots matching this pool
	# Bots are in a pool based on routine_pool matching
	total=$(query "SELECT COUNT(DISTINCT p.bot_id) 
			   FROM bot_profile p
			   WHERE p.routine_pool = '$pool_key'
			   AND p.status = 'active'" | tail -n +2)
	
	# Available = offline/parked bots
	available=$(query "SELECT COUNT(DISTINCT p.bot_id) 
				   FROM bot_profile p
				   JOIN bot_runtime_state r ON r.bot_id = p.bot_id
				   WHERE p.routine_pool = '$pool_key' 
				   AND p.status = 'active'
				   AND r.current_state = 'offline' 
				   AND r.park_state = 'parked'" | tail -n +2)
	
	# Active = currently online bots
	claimed=$(query "SELECT COUNT(DISTINCT p.bot_id) 
				 FROM bot_profile p
				 JOIN bot_runtime_state r ON r.bot_id = p.bot_id
				 WHERE p.routine_pool = '$pool_key' 
				 AND p.status = 'active'
				 AND r.current_state != 'offline'" | tail -n +2)
	
	# Return tab-separated
	echo -e "${total:-0}\t${available:-0}\t${claimed:-0}"
}

# Print header
print_header() {
	if [[ "$raw_output" -eq 1 ]]; then
		return
	fi
	printf "${C_BOLD}${C_UNDERLINE}%-30s  %-8s  %-10s  %-10s  %-10s  %s${C_RESET}\n" \
		"POOL" "DEMAND" "TOTAL" "AVAILABLE" "ACTIVE" "STATUS"
}

# Status command - comprehensive overview
cmd_status() {
	if [[ "$raw_output" -eq 1 ]]; then
		query "SELECT pool_key, 
			   COUNT(*) as slot_count,
			   SUM(actor_demand) as total_demand,
			   SUM(actor_weight) as total_weight
			   FROM bot_controller_slot 
			   WHERE enabled = 1
			   GROUP BY pool_key
			   ORDER BY pool_key"
		return
	fi
	
	printf "${C_BOLD}Pool and Scheduler Status${C_RESET}\n"
	printf "${C_DIM}Current time: %s${C_RESET}\n\n" "$(date '+%Y-%m-%d %H:%M:%S')"
	
	# Active controllers and their pool demand
	printf "${C_BOLD}Active Controller Demand:${C_RESET}\n"
	local sql="SELECT controller_key, map_name, 
			   SUM(actor_demand) as demand, 
			   SUM(actor_weight) as weight,
			   pool_key
			   FROM bot_controller_policy p
			   JOIN bot_controller_slot s ON s.controller_key = p.controller_key
			   WHERE p.controller_enabled = 1 AND s.enabled = 1
			   GROUP BY controller_key, pool_key
			   ORDER BY p.priority DESC"
	
	printf "  %-30s  %-12s  %-10s  %-8s  %-8s\n" "CONTROLLER" "POOL" "DEMAND" "WEIGHT"
	printf "  %s\n" "$(printf '%.0s-' {1..75})"
	
	while IFS=$'	' read -r controller map demand weight pool; do
		printf "  %-30s  %-12s  %-10s  %-8s\n" \
			"${controller:0:30}" "${pool:0:12}" "$demand" "$weight"
	done < <(query "$sql" | tail -n +2)
	
	# Pool state derived from runtime
	printf "\n${C_BOLD}Pool Availability:${C_RESET}\n"
	print_header
	
	# Get distinct pools and their stats
	sql="SELECT DISTINCT s.pool_key,
		   COUNT(DISTINCT s.slot_id) as slot_count,
		   SUM(s.min_demand_users) as min_demand
		   FROM bot_controller_slot s
		   WHERE s.enabled = 1
		   GROUP BY s.pool_key
		   ORDER BY s.pool_key"
	
	while IFS=$'	' read -r pool slots min_demand; do
		# Get runtime stats for this pool
		local runtime_stats
		runtime_stats=$(get_pool_summary "$pool")
		local total=$(echo "$runtime_stats" | cut -f1)
		local available=$(echo "$runtime_stats" | cut -f2)
		local active=$(echo "$runtime_stats" | cut -f3)
		
		local status_color="$C_GREEN"
		local status="OK"
		
		if [[ "$available" -eq 0 ]]; then
			status_color="$C_RED"
			status="STARVED"
		elif [[ "$available" -lt "$min_demand" ]]; then
			status_color="$C_YELLOW"
			status="LOW"
		fi
		
		printf "%-30s  %-8s  %-10s  %-10s  %-10s  ${status_color}%s${C_RESET}\n" \
			"${pool:0:30}" "$min_demand" "$total" "$available" "$active" "$status"
	done < <(query "$sql" | tail -n +2)
	
	# Summary stats
	printf "\n${C_BOLD}Summary:${C_RESET}\n"
	local total_pools total_slots
	total_pools=$(query "SELECT COUNT(DISTINCT pool_key) FROM bot_controller_slot WHERE enabled = 1" | tail -n +2)
	total_slots=$(query "SELECT COUNT(*) FROM bot_controller_slot WHERE enabled = 1" | tail -n +2)
	
	printf "  Active pools:       %s\n" "$total_pools"
	printf "  Total slots:        %s\n" "$total_slots"
	
	# Count bots by state
	local offline_bots online_bots
	offline_bots=$(query "SELECT COUNT(*) FROM bot_runtime_state WHERE current_state = 'offline' AND park_state = 'parked'" | tail -n +2)
	online_bots=$(query "SELECT COUNT(*) FROM bot_runtime_state WHERE current_state != 'offline'" | tail -n +2)
	
	printf "  Parked bots:        ${C_GREEN}%s${C_RESET}\n" "$offline_bots"
	printf "  Active bots:        ${C_CYAN}%s${C_RESET}\n" "$online_bots"
	return 0
}

# Pools command - list all pools
cmd_pools() {
	local n="${1:-$limit}"
	
	local sql="SELECT DISTINCT pool_key,
			   COUNT(*) as slot_count,
			   SUM(min_demand_users) as min_demand,
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
	
	printf "${C_BOLD}Pool Inventory${C_RESET}\n\n"
	print_header
	
	while IFS=$'	' read -r pool slots min_demand profiles roles; do
		# Get runtime stats
		local runtime_stats
		runtime_stats=$(get_pool_summary "$pool")
		local total=$(echo "$runtime_stats" | cut -f1)
		local available=$(echo "$runtime_stats" | cut -f2)
		local active=$(echo "$runtime_stats" | cut -f3)
		
		local status_color="$C_GREEN"
		local status="OK"
		
		if [[ "$available" -eq 0 ]]; then
			status_color="$C_RED"
			status="STARVED"
		elif [[ "$available" -lt "$min_demand" ]]; then
			status_color="$C_YELLOW"
			status="LOW"
		fi
		
		printf "%-30s  %-8s  %-10s  %-10s  %-10s  ${status_color}%s${C_RESET}\n" \
			"${pool:0:30}" "$min_demand" "$total" "$available" "$active" "$status"
		
		if [[ -n "$profiles" || -n "$roles" ]]; then
			printf "  ${C_DIM}profiles: %s | roles: %s${C_RESET}\n" "$profiles" "$roles"
		fi
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Shortage command - show pools with supply issues
cmd_shortage() {
	if [[ "$raw_output" -eq 1 ]]; then
		# Raw output - list pools with available < 2
		local sql="SELECT DISTINCT s.pool_key,
				   COUNT(*) as slot_count,
				   SUM(s.min_demand_users) as min_demand
				   FROM bot_controller_slot s
				   WHERE s.enabled = 1
				   GROUP BY s.pool_key"
		
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}${C_RED}Pool Supply Shortages${C_RESET}\n"
	printf "${C_DIM}Pools with low or no available capacity${C_RESET}\n\n"
	
	local sql="SELECT DISTINCT s.pool_key,
			   COUNT(*) as slot_count,
			   SUM(s.min_demand_users) as min_demand,
			   p.controller_key
			   FROM bot_controller_slot s
			   JOIN bot_controller_policy p ON p.controller_key = s.controller_key
			   WHERE s.enabled = 1 AND p.controller_enabled = 1
			   GROUP BY s.pool_key, p.controller_key
			   ORDER BY s.pool_key"
	
	printf "${C_BOLD}${C_UNDERLINE}%-30s  %-8s  %-10s  %-12s  %-20s${C_RESET}\n" \
		"POOL" "SLOTS" "AVAILABLE" "DEMAND" "CONTROLLER"
	
	local found=0
	while IFS=$'	' read -r pool slots min_demand controller; do
		# Get available count
		local runtime_stats
		runtime_stats=$(get_pool_summary "$pool")
		local total=$(echo "$runtime_stats" | cut -f1)
		local available=$(echo "$runtime_stats" | cut -f2)
		
		# Only show if shortage
		if [[ "$available" -lt "$min_demand" ]]; then
			found=1
			local avail_color="$C_YELLOW"
			[[ "$available" -eq 0 ]] && avail_color="$C_RED"
			
			printf "%-30s  %-8s  ${avail_color}%-10s${C_RESET}  %-12s  %-20s\n" \
				"${pool:0:30}" "$slots" "$available" "$min_demand" "${controller:0:20}"
		fi
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$found" -eq 0 ]]; then
		printf "${C_GREEN}No pool shortages detected. All pools have adequate supply.${C_RESET}\n"
	fi
	return 0
}

# Unassigned slots command
cmd_unassigned() {
	local n="${1:-$limit}"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "SELECT c.controller_key, c.map_name, c.actor_demand, c.actor_weight
			   FROM bot_controller_policy c
			   WHERE c.controller_enabled = 1
			   ORDER BY c.controller_key
			   LIMIT $n"
		return
	fi
	
	printf "${C_BOLD}Controllers with Unassigned Slots${C_RESET}\n"
	printf "${C_DIM}Controllers and their pool availability${C_RESET}\n\n"
	
	local sql="SELECT c.controller_key, c.map_name, c.actor_demand, c.actor_weight,
			   s.pool_key, COUNT(*) as slot_count
			   FROM bot_controller_policy c
			   JOIN bot_controller_slot s ON s.controller_key = c.controller_key
			   WHERE c.controller_enabled = 1 AND s.enabled = 1
			   GROUP BY c.controller_key, s.pool_key
			   ORDER BY c.controller_key"
	
	printf "${C_BOLD}${C_UNDERLINE}%-30s  %-10s  %-8s  %-20s  %-8s${C_RESET}\n" \
		"CONTROLLER" "MAP" "DEMAND" "POOL" "SLOTS"
	
	while IFS=$'	' read -r controller map demand weight pool slot_count; do
		# Get available bots for this pool
		local runtime_stats
		runtime_stats=$(get_pool_summary "$pool")
		local available=$(echo "$runtime_stats" | cut -f2)
		
		local avail_color="$C_RESET"
		[[ "$available" == "0" ]] && avail_color="$C_RED"
		[[ -z "$pool" ]] && avail_color="$C_MAGENTA"
		
		local pool_str="${pool:-<no pool>}"
		local avail_str="${available:-0}"
		
		printf "%-30s  %-10s  %-8s  %-20s  %-8s\n" \
			"${controller:0:30}" "$map" "$demand" "${pool_str:0:20}" "$slot_count"
		printf "  ${C_DIM}pool available: ${avail_color}%s${C_RESET}${C_DIM} bots${C_RESET}\n" "$avail_str"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Supply-demand command
cmd_supply_demand() {
	if [[ "$raw_output" -eq 1 ]]; then
		local sql="SELECT pool_key, COUNT(*) as slots, SUM(min_demand_users) as demand
				   FROM bot_controller_slot 
				   WHERE enabled = 1
				   GROUP BY pool_key
				   ORDER BY pool_key"
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Supply vs Demand Analysis${C_RESET}\n\n"
	
	local sql="SELECT pool_key, 
			   COUNT(*) as slots,
			   SUM(min_demand_users) as min_demand,
			   GROUP_CONCAT(DISTINCT controller_key) as controllers
			   FROM bot_controller_slot
			   WHERE enabled = 1
			   GROUP BY pool_key
			   ORDER BY pool_key"
	
	printf "${C_BOLD}${C_UNDERLINE}%-30s  %-8s  %-10s  %-10s  %-10s  %s${C_RESET}\n" \
		"POOL" "SLOTS" "SUPPLY" "DEMAND" "SHORTFALL" "STATUS"
	
	while IFS=$'	' read -r pool slots min_demand controllers; do
		# Get runtime supply
		local runtime_stats
		runtime_stats=$(get_pool_summary "$pool")
		local supply=$(echo "$runtime_stats" | cut -f1)
		local available=$(echo "$runtime_stats" | cut -f2)
		
		local shortfall=$(( min_demand - available ))
		[[ "$shortfall" -lt 0 ]] && shortfall=0
		
		local status_color="$C_GREEN"
		local status="HEALTHY"
		
		if [[ "$available" -eq 0 ]]; then
			status_color="$C_RED"
			status="EXHAUSTED"
		elif [[ "$shortfall" -gt 0 ]]; then
			status_color="$C_YELLOW"
			status="SHORTAGE"
		fi
		
		printf "%-30s  %-8s  %-10s  %-10s  %-10s  ${status_color}%s${C_RESET}\n" \
			"${pool:0:30}" "$slots" "$supply" "$min_demand" "$shortfall" "$status"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Controller command
cmd_controller() {
	local controller="$1"
	local n="${2:-$limit}"
	
	local sql="SELECT p.controller_key, p.map_name, p.actor_weight,
			   SUM(s.min_demand_users) as total_demand,
			   GROUP_CONCAT(DISTINCT s.pool_key) as pools
			   FROM bot_controller_policy p
			   JOIN bot_controller_slot s ON s.controller_key = p.controller_key
			   WHERE p.controller_key = '$controller' AND s.enabled = 1"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Controller Pool State: %s${C_RESET}\n\n" "$controller"
	
	# Get controller info
	local ctrl_info
	ctrl_info=$(query "$sql" | tail -n +2)
	if [[ -z "$ctrl_info" ]]; then
		echo "Controller not found: $controller" >&2
		return 1
	fi
	
	local map weight demand pools
	map=$(echo "$ctrl_info" | cut -f2)
	weight=$(echo "$ctrl_info" | cut -f3)
	demand=$(echo "$ctrl_info" | cut -f4)
	pools=$(echo "$ctrl_info" | cut -f5)
	
	printf "  Controller:  %s\n" "$controller"
	printf "  Map:         %s\n" "$map"
	printf "  Demand:      %s (min users)\n" "$demand"
	printf "  Weight:      %s\n" "$weight"
	printf "  Pools:       %s\n" "$pools"
	
	# Get slots for this controller
	printf "\n${C_BOLD}Controller Slots:${C_RESET}\n"
	sql="SELECT slot_index, slot_label, pool_key, profile_key, role_key, map_name, mode
		   FROM bot_controller_slot
		   WHERE controller_key = '$controller' AND enabled = 1
		   ORDER BY slot_index"
	
	printf "  %-6s  %-15s  %-20s  %-15s  %-12s\n" "INDEX" "LABEL" "POOL" "PROFILE" "MODE"
	printf "  %s\n" "$(printf '%.0s-' {1..75})"
	
	while IFS=$'	' read -r idx label pool profile role map mode; do
		printf "  %-6s  %-15s  %-20s  %-15s  %-12s\n" \
			"$idx" "${label:0:15}" "${pool:0:20}" "${profile:0:15}" "$mode"
	done < <(query "$sql" | tail -n +2)
	
	# Get pool availability for this controller's pools
	printf "\n${C_BOLD}Pool Availability:${C_RESET}\n"
	sql="SELECT DISTINCT pool_key
		   FROM bot_controller_slot
		   WHERE controller_key = '$controller' AND enabled = 1"
	
	printf "  %-30s  %-8s  %-10s  %-10s\n" "POOL" "DEMAND" "AVAILABLE" "STATUS"
	printf "  %s\n" "$(printf '%.0s-' {1..65})"
	
	while IFS=$'	' read -r pool; do
		local runtime_stats
		runtime_stats=$(get_pool_summary "$pool")
		local total=$(echo "$runtime_stats" | cut -f1)
		local available=$(echo "$runtime_stats" | cut -f2)
		local active=$(echo "$runtime_stats" | cut -f3)
		
		# Get demand for this pool from this controller
		local pool_demand
		pool_demand=$(query "SELECT SUM(min_demand_users) FROM bot_controller_slot WHERE controller_key = '$controller' AND pool_key = '$pool' AND enabled = 1" | tail -n +2)
		
		local avail_color="$C_GREEN"
		[[ "$available" -eq 0 ]] && avail_color="$C_RED"
		[[ "$available" -lt "$pool_demand" && "$available" -gt 0 ]] && avail_color="$C_YELLOW"
		
		local status="OK"
		[[ "$available" -eq 0 ]] && status="STARVED"
		[[ "$available" -lt "$pool_demand" && "$available" -gt 0 ]] && status="LOW"
		
		printf "  %-30s  %-8s  ${avail_color}%-10s${C_RESET}  %s\n" \
			"${pool:0:30}" "$pool_demand" "$available" "$status"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Pool detail command
cmd_pool() {
	local pool_name="$1"
	local n="${2:-$limit}"
	
	local sql="SELECT pool_key, profile_key, role_key, map_name, mode,
			   COUNT(*) as slot_count,
			   SUM(min_demand_users) as total_demand
			   FROM bot_controller_slot
			   WHERE pool_key = '$pool_name' AND enabled = 1
			   GROUP BY pool_key, profile_key, role_key, map_name, mode"
	
	if [[ "$raw_output" -eq 1 ]]; then
		query "$sql"
		return
	fi
	
	printf "${C_BOLD}Pool Details: %s${C_RESET}\n\n" "$pool_name"
	
	# Get pool stats
	local runtime_stats
	runtime_stats=$(get_pool_summary "$pool_name")
	local total=$(echo "$runtime_stats" | cut -f1)
	local available=$(echo "$runtime_stats" | cut -f2)
	local active=$(echo "$runtime_stats" | cut -f3)
	
	printf "  Pool Key:     %s\n" "$pool_name"
	printf "\n"
	printf "  Total Bots:   %s\n" "$total"
	printf "  Available:    ${C_GREEN}%s${C_RESET}\n" "$available"
	printf "  Active:       %s\n" "$active"
	printf "\n"
	
	local utilization=$(( (total - available) * 100 / (total > 0 ? total : 1) ))
	printf "  Utilization:  %s%%\n" "$utilization"
	
	local status="HEALTHY"
	local status_color="$C_GREEN"
	if [[ "$available" -eq 0 ]]; then
		status="STARVED"
		status_color="$C_RED"
	elif [[ "$available" -lt 2 ]]; then
		status="LOW"
		status_color="$C_YELLOW"
	fi
	printf "  Status:       ${status_color}%s${C_RESET}\n" "$status"
	
	# Show slot definitions
	printf "\n${C_BOLD}Slot Definitions:${C_RESET}\n"
	printf "  %-6s  %-15s  %-15s  %-12s  %-8s\n" "INDEX" "LABEL" "PROFILE" "ROLE" "DEMAND"
	printf "  %s\n" "$(printf '%.0s-' {1..70})"
	
	while IFS=$'	' read -r pool profile role map mode slots demand; do
		printf "  %-6s  %-15s  %-15s  %-12s  %-8s\n" \
			"..." "..." "${profile:0:15}" "${role:0:12}" "$demand"
	done < <(query "$sql" | tail -n +2)
	
	# Show controllers using this pool
	printf "\n${C_BOLD}Controllers Using This Pool:${C_RESET}\n"
	sql="SELECT DISTINCT c.controller_key, c.map_name, c.actor_demand
		   FROM bot_controller_policy c
		   JOIN bot_controller_slot s ON s.controller_key = c.controller_key
		   WHERE s.pool_key = '$pool_name' AND c.controller_enabled = 1 AND s.enabled = 1"
	
	while IFS=$'	' read -r controller map demand; do
		printf "  - %s (map: %s, demand: %s)\n" "$controller" "$map" "$demand"
	done < <(query "$sql" | tail -n +2)
	return 0
}

# Stats command
cmd_stats() {
	printf "${C_BOLD}Pool Statistics${C_RESET}\n\n"
	
	# Overall stats
	printf "${C_BOLD}Overall:${C_RESET}\n"
	local total_pools total_slots
	total_pools=$(query "SELECT COUNT(DISTINCT pool_key) FROM bot_controller_slot WHERE enabled = 1" | tail -n +2)
	total_slots=$(query "SELECT COUNT(*) FROM bot_controller_slot WHERE enabled = 1" | tail -n +2)
	
	printf "  Active Pools:      %s\n" "$total_pools"
	printf "  Total Slots:       %s\n" "$total_slots"
	
	# Bot counts by state
	local parked_bots active_bots
	parked_bots=$(query "SELECT COUNT(*) FROM bot_runtime_state WHERE current_state = 'offline' AND park_state = 'parked'" | tail -n +2)
	active_bots=$(query "SELECT COUNT(*) FROM bot_runtime_state WHERE current_state != 'offline'" | tail -n +2)
	
	printf "  Parked Bots:       ${C_GREEN}%s${C_RESET}\n" "$parked_bots"
	printf "  Active Bots:       ${C_CYAN}%s${C_RESET}\n" "$active_bots"
	
	# Starved pools
	printf "\n${C_BOLD}Starved Pools (0 available):${C_RESET}\n"
	sql="SELECT DISTINCT pool_key FROM bot_controller_slot WHERE enabled = 1"
	
	local starved_count=0
	while IFS=$'	' read -r pool; do
		local runtime_stats
		runtime_stats=$(get_pool_summary "$pool")
		local available=$(echo "$runtime_stats" | cut -f2)
		
		if [[ "$available" -eq 0 ]]; then
			starved_count=$((starved_count + 1))
		fi
	done < <(query "$sql" | tail -n +2)
	
	if [[ "$starved_count" -gt 0 ]]; then
		printf "  ${C_RED}%s pools have no available bots${C_RESET}\n" "$starved_count"
	else
		printf "  ${C_GREEN}None - all pools have available bots${C_RESET}\n"
	fi
	
	# By profile
	printf "\n${C_BOLD}By Profile:${C_RESET}\n"
	sql="SELECT profile_key, 
			   COUNT(*) as pool_count,
			   SUM(total_slots) as total_slots
			   FROM (
				   SELECT profile_key, pool_key, COUNT(*) as total_slots
				   FROM bot_controller_slot
				   WHERE enabled = 1 AND profile_key IS NOT NULL AND profile_key != ''
				   GROUP BY profile_key, pool_key
			   ) t
			   GROUP BY profile_key
			   ORDER BY pool_count DESC"
	
	printf "  %-20s  %-8s  %-10s\n" "PROFILE" "POOLS" "SLOTS"
	printf "  %s\n" "$(printf '%.0s-' {1..50})"
	
	while IFS=$'	' read -r profile count slots; do
		printf "  %-20s  %-8s  %-10s\n" "${profile:0:20}" "$count" "$slots"
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
	shortage)
		cmd_shortage "$@"
		;;
	unassigned)
		cmd_unassigned "$@"
		;;
	supply-demand)
		cmd_supply_demand "$@"
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
