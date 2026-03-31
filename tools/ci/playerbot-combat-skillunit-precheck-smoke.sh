#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-combat-skillunit-precheck-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-combat-skillunit-precheck-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden skillunit precheck probe for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for precheck output,
         then run check
  check  require a passing precheck probe line and print recent precheck traces
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBCSPC_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBCSPC_MANUAL_AID', 0, '0'),
('\$PBCSUP_AUTORUN_AID', 0, '0'),
('\$PBCST_AUTORUN_AID', 0, '0')"
}

check() {
	local pane line failures=0
	pb_smoke_wait_pattern 'playerbot_combat_skillunit_precheck:' 120 || true
	pane="$(pb_smoke_capture 3200)"
	printf '%s\n' "$pane" | grep 'playerbot_combat_skillunit_precheck:' | tail -n 3 || true
	line="$(printf '%s\n' "$pane" | grep 'playerbot_combat_skillunit_precheck:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing precheck line.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		low_sp_apply_ok=1 low_sp_unit_ok=1 low_sp_trace_ok=1 \
		range_apply_ok=1 range_unit_ok=1 range_trace_ok=1 \
		cell_apply_ok=1 cell_unit_ok=1 cell_trace_ok=1 \
		result=1 || failures=$?

	printf '\n[%s] Recent precheck trace rows\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `target_type`, `reason_code`, `result`, `error_detail`
FROM `bot_trace_event`
WHERE `target_type` = 'skill_pos'
ORDER BY `id` DESC
LIMIT 24;
EOF

	if (( failures > 0 )); then
		printf '\n[%s] precheck failed with %d missing signal(s).\n' "$PB_SMOKE_LABEL" "$failures" >&2
		return 1
	fi
	printf '\n[%s] precheck passed.\n' "$PB_SMOKE_LABEL"
}

run() {
	arm
	pb_smoke_launch_kore playerbot-combat-skillunit-precheck-kore
	if ! pb_smoke_wait_pattern 'playerbot_combat_skillunit_precheck:' 300; then
		printf '[%s] precheck line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 80 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
