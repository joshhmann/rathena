#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-market-session-stress"

CYCLES=2

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-market-session-stress.sh [options]

Options:
  --cycles N       Number of market session cycles to run (default: 2)
  -h, --help       Show this help

Each cycle executes `bash tools/ci/playerbot-market-smoke.sh run` and verifies:
  - mail delivery/continuity signals
  - buyingstore partial/reopen/close continuity signals
  - overall selftest result signal
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

check_market_signals() {
	local output="$1"
	local line
	line="$(printf '%s\n' "$output" | grep 'playerbot_merchant_selftest: bot_id=' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing merchant selftest line.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	for key in \
		result=1 mail_delivery_ok=1 mail_continuity_ok=1 \
		mail_idle_send_ok=1 mail_idle_delivery_ok=1 mail_idle_state_ok=1 \
		buying_partial_ok=1 buying_commit_total_ok=1 \
		buying_reopen_ok=1 buying_closed_ok=1; do
		if [[ "$line" != *"$key"* ]]; then
			printf '[%s] required market session signal missing: %s\n' "$PB_SMOKE_LABEL" "$key" >&2
			return 1
		fi
	done
	return 0
}

for i in $(seq 1 "$CYCLES"); do
	printf '[%s] cycle %d/%d\n' "$PB_SMOKE_LABEL" "$i" "$CYCLES"
	if ! output="$(bash tools/ci/playerbot-market-smoke.sh run 2>&1)"; then
		printf '%s\n' "$output" >&2
		printf '[%s] market run failed at cycle %d.\n' "$PB_SMOKE_LABEL" "$i" >&2
		exit 1
	fi
	check_market_signals "$output"
done

printf '[%s] pass: %d market session cycle(s) completed.\n' "$PB_SMOKE_LABEL" "$CYCLES"
