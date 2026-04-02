#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${PB_TEST_LOG_DIR:-$REPO_ROOT/logs/playerbot-tests}"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE=""

RUN_COUNT=10
RICH_COUNT=5
STRESS_RUNS=3
OVERLAP_CYCLES=1
MARKET_CYCLES=1
TRACE_QUALITY_MINUTES=180
LIFECYCLE_SPAWNFAIL_RUNS=1
LIFECYCLE_GRACE_RUNS=1
STRESS_CHECK_RUNS=1
OVERLAP_CHECK_RUNS=1
MARKET_CHECK_RUNS=1
TRACE_QUALITY_RUNS=1
LIFECYCLE_SPAWNFAIL_CHECK_RUNS=1
LIFECYCLE_GRACE_CHECK_RUNS=1
STOP_ON_FAIL=1
CHECK_SCENARIOS=1

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-foundation-closeout.sh [options]

Options:
  --run-count N         Number of aggregate foundation runs (default: 10)
  --rich-count N        Number of rich foundation runs (default: 5)
  --stress-runs N       Number of repeated-transition stress runs (default: 3)
  --overlap-cycles N    Number of loadout-overlap stress cycles (default: 1)
  --market-cycles N     Number of market-session stress cycles (default: 1)
  --trace-quality-min N Trace quality lookback window in minutes (default: 180)
  --lifecycle-spawnfail-runs N Number of lifecycle spawn-failure helper runs (default: 1)
  --lifecycle-grace-runs N Number of lifecycle-grace helper runs (default: 1)
  --no-rich             Skip rich runs
  --no-stress           Skip repeated-transition stress check
  --no-overlap          Skip loadout-overlap stress check
  --no-market           Skip market-session stress check
  --no-trace-quality    Skip trace quality checkpoint
  --no-lifecycle-spawnfail Skip lifecycle spawn-failure checkpoint
  --no-lifecycle-grace  Skip lifecycle grace checkpoint
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
		--stress-runs)
			STRESS_RUNS="${2:?missing value for --stress-runs}"
			shift 2
			;;
		--no-stress)
			STRESS_RUNS=0
			STRESS_CHECK_RUNS=0
			shift
			;;
		--overlap-cycles)
			OVERLAP_CYCLES="${2:?missing value for --overlap-cycles}"
			shift 2
			;;
		--no-overlap)
			OVERLAP_CYCLES=0
			OVERLAP_CHECK_RUNS=0
			shift
			;;
		--market-cycles)
			MARKET_CYCLES="${2:?missing value for --market-cycles}"
			shift 2
			;;
		--no-market)
			MARKET_CYCLES=0
			MARKET_CHECK_RUNS=0
			shift
			;;
		--trace-quality-min)
			TRACE_QUALITY_MINUTES="${2:?missing value for --trace-quality-min}"
			shift 2
			;;
		--lifecycle-spawnfail-runs)
			LIFECYCLE_SPAWNFAIL_RUNS="${2:?missing value for --lifecycle-spawnfail-runs}"
			shift 2
			;;
		--lifecycle-grace-runs)
			LIFECYCLE_GRACE_RUNS="${2:?missing value for --lifecycle-grace-runs}"
			shift 2
			;;
		--no-trace-quality)
			TRACE_QUALITY_RUNS=0
			shift
			;;
		--no-lifecycle-spawnfail)
			LIFECYCLE_SPAWNFAIL_RUNS=0
			LIFECYCLE_SPAWNFAIL_CHECK_RUNS=0
			shift
			;;
		--no-lifecycle-grace)
			LIFECYCLE_GRACE_RUNS=0
			LIFECYCLE_GRACE_CHECK_RUNS=0
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

if ! [[ "$STRESS_RUNS" =~ ^[0-9]+$ ]]; then
	echo "--stress-runs must be a non-negative integer" >&2
	exit 1
fi

if ! [[ "$OVERLAP_CYCLES" =~ ^[0-9]+$ ]]; then
	echo "--overlap-cycles must be a non-negative integer" >&2
	exit 1
fi

