#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-state-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-state-smoke.sh [arm|check]

Commands:
  arm    arm the hidden state/ownership selftest for the next test-account login, then restart the repo stack
  check  show recent state selftest lines and recent ownership recovery audits
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBSTAT_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	pb_smoke_capture 220 | grep 'playerbot_state_selftest' || true
	pb_smoke_sql_heredoc <<'EOF'
SELECT `scope`, `action`, `result`, `detail`
FROM `bot_recovery_audit`
WHERE `scope` = 'ownership'
ORDER BY `id` DESC
LIMIT 8;
EOF
}

pb_smoke_main "$@"
