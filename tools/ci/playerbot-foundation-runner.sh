#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-quick}"
shift || true

STREAM_MAP=0
ON_EXISTING="kill" # kill|check|ignore

CLOSEOUT_ARGS=()

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-foundation-runner.sh [quick|full|closeout] [options]

Modes:
  quick     Run foundation quick gate
  full      Run foundation full gate (closeout matrix)
  closeout  Run foundation closeout directly

Options:
  --stream-map             Stream map-server pane snapshots during foundation runs
  --on-existing MODE       How to handle existing foundation jobs: kill|check|ignore
                           (default: kill)
  --run-count N            Passed to closeout/full
  --rich-count N           Passed to closeout/full
  --no-rich                Passed to closeout/full
  --no-scenario-check      Passed to closeout/full
  --continue-on-fail       Passed to closeout/full
  -h, --help               Show this help

Notes:
  - This orchestrates integration/smoke runs, not unit tests.
  - Use --stream-map when you want live progression context in logs.
EOF
}

if [[ "$MODE" == "-h" || "$MODE" == "--help" || "$MODE" == "help" ]]; then
	usage
	exit 0
fi

while [[ $# -gt 0 ]]; do
	case "$1" in
		--stream-map)
			STREAM_MAP=1
			shift
			;;
		--on-existing)
			ON_EXISTING="${2:?missing value for --on-existing}"
			shift 2
			;;
		--run-count|--rich-count)
			CLOSEOUT_ARGS+=("$1" "${2:?missing value for $1}")
			shift 2
			;;
		--no-rich|--no-scenario-check|--continue-on-fail)
			CLOSEOUT_ARGS+=("$1")
			shift
			;;
		-h|--help|help)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			usage
			exit 1
			;;
	esac
done

if [[ "$ON_EXISTING" != "kill" && "$ON_EXISTING" != "check" && "$ON_EXISTING" != "ignore" ]]; then
	echo "--on-existing must be one of: kill, check, ignore" >&2
	exit 1
fi

PROC_RE='playerbot-foundation-gate.sh|playerbot-foundation-closeout.sh|playerbot-foundation-smoke.sh'

list_existing() {
	pgrep -af "$PROC_RE" || true
}

existing="$(list_existing)"
if [[ -n "$existing" ]]; then
	case "$ON_EXISTING" in
		check)
			echo "[foundation-runner] existing foundation processes detected:" >&2
			echo "$existing" >&2
			echo "[foundation-runner] aborting due to --on-existing check." >&2
			exit 1
			;;
		kill)
			echo "[foundation-runner] killing existing foundation processes..."
			echo "$existing"
			pkill -f "$PROC_RE" || true
			sleep 1
			remaining="$(list_existing)"
			if [[ -n "$remaining" ]]; then
				echo "[foundation-runner] warning: remaining processes after kill attempt:" >&2
				echo "$remaining" >&2
			fi
			;;
		ignore)
			echo "[foundation-runner] ignoring existing foundation processes."
			;;
	esac
fi

if (( STREAM_MAP > 0 )); then
	export PB_STREAM_MAP=1
	echo "[foundation-runner] map stream enabled (PB_STREAM_MAP=1)."
fi

case "$MODE" in
	quick)
		echo "[foundation-runner] mode=quick (integration/smoke)"
		exec bash tools/ci/playerbot-foundation-gate.sh quick
		;;
	full)
		echo "[foundation-runner] mode=full (integration/smoke closeout)"
		exec bash tools/ci/playerbot-foundation-gate.sh full "${CLOSEOUT_ARGS[@]}"
		;;
	closeout)
		echo "[foundation-runner] mode=closeout (integration/smoke matrix)"
		exec bash tools/ci/playerbot-foundation-closeout.sh "${CLOSEOUT_ARGS[@]}"
		;;
	*)
		echo "Unknown mode: $MODE" >&2
		usage
		exit 1
		;;
esac