if ! [[ "$MARKET_CYCLES" =~ ^[0-9]+$ ]]; then
	echo "--market-cycles must be a non-negative integer" >&2
	exit 1
fi

if ! [[ "$TRACE_QUALITY_MINUTES" =~ ^[0-9]+$ ]]; then
	echo "--trace-quality-min must be a non-negative integer" >&2
	exit 1
fi

if ! [[ "$LIFECYCLE_SPAWNFAIL_RUNS" =~ ^[0-9]+$ ]]; then
	echo "--lifecycle-spawnfail-runs must be a non-negative integer" >&2
	exit 1
fi

if ! [[ "$LIFECYCLE_GRACE_RUNS" =~ ^[0-9]+$ ]]; then
	echo "--lifecycle-grace-runs must be a non-negative integer" >&2
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
	echo "[foundation-closeout] config run_count=${RUN_COUNT} rich_count=${RICH_COUNT} stress_runs=${STRESS_RUNS} stress_check_runs=${STRESS_CHECK_RUNS} overlap_cycles=${OVERLAP_CYCLES} overlap_check_runs=${OVERLAP_CHECK_RUNS} market_cycles=${MARKET_CYCLES} market_check_runs=${MARKET_CHECK_RUNS} trace_quality_runs=${TRACE_QUALITY_RUNS} trace_quality_min=${TRACE_QUALITY_MINUTES} lifecycle_spawnfail_runs=${LIFECYCLE_SPAWNFAIL_RUNS} lifecycle_spawnfail_check_runs=${LIFECYCLE_SPAWNFAIL_CHECK_RUNS} lifecycle_grace_runs=${LIFECYCLE_GRACE_RUNS} lifecycle_grace_check_runs=${LIFECYCLE_GRACE_CHECK_RUNS} stop_on_fail=${STOP_ON_FAIL} scenario_check=${CHECK_SCENARIOS}"
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
	lifecycle-spawn-failure-cleanup
	lifecycle-despawn-grace-window
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

run_loop "combat-transition-stress" "bash tools/ci/playerbot-combat-transition-stress.sh --runs ${STRESS_RUNS} --strict-drift" "${STRESS_CHECK_RUNS}" || {
	echo "$RUN_LOOP_SUMMARY"
	exit 1
}
echo "$RUN_LOOP_SUMMARY"

run_loop "item-overlap-stress" "bash tools/ci/playerbot-item-overlap-stress.sh --cycles ${OVERLAP_CYCLES}" "${OVERLAP_CHECK_RUNS}" || {
	echo "$RUN_LOOP_SUMMARY"
	exit 1
}
echo "$RUN_LOOP_SUMMARY"

run_loop "market-session-stress" "bash tools/ci/playerbot-market-session-stress.sh --cycles ${MARKET_CYCLES}" "${MARKET_CHECK_RUNS}" || {
	echo "$RUN_LOOP_SUMMARY"
	exit 1
}
echo "$RUN_LOOP_SUMMARY"

run_loop "trace-quality" "bash tools/ci/playerbot-trace-quality.sh --since ${TRACE_QUALITY_MINUTES}" "${TRACE_QUALITY_RUNS}" || {
	echo "$RUN_LOOP_SUMMARY"
	exit 1
}
echo "$RUN_LOOP_SUMMARY"

run_loop "lifecycle-spawnfail" "bash tools/ci/playerbot-lifecycle-spawnfail-smoke.sh run" "${LIFECYCLE_SPAWNFAIL_CHECK_RUNS}" || {
	echo "$RUN_LOOP_SUMMARY"
	exit 1
}
echo "$RUN_LOOP_SUMMARY"

run_loop "lifecycle-grace" "bash tools/ci/playerbot-lifecycle-grace-smoke.sh run" "${LIFECYCLE_GRACE_CHECK_RUNS}" || {
	echo "$RUN_LOOP_SUMMARY"
	exit 1
}
echo "$RUN_LOOP_SUMMARY"

echo "[foundation-closeout] Done."
echo "[foundation-closeout] Manual follow-up: inspect recent trace/audit summaries for any unexpected reason/result drift."
