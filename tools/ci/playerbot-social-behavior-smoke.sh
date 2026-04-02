#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-social-behavior-smoke"

usage() {
	cat <<USAGE
Usage: bash tools/ci/playerbot-social-behavior-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden social-behavior selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for selftest output,
         then run check
  check  require a passing social-behavior selftest line and print behavior memory rows
USAGE
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBSOC_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBSOC_MANUAL_AID', 0, '0'),
('\$PBFNST_AUTORUN_AID', 0, '0')"
}

check() {
	local line
	line="$(pb_smoke_capture 320 | grep 'playerbot_social_behavior_selftest:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_social_behavior_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		summary_ok=1 ticks_ok=1 summary_build_ok=1 decision_ok=1 move_ok=1 park_ok=1 result=1
	printf '\n[%s] Current social behavior memory rows\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'SQL'
SELECT `memory_key`, `int_value`, `text_value`, `source_tag`
FROM `bot_shared_memory`
WHERE `memory_scope` = 'controller'
  AND (`memory_key` LIKE 'behavior.%' OR `memory_key` LIKE 'behavior.%.social.%')
ORDER BY `updated_at` DESC
LIMIT 16;
SQL
}

run() {
	arm
	pb_smoke_kill_kore playerbot-social-kore playerbot-foundation-kore \
		playerbot-behavior-kore playerbot-market-kore playerbot-item-kore playerbot-combat-kore
	pb_smoke_launch_kore playerbot-social-kore
	if ! pb_smoke_wait_result_line 'playerbot_social_behavior_selftest:' 300 2600 >/dev/null; then
		printf '[%s] social behavior selftest line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 160 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
