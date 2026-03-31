#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-combat-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-combat-smoke.sh [arm|check]

Commands:
  arm    arm the hidden combat selftest for the next test-account login, then restart the repo stack
  check  show recent combat selftest lines plus recent combat trace/audit rows
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBCST_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	local line
	line="$(pb_smoke_capture 260 | grep 'playerbot_combat_selftest' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_combat_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	if ! pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" continuity_loop_ok=1 result=1; then
		return 1
	fi
	pb_smoke_sql_heredoc <<'EOF'
SELECT `phase`, `action`, `target_type`, `reason_code`, `result`, `error_detail`
FROM `bot_trace_event`
WHERE `phase` = 'combat'
   OR (`phase` = 'reconcile' AND `target_type` = 'skillunit')
ORDER BY `id` DESC
LIMIT 20;

SELECT `scope`, `action`, `result`, `detail`
FROM `bot_recovery_audit`
WHERE `scope` IN ('combat','npc','storage','trade','skillunit')
ORDER BY `id` DESC
LIMIT 16;
EOF
}

pb_smoke_main "$@"
