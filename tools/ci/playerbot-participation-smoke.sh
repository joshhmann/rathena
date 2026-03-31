#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-participation-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-participation-smoke.sh [arm|check]

Commands:
  arm    arm the hidden participation selftest for the next test-account login, then restart the repo stack
  check  show recent participation selftest lines and recent interaction trace rows
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBPST_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	pb_smoke_capture 220 | grep 'playerbot_participation_selftest' || true
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `target_type`, `target_id`, `result`, `error_code`, `error_detail`
FROM `bot_trace_event`
WHERE `phase` = 'interaction'
ORDER BY `id` DESC
LIMIT 16;
EOF
}

pb_smoke_main "$@"
