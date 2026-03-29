#!/usr/bin/env bash
set -euo pipefail

# Playerbot Reservations Inspector
# CLI helper for inspecting bot_reservation ledger and bot_recovery_audit entries
# Answers: what resources are currently held, what's expired/stale,
# who holds what, what contention has occurred for a resource

DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-rathena}
DB_USER=${DB_USER:-rathena}
DB_PASS=${DB_PASS:-rathena_secure_2024}

DEFAULT_LIMIT=20
MAX_LIMIT=200

usage() {
	cat <<'EOF'
Usage: tools/ci/playerbot-reservations-inspector.sh [command] [options]

Playerbot Reservations Inspector - Inspect bot_reservation ledger and recovery audits

COMMANDS:
  summary                    Overview: counts per type, expiring-soon, stale
  active                     Active (non-expired) reservations grouped by type
  expired                    Expired but un-reaped rows (stale holders)
  by-bot <bot_id>            All reservations held by a specific holder_bot_id
  by-type <type>             Filter by reservation type
  contended <resource_key>   Contention history for a resource (via reservation_refs)
  audits [N]                 Recent bot_recovery_audit entries (default: 20)

RESERVATION TYPES:
  anchor, dialog_target, social_target, merchant_spot, party_role

EXAMPLES:
  # Quick overview
  tools/ci/playerbot-reservations-inspector.sh summary

  # All currently held reservations
  tools/ci/playerbot-reservations-inspector.sh active

  # What's been abandoned or expired
  tools/ci/playerbot-reservations-inspector.sh expired

  # What does bot 1 hold?
  tools/ci/playerbot-reservations-inspector.sh by-bot 1

  # All anchor reservations
  tools/ci/playerbot-reservations-inspector.sh by-type anchor

  # Full contention history for a resource
  tools/ci/playerbot-reservations-inspector.sh contended "prontera:anchor:152:179"

  # Recent cleanup audits (show 50)
  tools/ci/playerbot-reservations-inspector.sh audits 50

ENVIRONMENT:
  DB_HOST, DB_NAME, DB_USER, DB_PASS  Database connection settings
EOF
}

# Colors
if [[ -t 1 ]]; then
	C_RESET='\033[0m'
	C_BOLD='\033[1m'
	C_DIM='\033[2m'
	C_UNDERLINE='\033[4m'
	C_RED='\033[31m'
	C_GREEN='\033[32m'
	C_YELLOW='\033[33m'
	C_BLUE='\033[34m'
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
	C_CYAN=''
fi

# Execute query
query() {
	local sql="$1"
	mysql -N -B -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$sql" 2>/dev/null
}

# Format unix timestamp
format_ts() {
	local ts="$1"
	date -d "@$ts" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$ts"
}

# Format seconds remaining as "2m30s" or "EXPIRED"
# Accepts pre-computed remaining seconds (lease_until - now)
format_ttl() {
	local remaining="$1"
	if [[ "$remaining" -le 0 ]]; then
		echo "EXPIRED"
	elif [[ "$remaining" -lt 60 ]]; then
		echo "${remaining}s"
	else
		local mins=$(( remaining / 60 ))
		local secs=$(( remaining % 60 ))
		echo "${mins}m${secs}s"
	fi
}

