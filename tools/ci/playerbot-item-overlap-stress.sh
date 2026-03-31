#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-item-overlap-stress"

CYCLES=1

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-item-overlap-stress.sh [options]

Options:
  --cycles N       Number of overlap cycles to run (default: 1)
  -h, --help       Show this help

Each cycle executes:
  1. item denied/recover pass (`playerbot-item-smoke.sh run`)
  2. aggregate foundation pass (`playerbot-foundation-smoke.sh run`)
  3. item denied/recover pass again (`playerbot-item-smoke.sh run`)
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--cycles)
			CYCLES="${2:?missing value for --cycles}"
			shift 2
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

if ! [[ "$CYCLES" =~ ^[0-9]+$ ]] || (( CYCLES < 1 )); then
	echo "--cycles must be a positive integer" >&2
	exit 1
fi

cd "$REPO_ROOT"

check_item_signals() {
	local output="$1"
	local line
	line="$(printf '%s\n' "$output" | grep 'playerbot_item_selftest: provision_ok=' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing item selftest line.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	for key in \
		result=1 loadout_denied_ok=1 loadout_recover_ok=1 \
		loadout_conflict_cleared_ok=1 mech_refine_reexec_ok=1 \
		loadout_continuity_ok=1; do
		if [[ "$line" != *"$key"* ]]; then
			printf '[%s] required item overlap signal missing: %s\n' "$PB_SMOKE_LABEL" "$key" >&2
			return 1
		fi
	done
	return 0
}

for i in $(seq 1 "$CYCLES"); do
	printf '[%s] cycle %d/%d pre-check\n' "$PB_SMOKE_LABEL" "$i" "$CYCLES"
	if ! pre_output="$(bash tools/ci/playerbot-item-smoke.sh run 2>&1)"; then
		printf '%s\n' "$pre_output" >&2
		printf '[%s] item pre-check failed at cycle %d.\n' "$PB_SMOKE_LABEL" "$i" >&2
		exit 1
	fi
	check_item_signals "$pre_output"

	printf '[%s] cycle %d/%d foundation pass\n' "$PB_SMOKE_LABEL" "$i" "$CYCLES"
	if ! foundation_output="$(bash tools/ci/playerbot-foundation-smoke.sh run 2>&1)"; then
		printf '%s\n' "$foundation_output" >&2
		printf '[%s] foundation pass failed at cycle %d.\n' "$PB_SMOKE_LABEL" "$i" >&2
		exit 1
	fi
	if [[ "$foundation_output" != *"foundation pass ok."* ]]; then
		printf '[%s] foundation output missing pass marker at cycle %d.\n' "$PB_SMOKE_LABEL" "$i" >&2
		exit 1
	fi

	printf '[%s] cycle %d/%d post-check\n' "$PB_SMOKE_LABEL" "$i" "$CYCLES"
	if ! post_output="$(bash tools/ci/playerbot-item-smoke.sh run 2>&1)"; then
		printf '%s\n' "$post_output" >&2
		printf '[%s] item post-check failed at cycle %d.\n' "$PB_SMOKE_LABEL" "$i" >&2
		exit 1
	fi
	check_item_signals "$post_output"
done

printf '[%s] pass: %d overlap cycle(s) completed.\n' "$PB_SMOKE_LABEL" "$CYCLES"
