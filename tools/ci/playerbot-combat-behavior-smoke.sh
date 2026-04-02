#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-combat-behavior-smoke"

usage() {
	cat <<USAGE
Usage: bash tools/ci/playerbot-combat-behavior-smoke.sh [arm|run|check]

Commands:
	arm    arm the hidden combat-behavior selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for selftest output,
         then run check
  check  require a passing combat-behavior selftest line and print behavior memory rows
USAGE
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBCOMBHV_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBCOMBHV_MANUAL_AID', 0, '0'),
('\$PBFNST_AUTORUN_AID', 0, '0')"
}

check() {
	local line
	line="$(pb_smoke_capture 420 | grep 'playerbot_combat_behavior_selftest:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_combat_behavior_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		summary_ok=1 cfg_ok=1 spawn_ok=1 equip_ok=1 target_ok=1 \
		policy_pick$=attack_target policy_ok=1 mark_ok=1 attack_ok=1 \
		engaged_ok=1 state_ok=1 stop_ok=1 target_clear_ok=1 \
		retreat_cfg_ok=1 retreat_pick$=disengage retreat_ok=1 \
		tank_pick$=hold_position tank_ok=1 \
		dps_pick$=attack_target dps_ok=1 \
		support_pick$=disengage support_ok=1 \
		caster_pick$=cast_skill caster_pick_ok=1 caster_cast_ok=1 caster_clear_ok=1 \
		summary_build_ok=1 park_ok=1 result=1
	printf '\n[%s] Current combat behavior memory rows\n' "$PB_SMOKE_LABEL"
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
	pb_smoke_kill_kore playerbot-combat-behavior-kore playerbot-combat-kore \
		playerbot-merchant-behavior-kore playerbot-party-behavior-kore \
		playerbot-social-kore playerbot-behavior-kore playerbot-foundation-kore \
		playerbot-item-kore
	pb_smoke_launch_kore playerbot-combat-behavior-kore
	if ! pb_smoke_wait_result_line 'playerbot_combat_behavior_selftest:' 300 2600 >/dev/null; then
		printf '[%s] combat behavior selftest line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 180 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