# summary: counts per type, expiring-soon, stale
cmd_summary() {
	printf "${C_BOLD}Reservation Ledger Summary${C_RESET}\n\n"

	local sql="SELECT
		type,
		SUM(CASE WHEN lease_until >= UNIX_TIMESTAMP() THEN 1 ELSE 0 END) AS active,
		SUM(CASE WHEN lease_until < UNIX_TIMESTAMP() THEN 1 ELSE 0 END) AS stale,
		SUM(CASE WHEN lease_until >= UNIX_TIMESTAMP()
		         AND (lease_until - UNIX_TIMESTAMP()) < 60 THEN 1 ELSE 0 END) AS expiring_soon
		FROM bot_reservation
		GROUP BY type
		ORDER BY type"

	printf "  ${C_BOLD}${C_UNDERLINE}%-20s  %8s  %13s  %7s${C_RESET}\n" \
		"TYPE" "ACTIVE" "EXPIRING-SOON" "STALE"

	local any=0
	while IFS=$'\t' read -r type active stale expiring_soon; do
		any=1
		local active_color="$C_GREEN"
		local stale_color="$C_RESET"
		local expiring_color="$C_RESET"
		[[ "$active" -eq 0 ]] && active_color="$C_DIM"
		[[ "$stale" -gt 0 ]] && stale_color="$C_RED"
		[[ "$expiring_soon" -gt 0 ]] && expiring_color="$C_YELLOW"
		printf "  %-20s  ${active_color}%8s${C_RESET}  ${expiring_color}%13s${C_RESET}  ${stale_color}%7s${C_RESET}\n" \
			"$type" "$active" "$expiring_soon" "$stale"
	done < <(query "$sql")

	if [[ "$any" -eq 0 ]]; then
		printf "  ${C_DIM}No reservations in ledger${C_RESET}\n"
		return
	fi

	# Lock mode breakdown for active rows
	printf "\n  ${C_BOLD}Lock mode breakdown (active):${C_RESET}\n"
	sql="SELECT lock_mode, COUNT(*) FROM bot_reservation
	     WHERE lease_until >= UNIX_TIMESTAMP() GROUP BY lock_mode"
	while IFS=$'\t' read -r lock_mode cnt; do
		printf "    %-15s  %s\n" "$lock_mode" "$cnt"
	done < <(query "$sql")

	local total
	total=$(query "SELECT COUNT(*) FROM bot_reservation")
	printf "\n  ${C_DIM}Total rows in ledger: %s${C_RESET}\n" "$total"
}

# active: non-expired reservations
cmd_active() {
	printf "${C_BOLD}Active Reservations${C_RESET}\n\n"

	local sql="SELECT type, resource_key, holder_bot_id, holder_controller_id, lock_mode, lease_until, reason
	           FROM bot_reservation
	           WHERE lease_until >= UNIX_TIMESTAMP()
	           ORDER BY type, resource_key"

	printf "  ${C_BOLD}${C_UNDERLINE}%-16s  %-38s  %-6s  %-24s  %-10s  %-10s  %s${C_RESET}\n" \
		"TYPE" "RESOURCE_KEY" "BOT" "CONTROLLER" "MODE" "TTL" "REASON"

	local count=0
	local now
	now=$(date +%s)
	while IFS=$'\t' read -r type resource_key holder_bot holder_ctrl lock_mode lease_until reason; do
		count=$(( count + 1 ))
		local remaining=$(( lease_until - now ))
		local ttl
		ttl=$(format_ttl "$remaining")
		local ttl_color="$C_GREEN"
		[[ "$remaining" -le 0 ]] && ttl_color="$C_RED"
		[[ "$remaining" -gt 0 && "$remaining" -lt 30 ]] && ttl_color="$C_YELLOW"
		printf "  %-16s  ${C_CYAN}%-38s${C_RESET}  ${C_BLUE}%-6s${C_RESET}  %-24s  %-10s  ${ttl_color}%-10s${C_RESET}  %s\n" \
			"$type" "$resource_key" "$holder_bot" "$holder_ctrl" "$lock_mode" "$ttl" "$reason"
	done < <(query "$sql")

	if [[ "$count" -eq 0 ]]; then
		printf "  ${C_DIM}No active reservations${C_RESET}\n"
	else
		printf "\n  ${C_DIM}%d active reservation(s)${C_RESET}\n" "$count"
	fi
}

