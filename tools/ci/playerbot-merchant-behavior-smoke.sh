#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-merchant-behavior-smoke"

usage() {
	cat <<USAGE
Usage: bash tools/ci/playerbot-merchant-behavior-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden merchant-behavior selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for selftest output,
         then run check
  check  require a passing merchant-behavior selftest line and print behavior memory rows
USAGE
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBMERBHV_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBMERBHV_MANUAL_AID', 0, '0'),
('\$PBFNST_AUTORUN_AID', 0, '0')"
}

check() {
	local line
	line="$(pb_smoke_capture 360 | grep 'playerbot_merchant_behavior_selftest:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_merchant_behavior_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		summary_ok=1 cfg_ok=1 policy_pick$=open_shop policy_ok=1 mark_ok=1 \
		spawn_ok=1 bootstrap_ok=1 open_state_ok=1 runtime_ok=1 proxy_ok=1 \
		runtime_summary_ok=1 summary_build_ok=1 park_ok=1 result=1
	printf '\n[%s] Current merchant behavior memory rows\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'SQL'
SELECT `memory_key`, `int_value`, `text_value`, `source_tag`
FROM `bot_shared_memory`
WHERE `memory_scope` = 'controller'
  AND `memory_key` LIKE 'behavior.%'
ORDER BY `updated_at` DESC
LIMIT 16;
SQL
}

run() {
	arm
	pb_smoke_kill_kore playerbot-merchant-behavior-kore playerbot-market-kore \
		playerbot-party-behavior-kore playerbot-social-kore playerbot-behavior-kore \
		playerbot-foundation-kore playerbot-item-kore playerbot-combat-kore
	pb_smoke_launch_kore playerbot-merchant-behavior-kore
	if ! pb_smoke_wait_result_line 'playerbot_merchant_behavior_selftest:' 300 2600 >/dev/null; then
		printf '[%s] merchant behavior selftest line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 180 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
