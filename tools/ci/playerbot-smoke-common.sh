#!/usr/bin/env bash
# Shared helpers for playerbot smoke scripts.
# Source this at the top of each smoke script after set -euo pipefail.
#
# Usage:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"

# ── Configuration ──────────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

# ── Database helpers ───────────────────────────────────────────────────────────

# Run a mysql query against the bot database.
# Usage: pb_smoke_sql "SELECT ..."
pb_smoke_sql() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B -e "$1"
}

# Run a mysql heredoc-style query.
# Usage: pb_smoke_sql_heredoc <<'EOF' ... EOF
pb_smoke_sql_heredoc() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B
}

# Arm one or more mapreg values, then restart the dev stack.
# Usage: pb_smoke_arm_and_restart SCRIPT_LABEL mapreg_sql_values
#   mapreg_sql_values: the VALUES clause body, e.g.:
#     "('\$PBGST_AUTORUN_AID', 0, '$TEST_AID')"
#   or multiple comma-separated for multi-arm.
pb_smoke_arm_and_restart() {
	local label="$1"; shift
	local values="$1"
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`) VALUES
$values;
EOF
	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	printf '\n[%s] Armed selftest for account %s.\n' "$label" "$TEST_AID"
	printf '[%s] Next step: log in with the codex OpenKore profile, then run this script with check.\n' "$label"
}

# Arm and restart, then wait for the map server to come online.
# Usage: pb_smoke_arm_restart_wait SCRIPT_LABEL mapreg_sql_values [timeout_s]
pb_smoke_arm_restart_wait() {
	local label="$1"; shift
	local values="$1"; shift
	local timeout_s="${1:-20}"
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`) VALUES
$values;
EOF
	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	local elapsed=0
	while (( elapsed < timeout_s )); do
		if tmux capture-pane -J -pt rathena-dev-map-server -S -80 2>/dev/null | grep -q "Map Server is now online."; then
			break
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	printf '\n[%s] Armed selftest for account %s.\n' "$label" "$TEST_AID"
	printf '[%s] Next step: log in with the codex OpenKore profile, then run this script with check.\n' "$label"
}

# ── tmux / OpenKore helpers ────────────────────────────────────────────────────

# Launch an OpenKore session in tmux. Kills any existing session with the name.
# Usage: pb_smoke_launch_kore SESSION_NAME
pb_smoke_launch_kore() {
	local session="$1"
	tmux kill-session -t "$session" 2>/dev/null || true
	tmux new-session -d -s "$session" 'cd /root/testing/openkore && perl openkore.pl --control=/root/testing/openkore-control-codex'
	printf '[%s] Launched OpenKore in tmux session %s.\n' "${PB_SMOKE_LABEL:-playerbot-smoke}" "$session"
}

# Kill one or more OpenKore tmux sessions.
# Usage: pb_smoke_kill_kore session1 [session2 ...]
pb_smoke_kill_kore() {
	local s
	for s in "$@"; do
		tmux kill-session -t "$s" 2>/dev/null || true
	done
}

# Capture the map-server tmux pane.
# Usage: pb_smoke_capture [scrollback_lines]
# Prints captured text to stdout.
pb_smoke_capture() {
	local lines="${1:-220}"
	tmux capture-pane -J -pt rathena-dev-map-server -S "-${lines}" \; save-buffer - 2>/dev/null | tail -n "$lines" || true
}

# Wait for a pattern to appear in the map-server tmux pane.
# Usage: pb_smoke_wait_pattern PATTERN [timeout_s] [scrollback_lines]
# Returns 0 on match, 1 on timeout.
pb_smoke_wait_pattern() {
	local pattern="$1"
	local timeout_s="${2:-210}"
	local scroll="${3:-2400}"
	local elapsed=0 pane
	while (( elapsed < timeout_s )); do
		pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S "-${scroll}" 2>/dev/null || true)"
		if printf '%s\n' "$pane" | grep -q "$pattern"; then
			return 0
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 1
}

# Wait for a pattern and return the last matching line.
# Usage: pb_smoke_wait_result_line PATTERN [timeout_s] [scrollback_lines]
# Prints the matching line to stdout. Returns 0 on match, 1 on timeout.
pb_smoke_wait_result_line() {
	local pattern="$1"
	local timeout_s="${2:-210}"
	local scroll="${3:-3200}"
	local elapsed=0 pane line latest=""
	while (( elapsed < timeout_s )); do
		pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S "-${scroll}" \; save-buffer - 2>/dev/null | tail -n "$scroll" || true)"
		line="$(printf '%s\n' "$pane" | grep "$pattern" | tail -n 1 || true)"
		if [[ -n "$line" ]]; then
			latest="$line"
			if [[ "$line" == *"result=1"* ]]; then
				printf '%s\n' "$line"
				return 0
			fi
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	if [[ -n "$latest" ]]; then
		printf '%s\n' "$latest"
	fi
	return 1
}

# ── Signal validation ──────────────────────────────────────────────────────────

# Check a result line for required signals.
# Usage: pb_smoke_check_signals LABEL LINE signal1 signal2 ...
# Returns the number of failures (0 = all passed).
pb_smoke_check_signals() {
	local label="$1"; shift
	local line="$1"; shift
	local failures=0 key
	for key in "$@"; do
		if [[ "$line" != *"$key"* ]]; then
			printf '[%s] required signal missing: %s\n' "$label" "$key" >&2
			failures=$((failures + 1))
		fi
	done
	return "$failures"
}

# Check that a count is >= 1, printing a message on failure.
# Usage: pb_smoke_require_rows LABEL DESCRIPTION COUNT
# Returns 0 if count >= 1, 1 otherwise.
pb_smoke_require_rows() {
	local label="$1" desc="$2" count="$3"
	if (( count < 1 )); then
		printf '[%s] missing %s.\n' "$label" "$desc" >&2
		return 1
	fi
	return 0
}

# ── Main dispatcher ───────────────────────────────────────────────────────────

# Standard main dispatcher for smoke scripts.
# Usage: pb_smoke_main "$@"
# Expects the following functions to be defined in the calling script:
#   usage, arm, check
# Optionally: run, check_denied, check_rich, run_rich
pb_smoke_main() {
	local cmd="${1:-arm}"
	shift || true
	case "$cmd" in
		arm) arm ;;
		run) if declare -f run >/dev/null 2>&1; then run; else echo "run not supported" >&2; exit 1; fi ;;
		check) check ;;
		check-denied) if declare -f check_denied >/dev/null 2>&1; then check_denied; else echo "check-denied not supported" >&2; exit 1; fi ;;
		check-rich) if declare -f check_rich >/dev/null 2>&1; then check_rich; else echo "check-rich not supported" >&2; exit 1; fi ;;
		run-rich) if declare -f run_rich >/dev/null 2>&1; then run_rich; else echo "run-rich not supported" >&2; exit 1; fi ;;
		-h|--help|help) usage ;;
		*)
			usage
			exit 1
			;;
	esac
}