# expired: rows past lease_until (pending cleanup)
cmd_expired() {
	printf "${C_BOLD}${C_RED}Expired / Stale Reservations${C_RESET}\n\n"

	local sql="SELECT type, resource_key, holder_bot_id, holder_controller_id, lock_mode, lease_until, reason
	           FROM bot_reservation
	           WHERE lease_until < UNIX_TIMESTAMP()
	           ORDER BY lease_until DESC
	           LIMIT $DEFAULT_LIMIT"

	printf "  ${C_BOLD}${C_UNDERLINE}%-16s  %-38s  %-6s  %-24s  %-10s  %-20s  %s${C_RESET}\n" \
		"TYPE" "RESOURCE_KEY" "BOT" "CONTROLLER" "MODE" "EXPIRED-AT" "REASON"

	local count=0
	while IFS=$'\t' read -r type resource_key holder_bot holder_ctrl lock_mode lease_until reason; do
		count=$(( count + 1 ))
		local exp_ts
		exp_ts=$(format_ts "$lease_until")
		printf "  %-16s  ${C_RED}%-38s${C_RESET}  ${C_BLUE}%-6s${C_RESET}  %-24s  %-10s  ${C_DIM}%-20s${C_RESET}  %s\n" \
			"$type" "$resource_key" "$holder_bot" "$holder_ctrl" "$lock_mode" "$exp_ts" "$reason"
	done < <(query "$sql")

	if [[ "$count" -eq 0 ]]; then
		printf "  ${C_GREEN}No expired reservations — ledger is clean${C_RESET}\n"
	else
		printf "\n  ${C_YELLOW}%d expired row(s) pending cleanup${C_RESET}\n  ${C_DIM}Run F_PB_RES_ReapExpired() via the Reservation Lab NPC to clear${C_RESET}\n" "$count"
	fi
}

# by-bot: all reservations for a holder_bot_id
cmd_by_bot() {
	local bot_id="$1"
	printf "${C_BOLD}Reservations for bot %s${C_RESET}\n\n" "$bot_id"

	local sql="SELECT type, resource_key, lock_mode, lease_until, reason, created_at
	           FROM bot_reservation
	           WHERE holder_bot_id = '$bot_id'
	           ORDER BY lease_until DESC"

	printf "  ${C_BOLD}${C_UNDERLINE}%-16s  %-38s  %-10s  %-12s  %-20s  %s${C_RESET}\n" \
		"TYPE" "RESOURCE_KEY" "MODE" "STATUS" "CREATED" "REASON"

	local count=0
	local now
	now=$(date +%s)
	while IFS=$'\t' read -r type resource_key lock_mode lease_until reason created_at; do
		count=$(( count + 1 ))
		local remaining=$(( lease_until - now ))
		local ttl
		ttl=$(format_ttl "$remaining")
		local ttl_color="$C_GREEN"
		if [[ "$remaining" -le 0 ]]; then
			ttl_color="$C_RED"
		elif [[ "$remaining" -lt 30 ]]; then
			ttl_color="$C_YELLOW"
		fi
		local created_fmt
		created_fmt=$(format_ts "$created_at")
		printf "  %-16s  ${C_CYAN}%-38s${C_RESET}  %-10s  ${ttl_color}%-12s${C_RESET}  ${C_DIM}%-20s${C_RESET}  %s\n" \
			"$type" "$resource_key" "$lock_mode" "$ttl" "$created_fmt" "$reason"
	done < <(query "$sql")

	if [[ "$count" -eq 0 ]]; then
		printf "  ${C_DIM}No reservations found for bot %s${C_RESET}\n" "$bot_id"
	else
		printf "\n  ${C_DIM}%d reservation(s) total${C_RESET}\n" "$count"
	fi
}

