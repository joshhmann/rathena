#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="${1:-quick}"
shift || true

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
EOF
}

check_cmd() {
	command -v "$1" >/dev/null 2>&1
}

run_quick() {
	cd "$REPO_ROOT"
	echo "[foundation-gate] quick: syntax checks"
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

	echo "[foundation-gate] quick: scenario catalog checks"
	bash tools/ci/playerbot-scenario.sh --no-color describe foundation-rich-gate >/dev/null
	bash tools/ci/playerbot-scenario.sh --no-color describe combat-repeated-transition-stress >/dev/null

	echo "[foundation-gate] quick: aggregate foundation run"
	bash tools/ci/playerbot-foundation-smoke.sh run
	echo "[foundation-gate] quick: pass"
}

run_full() {
	cd "$REPO_ROOT"
	echo "[foundation-gate] full: running closeout matrix"
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
		run_quick
		;;
	full)
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
