#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-participation-smoke"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-participation-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden participation selftest for the next test-account login, then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for participation
         selftest output, then run check
  check  require a passing participation selftest line and print recent interaction traces
EOF
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBPST_AUTORUN_AID', 0, '$TEST_AID')"
}

check() {
	local line
	line="$(pb_smoke_capture 260 | grep 'playerbot_participation_selftest' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_participation_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	if ! pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" result=1; then
		return 1
	fi
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `target_type`, `target_id`, `result`, `error_code`, `error_detail`
FROM `bot_trace_event`
WHERE `phase` = 'interaction'
ORDER BY `id` DESC
LIMIT 16;
EOF
}

run() {
	arm
	pb_smoke_kill_kore playerbot-participation-kore playerbot-foundation-kore \
		playerbot-combat-kore playerbot-item-kore playerbot-market-kore
	pb_smoke_launch_kore playerbot-participation-kore
	if ! pb_smoke_wait_result_line 'playerbot_participation_selftest:' 300 2600 >/dev/null; then
		printf '[%s] participation selftest result line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 140 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
