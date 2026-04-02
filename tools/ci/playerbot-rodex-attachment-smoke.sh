#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-rodex-attachment-smoke"

usage() {
	cat <<USAGE
Usage: bash tools/ci/playerbot-rodex-attachment-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden Rodex attachment selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for selftest output,
         then run check
  check  require a passing Rodex attachment selftest line and print recent mail traces
USAGE
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBMAIL_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBMAIL_MANUAL_AID', 0, '0'),
('\$PBMST_AUTORUN_AID', 0, '0'),
('\$PBFNST_AUTORUN_AID', 0, '0')"
}

check() {
	local line
	line="$(pb_smoke_capture 320 | grep 'playerbot_mail_selftest:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_mail_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	if ! pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		insert_ok=1 attach_seed_ok=1 refresh_ok=1 find_ok=1 item_seed_ok=1 zen_seed_ok=1 \
		get_ok=1 recv_ok=1 refresh2_ok=1 clear_ok=1 db_ok=1 park_ok=1 result=1; then
		return 1
	fi
	printf '\n[%s] Recent Rodex trace summary\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'SQL'
SELECT `action`, `target_type`, `reason_code`, `result`, `error_detail`
FROM `bot_trace_event`
WHERE `target_type` IN ('mail','mail_inbox','mail_attach')
ORDER BY `id` DESC
LIMIT 24;
SQL
}

run() {
	arm
	pb_smoke_kill_kore playerbot-rodex-kore playerbot-foundation-kore \
		playerbot-market-kore playerbot-item-kore playerbot-combat-kore
	pb_smoke_launch_kore playerbot-rodex-kore
	if ! pb_smoke_wait_result_line 'playerbot_mail_selftest:' 300 2600 >/dev/null; then
		printf '[%s] Rodex attachment selftest line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 160 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
