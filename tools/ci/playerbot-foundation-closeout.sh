#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

RUN_COUNT=10
RICH_COUNT=5
STOP_ON_FAIL=1
CHECK_SCENARIOS=1

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-foundation-closeout.sh [options]

Options:
  --run-count N         Number of aggregate foundation runs (default: 10)
  --rich-count N        Number of rich foundation runs (default: 5)
  --no-rich             Skip rich runs
  --no-scenario-check   Skip scenario catalog presence checks
  --continue-on-fail    Continue after failures (default: stop on first failure)
  -h, --help            Show this help

Notes:
  - This script executes the foundation closeout stability gate.
  - It validates scenario-definition presence for key closeout fronts.
  - It does not replace manual semantic review of traces/audits for new slices.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--run-count)
			RUN_COUNT="${2:?missing value for --run-count}"
			shift 2
			;;
		--rich-count)
			RICH_COUNT="${2:?missing value for --rich-count}"
			shift 2
			;;
		--no-rich)
			RICH_COUNT=0
			shift
			;;
		--no-scenario-check)
			CHECK_SCENARIOS=0
			shift
			;;
		--continue-on-fail)
			STOP_ON_FAIL=0
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

if ! [[ "$RUN_COUNT" =~ ^[0-9]+$ ]]; then
	echo "--run-count must be a non-negative integer" >&2
	exit 1
fi

if ! [[ "$RICH_COUNT" =~ ^[0-9]+$ ]]; then
	echo "--rich-count must be a non-negative integer" >&2
	exit 1
fi

cd "$REPO_ROOT"

check_cmd() {
	command -v "$1" >/dev/null 2>&1
}

for dep in bash cmake tmux mysql; do
	if ! check_cmd "$dep"; then
		echo "Missing required dependency: $dep" >&2
		exit 1
	fi
done

SCENARIOS=(
	combat-baseline
	combat-skillunit-mapchange-cleanup
	combat-skillunit-death-cleanup
	combat-skillunit-quit-cleanup
	combat-skillunit-promotion-precheck
	status-continuity
	status-death-cleanup
	status-map-continuity
	status-respawn-reconcile
	status-recovery-integrity
	death-respawn
	item-loadout-continuity
	loadout-denied-recover
	loadout-overlap-continuity
	mechanic-cleanup
	mechanic-execution-rollback
	market-buyingstore-partial-fill
	market-buyingstore-reopen
	market-buyingstore-denial-continuity
	market-mail-delivery-integrity
	market-session-restart-continuity
	combat-repeated-transition-stress
	foundation-rich-gate
)

if (( CHECK_SCENARIOS > 0 )); then
	echo "[foundation-closeout] Verifying required scenario definitions..."
	for id in "${SCENARIOS[@]}"; do
		if ! bash tools/ci/playerbot-scenario.sh --no-color describe "$id" >/dev/null; then
			echo "[foundation-closeout] Missing or invalid scenario definition: $id" >&2
			exit 1
		fi
	done
fi

echo "[foundation-closeout] Building map-server..."
cmake --build build --target map-server -j4

run_loop() {
	local label="$1"
	local cmd="$2"
	local count="$3"
	local i
	local passed=0
	local failed=0

	if (( count == 0 )); then
		echo "[foundation-closeout] Skipping ${label}."
		echo "${label}:0:0"
		return 0
	fi

	for i in $(seq 1 "$count"); do
		echo "[foundation-closeout] ${label} ${i}/${count}"
		if eval "$cmd"; then
			passed=$((passed + 1))
		else
			failed=$((failed + 1))
			echo "[foundation-closeout] ${label} failed at iteration ${i}." >&2
			if (( STOP_ON_FAIL > 0 )); then
				echo "${label}:${passed}:${failed}"
				return 1
			fi
		fi
	done

	echo "${label}:${passed}:${failed}"
	return 0
}

run_summary="$(run_loop "foundation-run" "bash tools/ci/playerbot-foundation-smoke.sh run" "$RUN_COUNT")" || {
	echo "$run_summary"
	exit 1
}
echo "$run_summary"

rich_summary="$(run_loop "foundation-run-rich" "bash tools/ci/playerbot-foundation-smoke.sh run-rich" "$RICH_COUNT")" || {
	echo "$rich_summary"
	exit 1
}
echo "$rich_summary"

echo "[foundation-closeout] Done."
echo "[foundation-closeout] Manual follow-up: inspect recent trace/audit summaries for any unexpected reason/result drift."
