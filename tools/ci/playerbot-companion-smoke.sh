#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-companion-smoke"

usage() {
	cat <<USAGE
Usage: bash tools/ci/playerbot-companion-smoke.sh [arm|run|check]

Commands:
  arm    arm the hidden companion selftest for the next test-account login,
         then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for selftest output,
         then run check
  check  require a passing mercenary + elemental continuity selftest line
USAGE
}

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBCOMP_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBCOMP_MANUAL_AID', 0, '0'),
('\$PBFNST_AUTORUN_AID', 0, '0')"
}

check() {
	local line
	line="$(pb_smoke_capture 320 | grep 'playerbot_companion_selftest:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing playerbot_companion_selftest line\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '%s\n' "$line"
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		mer_create_ok=1 mer_live_ok=1 mer_respawn_ok=1 mer_cleanup_ok=1 \
		ele_spawn_ok=1 ele_create_ok=1 ele_live_ok=1 ele_respawn_ok=1 ele_clear_ok=1 \
		pet_insert_ok=1 pet_respawn_ok=1 pet_clear_ok=1 park_ok=1 result=1
}

run() {
	arm
	pb_smoke_kill_kore playerbot-companion-kore playerbot-foundation-kore \
		playerbot-market-kore playerbot-item-kore playerbot-combat-kore playerbot-rodex-kore
	pb_smoke_launch_kore playerbot-companion-kore
	if ! pb_smoke_wait_result_line 'playerbot_companion_selftest:' 300 2600 >/dev/null; then
		printf '[%s] companion selftest line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 160 >&2
		return 1
	fi
	check
}

pb_smoke_main "$@"
