#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${PB_TEST_LOG_DIR:-$REPO_ROOT/logs/playerbot-tests}"

RUNS=5
STOP_ON_FAIL=0

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-foundation-flake-hunt.sh [options]

Options:
  --runs N         Number of quick-gate attempts (default: 5)
  --stop-on-fail   Stop immediately after first failure
  -h, --help       Show this help

Purpose:
  Repeatedly run `playerbot-foundation-gate.sh quick` and, on failures,
  auto-extract high-signal diagnostics from the failed gate log so flakes are
  faster to triage.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--runs)
			RUNS="${2:?missing value for --runs}"
			shift 2
			;;
		--stop-on-fail)
			STOP_ON_FAIL=1
			shift
			;;
		-h|--help)
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

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || (( RUNS < 1 )); then
	echo "--runs must be a positive integer" >&2
	exit 1
fi

cd "$REPO_ROOT"
mkdir -p "$LOG_DIR"

extract_failure_context() {
	local log_file="$1"
	printf '[flake-hunt] failure log: %s\n' "$log_file"
	printf '[flake-hunt] selftest fail lines:\n'
	grep -E 'selftest did not pass|foundation pass failed' "$log_file" | tail -n 20 || true
	printf '[flake-hunt] combat fail hints:\n'
	grep -E 'playerbot_combat_fail_hint|playerbot_combat_cont_loop' "$log_file" | tail -n 20 || true
	printf '[flake-hunt] final stage/result lines:\n'
	grep -E 'playerbot_foundation_selftest: stage=|playerbot_.*_selftest: .*result=' "$log_file" | tail -n 40 || true
}

passes=0
failures=0

for i in $(seq 1 "$RUNS"); do
	printf '[flake-hunt] run %d/%d\n' "$i" "$RUNS"
	before_latest="$(ls -1t "$LOG_DIR"/foundation-gate-quick-*.log 2>/dev/null | head -n 1 || true)"
	if bash tools/ci/playerbot-foundation-gate.sh quick; then
		passes=$((passes + 1))
		printf '[flake-hunt] run %d PASS\n' "$i"
		continue
	fi

	failures=$((failures + 1))
	printf '[flake-hunt] run %d FAIL\n' "$i" >&2
	after_latest="$(ls -1t "$LOG_DIR"/foundation-gate-quick-*.log 2>/dev/null | head -n 1 || true)"
	if [[ -n "$after_latest" && "$after_latest" != "$before_latest" ]]; then
		extract_failure_context "$after_latest"
	elif [[ -n "$after_latest" ]]; then
		extract_failure_context "$after_latest"
	else
		printf '[flake-hunt] no quick-gate log file found.\n' >&2
	fi

	if (( STOP_ON_FAIL > 0 )); then
		break
	fi
done

printf '[flake-hunt] summary pass=%d fail=%d runs=%d\n' "$passes" "$failures" "$RUNS"
if (( failures > 0 )); then
	exit 1
fi
