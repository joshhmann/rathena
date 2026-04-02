#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-combat-edge-smoke"

usage() {
	cat <<USAGE
Usage: bash tools/ci/playerbot-combat-edge-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden PvP / WoE edge probe for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for probe output,
         then run check
  check  require a passing edge probe line and print recent combat trace/audit rows
USAGE
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBCEDGE_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBCEDGE_MANUAL_AID', 0, '0'),
('\$PBCST_AUTORUN_AID', 0, '0'),
('\$PBCSUP_AUTORUN_AID', 0, '0'),
('\$PBCSPC_AUTORUN_AID', 0, '0')"
}

check() {
	local line
	line="$(pb_smoke_capture 320 | grep 'playerbot_combat_edge_probe:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_combat_edge_probe line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	if ! pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		pvp_keep1_ok=1 pvp_auto_ok=1 pvp_keep2_ok=1 \
		gvg_auto_ok=1 gvg_keep_ok=1 trace_ok=1 audit_ok=1 result=1; then
		return 1
	fi
	printf '\n[%s] Recent combat death/respawn traces\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'SQL'
SELECT `phase`, `action`, `target_type`, `reason_code`, `result`, `error_detail`
FROM `bot_trace_event`
WHERE `phase` = 'combat'
  AND `target_type` IN ('death','respawn')
ORDER BY `id` DESC
LIMIT 20;

SELECT `scope`, `action`, `result`, `detail`
FROM `bot_recovery_audit`
WHERE `scope` = 'combat'
  AND `action` IN ('death','respawn')
ORDER BY `id` DESC
LIMIT 16;
SQL
}

run() {
	arm
	pb_smoke_kill_kore playerbot-combat-edge-kore playerbot-foundation-kore \
		playerbot-combat-kore playerbot-item-kore playerbot-market-kore
	pb_smoke_launch_kore playerbot-combat-edge-kore
	if ! pb_smoke_wait_result_line 'playerbot_combat_edge_probe:' 300 2600 >/dev/null; then
		printf '[%s] combat edge probe result line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 160 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
