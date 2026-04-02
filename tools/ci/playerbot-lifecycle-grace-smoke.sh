#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-lifecycle-grace-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-lifecycle-grace-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden lifecycle grace selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for lifecycle
         grace output, then run check
  check  require a passing lifecycle grace selftest line and print recent
         scheduler/runtime evidence
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBLGST_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	local line
	line="$(pb_smoke_capture 3200 | grep 'playerbot_lifecycle_grace_selftest:' | grep 'result=' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_lifecycle_grace_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	if ! pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		active_ok=1 grace_mark_ok=1 deadline_ok=1 grace_count_ok=1 \
		park_ok=1 runtime_parked_ok=1 restore_ok=1 result=1; then
		return 1
	fi
	printf '\n[%s] Recent scheduler grace trace summary\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `target_type`, `reason_code`, `result`, COUNT(*)
FROM `bot_trace_event`
WHERE `phase` = 'scheduler'
  AND `action` IN ('scheduler.grace','scheduler.resumed','scheduler.parked')
  AND UNIX_TIMESTAMP() - `ts` <= 1800
GROUP BY `action`, `target_type`, `reason_code`, `result`
ORDER BY MAX(`id`) DESC
LIMIT 16;

SELECT p.`bot_key`, r.`current_state`, r.`park_state`, IFNULL(UNIX_TIMESTAMP(r.`despawn_grace_until`),0)
FROM `bot_runtime_state` r
JOIN `bot_profile` p ON p.`bot_id` = r.`bot_id`
LEFT JOIN `bot_behavior_config` b ON b.`bot_id` = p.`bot_id`
WHERE b.`profile_key` LIKE 'social.prontera%'
   OR p.`bot_key` LIKE 'quick_%'
ORDER BY r.`bot_id` DESC
LIMIT 12;
EOF
}

run() {
	arm
	pb_smoke_kill_kore playerbot-lifecycle-grace-kore playerbot-foundation-kore \
		playerbot-combat-kore playerbot-item-kore playerbot-market-kore playerbot-participation-kore
	pb_smoke_launch_kore playerbot-lifecycle-grace-kore
	local result_line=""
	result_line="$(pb_smoke_wait_result_line 'playerbot_lifecycle_grace_selftest:' 240 4000 || true)"
	if [[ -z "$result_line" || "$result_line" != *"result="* ]]; then
		printf '[%s] lifecycle grace selftest result line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 200 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
