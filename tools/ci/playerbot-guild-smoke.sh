#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-guild-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-guild-smoke.sh [arm|check]

Commands:
  arm    arm the hidden guild selftest for the next test-account login, then restart the repo stack
  check  show recent guild selftest lines from the map-server tmux pane
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBGST_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	tmux capture-pane -pt rathena-dev-map-server -S -200 2>/dev/null | tail -n 200 | grep 'playerbot_guild_selftest' || true
	pb_smoke_sql_heredoc <<'EOF'
SELECT `guild_name`, `last_member_join_at`, `last_notice_at`
FROM `bot_guild_runtime`
WHERE `guild_name` = 'PBG150001';
EOF
}

pb_smoke_main "$@"