# by-type: all reservations of a given type
cmd_by_type() {
	local res_type="$1"
	printf "${C_BOLD}Reservations of type: %s${C_RESET}\n\n" "$res_type"

	local sql="SELECT resource_key, holder_bot_id, holder_controller_id, lock_mode, lease_until, priority, reason
	           FROM bot_reservation
	           WHERE type = '$res_type'
	           ORDER BY lease_until DESC
	           LIMIT $DEFAULT_LIMIT"

	printf "  ${C_BOLD}${C_UNDERLINE}%-38s  %-6s  %-24s  %-10s  %-12s  %s${C_RESET}\n" \
		"RESOURCE_KEY" "BOT" "CONTROLLER" "MODE" "STATUS" "REASON"

	local count=0
	local now
	now=$(date +%s)
	while IFS=$'\t' read -r resource_key holder_bot holder_ctrl lock_mode lease_until priority reason; do
		count=$(( count + 1 ))
		local remaining=$(( lease_until - now ))
		local ttl
		ttl=$(format_ttl "$remaining")
		local ttl_color="$C_GREEN"
		if [[ "$remaining" -le 0 ]]; then
			ttl_color="$C_RED"
		elif [[ "$remaining" -lt 30 ]]; then
			ttl_color="$C_YELLOW"
		fi
		printf "  ${C_CYAN}%-38s${C_RESET}  ${C_BLUE}%-6s${C_RESET}  %-24s  %-10s  ${ttl_color}%-12s${C_RESET}  %s\n" \
			"$resource_key" "$holder_bot" "$holder_ctrl" "$lock_mode" "$ttl" "$reason"
	done < <(query "$sql")

	if [[ "$count" -eq 0 ]]; then
		printf "  ${C_DIM}No reservations of type '%s'${C_RESET}\n" "$res_type"
	else
		printf "\n  ${C_DIM}%d row(s)${C_RESET}\n" "$count"
	fi
}

# contended: trace event history for a resource_key via reservation_refs
cmd_contended() {
	local resource_key="$1"
	printf "${C_BOLD}Contention History: %s${C_RESET}\n\n" "$resource_key"

	# Show current holder from ledger (if any)
	local sql="SELECT holder_bot_id, holder_controller_id, lock_mode, lease_until
	           FROM bot_reservation
	           WHERE resource_key = '$resource_key'
	           LIMIT 1"
	local holder_info
	holder_info=$(query "$sql")
	if [[ -n "$holder_info" ]]; then
		local holder_bot holder_ctrl lock_mode lease_until
		IFS=$'\t' read -r holder_bot holder_ctrl lock_mode lease_until <<< "$holder_info"
		local remaining=$(( lease_until - $(date +%s) ))
		if [[ "$remaining" -gt 0 ]]; then
			local ttl
			ttl=$(format_ttl "$remaining")
			printf "  ${C_BOLD}Current holder:${C_RESET} ${C_GREEN}bot %s${C_RESET} via ${C_CYAN}%s${C_RESET} (%s, TTL: %s)\n\n" \
				"$holder_bot" "$holder_ctrl" "$lock_mode" "$ttl"
		else
			printf "  ${C_BOLD}Current holder:${C_RESET} ${C_RED}bot %s (EXPIRED)${C_RESET} via %s\n\n" \
				"$holder_bot" "$holder_ctrl"
		fi
	else
		printf "  ${C_DIM}No current holder in ledger${C_RESET}\n\n"
	fi

	# Trace events referencing this resource
	printf "  ${C_BOLD}Trace event history (reservation_refs):${C_RESET}\n\n"
	sql="SELECT ts, action, IFNULL(NULLIF(controller_id,''), '-'), char_id, result, IFNULL(NULLIF(error_code,''), '-')
	     FROM bot_trace_event
	     WHERE reservation_refs LIKE CONCAT('%', '$resource_key', '%')
	     ORDER BY id DESC
	     LIMIT $DEFAULT_LIMIT"

	printf "  ${C_BOLD}${C_UNDERLINE}%-19s  %-30s  %-8s  %-24s  %-8s  %s${C_RESET}\n" \
		"TIMESTAMP" "ACTION" "BOT" "CONTROLLER" "RESULT" "ERROR"

	local count=0
	while IFS=$'\t' read -r ts action controller char_id result error_code; do
		count=$(( count + 1 ))
		local ts_fmt
		ts_fmt=$(format_ts "$ts")
		local result_color="$C_RESET"
		case "$result" in
			ok|noop) result_color="$C_GREEN" ;;
			denied|aborted|failed) result_color="$C_RED" ;;
			retry|fallback|timeout) result_color="$C_YELLOW" ;;
			desynced|fatal) result_color="$C_RED$C_BOLD" ;;
		esac
		printf "  ${C_DIM}%-19s${C_RESET}  ${C_BOLD}%-30s${C_RESET}  ${C_BLUE}%-8s${C_RESET}  %-24s  ${result_color}%-8s${C_RESET}  %s\n" \
			"$ts_fmt" "$action" "$char_id" "$controller" "$result" "$error_code"
	done < <(query "$sql")

	if [[ "$count" -eq 0 ]]; then
		printf "  ${C_DIM}No trace events reference this resource key${C_RESET}\n"
	else
		printf "\n  ${C_DIM}%d trace event(s) found${C_RESET}\n" "$count"
	fi
}

