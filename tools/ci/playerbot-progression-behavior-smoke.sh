#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-progression-behavior-smoke"

usage() {
	cat <<USAGE
Usage: bash tools/ci/playerbot-progression-behavior-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden progression-behavior selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for selftest output,
         then run check
  check  require a passing progression-behavior selftest line and print behavior memory rows
USAGE
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBPROGBHV_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBPROGBHV_MANUAL_AID', 0, '0'),
('\$PBFNST_AUTORUN_AID', 0, '0')"
}

check() {
	local line
	line="$(pb_smoke_capture 420 | grep 'playerbot_progression_behavior_selftest:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_progression_behavior_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		summary_ok=1 cfg_ok=1 spawn_ok=1 policy_pick$=advance_relay policy_ok=1 \
		mark_ok=1 quest_ok=1 stage1_ok=1 stage2_ok=1 progression_state_ok=1 progression_summary_ok=1 summary_build_ok=1 park_ok=1 result=1
	printf '\n[%s] Current progression behavior memory rows\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'SQL'
SELECT `memory_key`, `int_value`, `text_value`, `source_tag`
FROM `bot_shared_memory`
WHERE `memory_scope` = 'controller'
  AND `memory_key` LIKE 'behavior.%'
ORDER BY `updated_at` DESC
LIMIT 16;
SQL
	printf '\n[%s] Current persisted progression state\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'SQL'
SELECT p.`bot_key`, pg.`build_tag`, pg.`progression_profile`, pg.`base_level`, pg.`job_level`, pg.`equipment_profile`, pg.`daily_activity_budget`, pg.`last_progression_tick`
FROM `bot_profile` p
JOIN `bot_progression_state` pg ON pg.`bot_id` = p.`bot_id`
WHERE p.`bot_key` = 'quick_prog_open';
SQL
}

run() {
	arm
	pb_smoke_kill_kore playerbot-progression-behavior-kore playerbot-combat-behavior-kore \
		playerbot-merchant-behavior-kore playerbot-party-behavior-kore \
		playerbot-social-kore playerbot-behavior-kore playerbot-foundation-kore
	pb_smoke_launch_kore playerbot-progression-behavior-kore
	if ! pb_smoke_wait_result_line 'playerbot_progression_behavior_selftest:' 300 3000 >/dev/null; then
		printf '[%s] progression behavior selftest line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 220 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
