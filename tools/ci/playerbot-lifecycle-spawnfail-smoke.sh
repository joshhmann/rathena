#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-lifecycle-spawnfail-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-lifecycle-spawnfail-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden lifecycle spawn-failure selftest for the next
         test-account login, then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for the
         spawn-failure selftest result line, then run check
  check  require a passing lifecycle spawn-failure selftest line and print
         recent runtime evidence
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBLSF_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	local line
	line="$(pb_smoke_capture 3200 | grep 'playerbot_lifecycle_spawnfail_selftest:' | grep 'result=' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_lifecycle_spawnfail_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	if ! pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		spawn_req_ok=1 status_absent_ok=1 spawn_ack_stable_ok=1 runtime_clear_ok=1 \
		loadout_trace_ok=1 recovery_spawn_ok=1 recovery_remove_ok=1 result=1; then
		return 1
	fi
	printf '\n[%s] Recent spawn-failure runtime summary\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'EOF'
SELECT `char_id`, `map_name`, `x`, `y`, `state`
FROM `headless_pc_runtime`
WHERE `char_id` = '150015'
LIMIT 4;

SELECT `phase`, `action`, `target_type`, `reason_code`, `result`, `error_detail`
FROM `bot_trace_event`
WHERE `char_id` = '150015'
  AND UNIX_TIMESTAMP() - `ts` <= 1800
ORDER BY `id` DESC
LIMIT 20;
EOF
}

run() {
	local result_line=""
	arm
	pb_smoke_kill_kore playerbot-lifecycle-spawnfail-kore playerbot-foundation-kore \
		playerbot-combat-kore playerbot-item-kore playerbot-market-kore playerbot-participation-kore \
		playerbot-lifecycle-grace-kore
	pb_smoke_launch_kore playerbot-lifecycle-spawnfail-kore
	result_line="$(pb_smoke_wait_result_line 'playerbot_lifecycle_spawnfail_selftest:' 240 4000 || true)"
	if [[ -z "$result_line" || "$result_line" != *"result="* ]]; then
		printf '[%s] lifecycle spawn-failure selftest result line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 200 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
