#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="${1:-quick}"
shift || true
LOG_DIR="${PB_TEST_LOG_DIR:-$REPO_ROOT/logs/playerbot-tests}"
RUN_TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE=""

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-foundation-gate.sh [quick|full]

Modes:
  quick  Fast pre-integration gate:
         - smoke script syntax checks
         - scenario catalog sanity checks
         - 1x aggregate foundation smoke run
  full   Full closeout matrix via playerbot-foundation-closeout.sh

Notes:
  - Use quick on every candidate integration.
  - Use full for closeout checkpoints and major merges.
  - This is an integration/smoke gate, not a unit-test suite.
EOF
}

check_cmd() {
	command -v "$1" >/dev/null 2>&1
}

phase() {
	printf '[foundation-gate] phase=%s\n' "$1"
}

init_log() {
	local mode="$1"
	mkdir -p "$LOG_DIR"
	LOG_FILE="$LOG_DIR/foundation-gate-${mode}-${RUN_TS}.log"
	exec > >(tee -a "$LOG_FILE") 2>&1
	printf '[foundation-gate] log=%s\n' "$LOG_FILE"
	printf '[foundation-gate] mode=%s started=%s\n' "$mode" "$RUN_TS"
}

run_quick() {
	cd "$REPO_ROOT"
	phase "quick.syntax"
	echo "[foundation-gate] test=smoke script shell syntax"
	bash -n \
		tools/ci/playerbot-smoke-common.sh \
		tools/ci/playerbot-foundation-smoke.sh \
		tools/ci/playerbot-combat-smoke.sh \
		tools/ci/playerbot-item-smoke.sh \
		tools/ci/playerbot-market-smoke.sh \
		tools/ci/playerbot-participation-smoke.sh \
		tools/ci/playerbot-state-smoke.sh \
		tools/ci/playerbot-guild-smoke.sh \
		tools/ci/playerbot-combat-skillunit-smoke.sh \
		tools/ci/playerbot-combat-skillunit-precheck-smoke.sh

	phase "quick.scenario-catalog"
	echo "[foundation-gate] test=scenario definition sanity"
	bash tools/ci/playerbot-scenario.sh --no-color describe foundation-rich-gate >/dev/null
	bash tools/ci/playerbot-scenario.sh --no-color describe combat-repeated-transition-stress >/dev/null

	phase "quick.aggregate-foundation"
	echo "[foundation-gate] test=aggregate foundation smoke pass"
	bash tools/ci/playerbot-foundation-smoke.sh run
	echo "[foundation-gate] quick: pass"
}

run_full() {
	cd "$REPO_ROOT"
	phase "full.closeout-matrix"
	echo "[foundation-gate] test=closeout matrix (aggregate + rich)"
	bash tools/ci/playerbot-foundation-closeout.sh "$@"
	echo "[foundation-gate] full: pass"
}

for dep in bash tmux mysql; do
	if ! check_cmd "$dep"; then
		echo "Missing required dependency: $dep" >&2
		exit 1
	fi
done

case "$MODE" in
	quick)
		init_log "quick"
		run_quick
		;;
	full)
		init_log "full"
		run_full "$@"
		;;
	-h|--help|help)
		usage
		;;
	*)
		echo "Unknown mode: $MODE" >&2
		usage
		exit 1
		;;
esac
