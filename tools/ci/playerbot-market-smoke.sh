#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-market-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden merchant/market selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for merchant
         selftest output, then run check
  check  require a passing merchant selftest line with partial-fill + reopen
         signals, then print market interaction trace summary
EOF
}

wait_for_merchant_result_line() {
	local timeout_s="${1:-210}" elapsed=0 pane
	while (( elapsed < timeout_s )); do
		pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -2200 2>/dev/null || true)"
		if printf '%s\n' "$pane" | grep -q 'playerbot_merchant_selftest: bot_id='; then
			return 0
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 1
}

launch_kore() {
	tmux kill-session -t playerbot-market-kore 2>/dev/null || true
	tmux new-session -d -s playerbot-market-kore 'cd /root/testing/openkore && perl openkore.pl --control=/root/testing/openkore-control-codex'
	printf '[playerbot-market-smoke] Launched OpenKore in tmux session playerbot-market-kore.\n'
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`) VALUES
('\$PBMST_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBMST_MANUAL_AID', 0, '0'),
('\$PBFNST_AUTORUN_AID', 0, '0'),
('\$PBFNST_ACTIVE', 0, '0');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	for _ in $(seq 1 20); do
		if tmux capture-pane -J -pt rathena-dev-map-server -S -80 2>/dev/null | grep -q "Map Server is now online."; then
			break
		fi
		sleep 1
	done
	printf '\n[playerbot-market-smoke] Armed merchant/market selftest for account %s.\n' "$TEST_AID"
	printf '[playerbot-market-smoke] Next step: log in once with the codex OpenKore profile, then run this script with check.\n'
}

check() {
	local pane line key failures=0
	wait_for_merchant_result_line 180 || true
	pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -3200 \; save-buffer - 2>/dev/null | tail -n 3200 || true)"
	printf '%s\n' "$pane" | grep 'playerbot_merchant_selftest:' | tail -n 4 || true
	line="$(printf '%s\n' "$pane" | grep 'playerbot_merchant_selftest: bot_id=' | tail -n 1 || true)"

	if [[ -z "$line" ]]; then
		printf '[playerbot-market-smoke] missing merchant selftest line.\n' >&2
		return 1
	fi

	for key in result=1 market_trace_ok=1 buying_sell_first_ok=1 buying_partial_ok=1 buying_sell_ok=1 buying_buyer_close_ok=1 buying_reopen_ok=1 buying_close_ok=1 buying_closed_ok=1 park_ok=1; do
		if [[ "$line" != *"$key"* ]]; then
			printf '[playerbot-market-smoke] required signal missing: %s\n' "$key" >&2
			failures=$((failures + 1))
		fi
	done

	printf '\n[playerbot-market-smoke] Recent market interaction trace summary\n'
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`action\`, \`target_type\`, \`reason_code\`, \`result\`, COUNT(*)
FROM \`bot_trace_event\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= 1800
  AND \`phase\` = 'interaction'
  AND \`target_type\` IN ('vending','vendlist','buyingstore','buyinglist','buyingtrade')
GROUP BY \`action\`, \`target_type\`, \`reason_code\`, \`result\`
ORDER BY MAX(\`id\`) DESC
LIMIT 24;
EOF

	if (( failures > 0 )); then
		printf '\n[playerbot-market-smoke] market continuity check failed with %d missing signal(s).\n' "$failures" >&2
		return 1
	fi
	printf '\n[playerbot-market-smoke] market continuity check passed.\n'
}

run() {
	arm
	launch_kore
	if ! wait_for_merchant_result_line 300; then
		printf '[playerbot-market-smoke] merchant selftest line not observed within timeout.\n' >&2
		tmux capture-pane -J -pt rathena-dev-map-server -S -220 | tail -n 80 >&2 || true
		return 1
	fi
	check
}

main() {
	case "${1:-arm}" in
		arm) arm ;;
		run) run ;;
		check) check ;;
		-h|--help|help) usage ;;
		*)
			usage
			exit 1
			;;
	esac
}

main "$@"
