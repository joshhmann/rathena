#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-market-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-market-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden merchant/market selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for merchant
         selftest output, then run check
  check  require a passing merchant selftest line with denial-path continuity
         (browse inactive + zeny limit), partial-fill + reopen signals, then
         print market interaction trace summary
EOF
}

arm() {
	pb_smoke_arm_restart_wait "$PB_SMOKE_LABEL" \
		"('\$PBMST_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBMST_MANUAL_AID', 0, '0'),
('\$PBFNST_AUTORUN_AID', 0, '0'),
('\$PBFNST_ACTIVE', 0, '0')"
}

check() {
	local pane line failures=0 line_count=0
	line="$(pb_smoke_wait_result_line 'playerbot_merchant_selftest: bot_id=' 240 || true)"
	pane="$(pb_smoke_capture 3200)"
	line_count="$(printf '%s\n' "$pane" | grep -c 'playerbot_merchant_selftest: bot_id=' || true)"
	printf '%s\n' "$pane" | grep 'playerbot_merchant_selftest:' | tail -n 4 || true
	if [[ -z "$line" ]]; then
		line="$(printf '%s\n' "$pane" | grep 'playerbot_merchant_selftest: bot_id=' | tail -n 1 || true)"
	fi

	if [[ -z "$line" ]]; then
		printf '[%s] missing merchant selftest line.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	if (( line_count > 1 )); then
		printf '[%s] duplicate merchant selftest result lines detected in one run (%d).\n' "$PB_SMOKE_LABEL" "$line_count" >&2
		return 1
	fi

	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		result=1 market_trace_ok=1 market_session_trace_ok=1 \
		buying_denial_trace_ok=1 mail_delivery_ok=1 mail_continuity_ok=1 \
		mail_idle_send_ok=1 mail_idle_delivery_ok=1 mail_idle_state_ok=1 \
		mail_trace_ok=1 buying_browse_inactive_denied_ok=1 \
		buying_browse_reopen_ok=1 buying_wrong_item_denied_ok=1 \
		buying_overfill_denied_ok=1 buying_denied_state_ok=1 \
		buying_sell_first_ok=1 buying_commit_first_ok=1 \
		buying_partial_ok=1 buying_sell_ok=1 buying_commit_total_ok=1 \
		buying_buyer_close_ok=1 buying_zeny_limit_denied_ok=1 \
		buying_zeny_denied_state_ok=1 buying_zeny_close_ok=1 \
		buying_reopen_ok=1 buying_close_ok=1 buying_closed_ok=1 \
		park_ok=1 || failures=$?

	printf '\n[%s] Recent market interaction trace summary\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `target_type`, `reason_code`, `result`, COUNT(*)
FROM `bot_trace_event`
WHERE UNIX_TIMESTAMP() - `ts` <= 1800
  AND `phase` = 'interaction'
  AND `target_type` IN ('vending','vendlist','buyingstore','buyinglist','buyingtrade')
GROUP BY `action`, `target_type`, `reason_code`, `result`
ORDER BY MAX(`id`) DESC
LIMIT 24;
EOF

	if (( failures > 0 )); then
		printf '\n[%s] market continuity check failed with %d missing signal(s).\n' "$PB_SMOKE_LABEL" "$failures" >&2
		return 1
	fi
	printf '\n[%s] market continuity check passed.\n' "$PB_SMOKE_LABEL"
}

run() {
	arm
	pb_smoke_launch_kore playerbot-market-kore
	check
}

pb_smoke_main "$@"
