#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RATHENA_DIR="${RATHENA_DIR:-$REPO_ROOT}"
TMUX_PREFIX="${TMUX_PREFIX:-rathena-dev}"

usage() {
	cat <<EOF
Usage: bash tools/dev/playerbot-dev.sh <command>

Commands:
  cleanup   Kill orphan rAthena repo server processes and stray tmux lanes
  start     Start login/char/map from this repo in tmux after cleanup
  stop      Stop login/char/map tmux sessions, then cleanup strays
  restart   Stop, cleanup, and restart the repo server stack
  status    Show current tmux sessions, listeners, and repo-owned processes
EOF
}

log() {
	printf '[playerbot-dev] %s\n' "$1"
}

session_name() {
	printf '%s-%s' "$TMUX_PREFIX" "$1"
}

require_binary() {
	local bin="$1"
	if [[ ! -x "$RATHENA_DIR/$bin" ]]; then
		echo "Missing binary: $RATHENA_DIR/$bin" >&2
		echo "Build the repo first." >&2
		exit 1
	fi
}

cleanup_server_processes() {
	local -a names=(map-server char-server login-server)

	for name in "${names[@]}"; do
		while IFS= read -r pid; do
			[[ -z "$pid" ]] && continue

			local exe cwd
			exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)"
			cwd="$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)"

			if [[ "$exe" == "$RATHENA_DIR/$name" || "$cwd" == "$RATHENA_DIR" ]]; then
				log "Killing orphan $name process $pid"
				kill "$pid" 2>/dev/null || true
			fi
		done < <(pgrep -x "$name" || true)
	done

	while IFS=$'\t' read -r session command; do
		[[ -z "$session" ]] && continue
		case "$command" in
			*"$RATHENA_DIR"*"/map-server"*|*"$RATHENA_DIR"*"/char-server"*|*"$RATHENA_DIR"*"/login-server"*|*"cd $RATHENA_DIR && ./map-server"*|*"cd $RATHENA_DIR && ./char-server"*|*"cd $RATHENA_DIR && ./login-server"*)
				if [[ "$session" != "$(session_name "map-server")" && "$session" != "$(session_name "char-server")" && "$session" != "$(session_name "login-server")" ]]; then
					log "Killing orphan tmux session $session"
					tmux kill-session -t "$session" 2>/dev/null || true
				fi
				;;
		esac
	done < <(tmux list-panes -a -F '#{session_name}'$'\t''#{pane_start_command}' 2>/dev/null || true)
}

start_servers() {
	require_binary login-server
	require_binary char-server
	require_binary map-server

	cleanup_server_processes
	cd "$RATHENA_DIR"
	for name in login-server char-server map-server; do
		local session
		session="$(session_name "$name")"
		tmux kill-session -t "$session" 2>/dev/null || true
		log "Starting $name in tmux session $session"
		tmux new-session -d -s "$session" "./$name"
		sleep 2
	done
}

stop_servers() {
	for name in map-server char-server login-server; do
		local session
		session="$(session_name "$name")"
		tmux kill-session -t "$session" 2>/dev/null || true
	done
	cleanup_server_processes
}

show_status() {
	echo "Repo: $RATHENA_DIR"
	echo "tmux:"
	tmux ls 2>/dev/null || true
	echo
	echo "listeners:"
	ss -ltnp 2>/dev/null | grep -E ':6900|:6121|:5121' || true
	echo
	echo "repo-owned processes:"
	for name in login-server char-server map-server; do
		while IFS= read -r pid; do
			[[ -z "$pid" ]] && continue
			exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)"
			cwd="$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)"
			if [[ "$exe" == "$RATHENA_DIR/$name" || "$cwd" == "$RATHENA_DIR" ]]; then
				printf '%s pid=%s exe=%s cwd=%s\n' "$name" "$pid" "$exe" "$cwd"
			fi
		done < <(pgrep -x "$name" || true)
	done
}

main() {
	local cmd="${1:-status}"
	case "$cmd" in
		cleanup) cleanup_server_processes ;;
		start) start_servers ;;
		stop) stop_servers ;;
		restart)
			stop_servers
			start_servers
			;;
		status) show_status ;;
		-h|--help|help) usage ;;
		*)
			usage
			exit 1
			;;
	esac
}

main "$@"