# audits: recent bot_recovery_audit entries
cmd_audits() {
	local n="${1:-$DEFAULT_LIMIT}"
	if [[ "$n" -gt "$MAX_LIMIT" ]]; then
		n=$MAX_LIMIT
	fi

	# Verify table exists before querying
	local table_check
	table_check=$(mysql -N -B -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" \
		-e "SELECT COUNT(*) FROM information_schema.tables
		    WHERE table_schema='$DB_NAME' AND table_name='bot_recovery_audit'" 2>/dev/null)
	if [[ "$table_check" -eq 0 ]]; then
		printf "${C_YELLOW}bot_recovery_audit table not yet provisioned${C_RESET}\n"
		return
	fi

	printf "${C_BOLD}Recent Recovery Audits (last %d)${C_RESET}\n\n" "$n"

	local sql="SELECT ts, bot_id, char_id, scope, action, result, detail
	           FROM bot_recovery_audit
	           ORDER BY id DESC
	           LIMIT $n"

	printf "  ${C_BOLD}${C_UNDERLINE}%-19s  %-8s  %-10s  %-18s  %-28s  %-8s  %s${C_RESET}\n" \
		"TIMESTAMP" "BOT" "CHAR" "SCOPE" "ACTION" "RESULT" "DETAIL"

	local count=0
	while IFS=$'\t' read -r ts bot_id char_id scope action result detail; do
		count=$(( count + 1 ))
		local ts_fmt
		ts_fmt=$(format_ts "$ts")
		local result_color="$C_RESET"
		case "$result" in
			ok|fixed) result_color="$C_GREEN" ;;
			failed|error) result_color="$C_RED" ;;
			skipped|noop) result_color="$C_DIM" ;;
		esac
		printf "  ${C_DIM}%-19s${C_RESET}  ${C_BLUE}%-8s${C_RESET}  %-10s  %-18s  ${C_CYAN}%-28s${C_RESET}  ${result_color}%-8s${C_RESET}  %s\n" \
			"$ts_fmt" "$bot_id" "$char_id" "$scope" "$action" "$result" "$detail"
	done < <(query "$sql")

	if [[ "$count" -eq 0 ]]; then
		printf "  ${C_DIM}No recovery audit entries${C_RESET}\n"
	else
		printf "\n  ${C_DIM}Showing %d entries${C_RESET}\n" "$count"
	fi
}

# --- Main dispatcher ---
if [[ $# -eq 0 ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "help" ]]; then
	if [[ $# -eq 0 ]]; then
		cmd_summary
	else
		usage
	fi
	exit 0
fi

cmd="$1"
shift || true

case "$cmd" in
	summary)
		cmd_summary
		;;
	active)
		cmd_active
		;;
	expired)
		cmd_expired
		;;
	by-bot)
		if [[ $# -lt 1 ]]; then
			echo "Usage: playerbot-reservations-inspector.sh by-bot <bot_id>" >&2
			exit 1
		fi
		cmd_by_bot "$1"
		;;
	by-type)
		if [[ $# -lt 1 ]]; then
			echo "Usage: playerbot-reservations-inspector.sh by-type <type>" >&2
			echo "Types: anchor, dialog_target, social_target, merchant_spot, party_role" >&2
			exit 1
		fi
		cmd_by_type "$1"
		;;
	contended)
		if [[ $# -lt 1 ]]; then
			echo "Usage: playerbot-reservations-inspector.sh contended <resource_key>" >&2
			exit 1
		fi
		cmd_contended "$1"
		;;
	audits)
		cmd_audits "${1:-$DEFAULT_LIMIT}"
		;;
	*)
		echo "Unknown command: $cmd" >&2
		usage >&2
		exit 1
		;;
esac
