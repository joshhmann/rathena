#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${PB_TEST_LOG_DIR:-$REPO_ROOT/logs/playerbot-tests}"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE=""

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
  - This script executes the foundation closeout stability gate (integration/smoke).
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

init_log() {
	mkdir -p "$LOG_DIR"
	LOG_FILE="$LOG_DIR/foundation-closeout-${RUN_TS}.log"
	exec > >(tee -a "$LOG_FILE") 2>&1
	echo "[foundation-closeout] log=${LOG_FILE}"
	echo "[foundation-closeout] started=${RUN_TS}"
	echo "[foundation-closeout] config run_count=${RUN_COUNT} rich_count=${RICH_COUNT} stop_on_fail=${STOP_ON_FAIL} scenario_check=${CHECK_SCENARIOS}"
}

init_log

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
	echo "[foundation-closeout] phase=scenario-definition-check"
	echo "[foundation-closeout] Verifying required scenario definitions..."
	for id in "${SCENARIOS[@]}"; do
		if ! bash tools/ci/playerbot-scenario.sh --no-color describe "$id" >/dev/null; then
			echo "[foundation-closeout] Missing or invalid scenario definition: $id" >&2
			exit 1
		fi
	done
fi

echo "[foundation-closeout] phase=build-map-server"
echo "[foundation-closeout] Building map-server..."
cmake --build build --target map-server -j4

run_loop() {
	local label="$1"
	local cmd="$2"
	local count="$3"
	local i
	local passed=0
	local failed=0
	local start_ts end_ts elapsed_s
	RUN_LOOP_SUMMARY=""

	if (( count == 0 )); then
		echo "[foundation-closeout] Skipping ${label}."
		RUN_LOOP_SUMMARY="${label}:0:0"
		echo "$RUN_LOOP_SUMMARY"
		return 0
	fi

	for i in $(seq 1 "$count"); do
		start_ts="$(date +%s)"
		echo "[foundation-closeout] phase=${label} iteration=${i}/${count}"
		echo "[foundation-closeout] test_cmd=${cmd}"
		if eval "$cmd"; then
			passed=$((passed + 1))
			end_ts="$(date +%s)"
			elapsed_s=$((end_ts - start_ts))
			echo "[foundation-closeout] ${label} iteration ${i} PASS elapsed=${elapsed_s}s"
		else
			failed=$((failed + 1))
			end_ts="$(date +%s)"
			elapsed_s=$((end_ts - start_ts))
			echo "[foundation-closeout] ${label} iteration ${i} FAIL elapsed=${elapsed_s}s." >&2
			if (( STOP_ON_FAIL > 0 )); then
				RUN_LOOP_SUMMARY="${label}:${passed}:${failed}"
				echo "$RUN_LOOP_SUMMARY"
				return 1
			fi
		fi
	done

	RUN_LOOP_SUMMARY="${label}:${passed}:${failed}"
	echo "$RUN_LOOP_SUMMARY"
	return 0
}

run_loop "foundation-run" "bash tools/ci/playerbot-foundation-smoke.sh run" "$RUN_COUNT" || {
	echo "$RUN_LOOP_SUMMARY"
	exit 1
}
echo "$RUN_LOOP_SUMMARY"

run_loop "foundation-run-rich" "bash tools/ci/playerbot-foundation-smoke.sh run-rich" "$RICH_COUNT" || {
	echo "$RUN_LOOP_SUMMARY"
	exit 1
}
echo "$RUN_LOOP_SUMMARY"

echo "[foundation-closeout] Done."
echo "[foundation-closeout] Manual follow-up: inspect recent trace/audit summaries for any unexpected reason/result drift."
