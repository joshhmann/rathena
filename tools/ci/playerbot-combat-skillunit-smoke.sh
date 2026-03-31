#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-combat-skillunit-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-combat-skillunit-smoke.sh [arm|check]

Commands:
  arm    arm the hidden skillunit probe for the next test-account login, then restart the repo stack
  check  show the recent skillunit probe line plus recent skillunit trace/audit rows
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBCSUP_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	pb_smoke_capture 220 | grep 'playerbot_combat_skillunit_probe' || true
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

pb_smoke_main "$@"
