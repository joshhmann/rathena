#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-combat-skillunit-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-combat-skillunit-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden skillunit probe for the next test-account login, then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for probe output,
         then run check
  check  require a passing skillunit probe line and print recent trace/audit rows
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBCSUP_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	local line
	line="$(pb_smoke_capture 260 | grep 'playerbot_combat_skillunit_probe' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_combat_skillunit_probe line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	if ! pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" result=1; then
		return 1
	fi
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `target_type`, `reason_code`, `result`, `error_detail`
FROM `bot_trace_event`
WHERE `target_type` IN ('skill_self','skill_pos','skillunit')
ORDER BY `id` DESC
LIMIT 20;

SELECT `scope`, `action`, `result`, `detail`
FROM `bot_recovery_audit`
WHERE `scope` = 'skillunit'
ORDER BY `id` DESC
LIMIT 12;
EOF
}

run() {
	arm
	pb_smoke_kill_kore playerbot-combat-skillunit-kore playerbot-foundation-kore \
		playerbot-combat-kore playerbot-item-kore playerbot-market-kore
	pb_smoke_launch_kore playerbot-combat-skillunit-kore
	if ! pb_smoke_wait_result_line 'playerbot_combat_skillunit_probe:' 300 2600 >/dev/null; then
		printf '[%s] skillunit probe result line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 140 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
