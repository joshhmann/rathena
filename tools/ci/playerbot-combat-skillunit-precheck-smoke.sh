#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

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

wait_for_precheck_line() {
	local timeout_s="${1:-210}" elapsed=0 pane
	while (( elapsed < timeout_s )); do
		pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -2400 2>/dev/null || true)"
		if printf '%s\n' "$pane" | grep -q 'playerbot_combat_skillunit_precheck:'; then
			return 0
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 1
}

launch_kore() {
	tmux kill-session -t playerbot-combat-skillunit-precheck-kore 2>/dev/null || true
	tmux new-session -d -s playerbot-combat-skillunit-precheck-kore 'cd /root/testing/openkore && perl openkore.pl --control=/root/testing/openkore-control-codex'
	printf '[playerbot-combat-skillunit-precheck-smoke] Launched OpenKore in tmux session playerbot-combat-skillunit-precheck-kore.\n'
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`) VALUES
('\$PBCSPC_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBCSPC_MANUAL_AID', 0, '0'),
('\$PBCSUP_AUTORUN_AID', 0, '0'),
('\$PBCST_AUTORUN_AID', 0, '0');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	printf '\n[playerbot-combat-skillunit-precheck-smoke] Armed skillunit precheck probe for account %s.\n' "$TEST_AID"
	printf '[playerbot-combat-skillunit-precheck-smoke] Next step: log in with the codex OpenKore profile, then run this script with check.\n'
}

check() {
	local pane line key failures=0
	wait_for_precheck_line 120 || true
	pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -3200 \; save-buffer - 2>/dev/null | tail -n 3200 || true)"
	printf '%s\n' "$pane" | grep 'playerbot_combat_skillunit_precheck:' | tail -n 3 || true
	line="$(printf '%s\n' "$pane" | grep 'playerbot_combat_skillunit_precheck:' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[playerbot-combat-skillunit-precheck-smoke] missing precheck line.\n' >&2
		return 1
	fi
	for key in low_sp_apply_ok=1 low_sp_unit_ok=1 low_sp_trace_ok=1 range_apply_ok=1 range_unit_ok=1 range_trace_ok=1 cell_apply_ok=1 cell_unit_ok=1 cell_trace_ok=1 result=1; do
		if [[ "$line" != *"$key"* ]]; then
			printf '[playerbot-combat-skillunit-precheck-smoke] required signal missing: %s\n' "$key" >&2
			failures=$((failures + 1))
		fi
	done

	printf '\n[playerbot-combat-skillunit-precheck-smoke] Recent precheck trace rows\n'
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`action\`, \`target_type\`, \`reason_code\`, \`result\`, \`error_detail\`
FROM \`bot_trace_event\`
WHERE \`target_type\` = 'skill_pos'
ORDER BY \`id\` DESC
LIMIT 24;
EOF

	if (( failures > 0 )); then
		printf '\n[playerbot-combat-skillunit-precheck-smoke] precheck failed with %d missing signal(s).\n' "$failures" >&2
		return 1
	fi
	printf '\n[playerbot-combat-skillunit-precheck-smoke] precheck passed.\n'
}

run() {
	arm
	launch_kore
	if ! wait_for_precheck_line 300; then
		printf '[playerbot-combat-skillunit-precheck-smoke] precheck line not observed within timeout.\n' >&2
		tmux capture-pane -J -pt rathena-dev-map-server -S -220 | tail -n 80 >&2 || true
		return 1
	fi
	check
}

main() {
	case "${1:-arm}" in
		arm) arm ;;
		run) run ;;
		check) check ;;
		-h|--help|help) usage ;;
		*)
			usage
			exit 1
			;;
	esac
}

main "$@"
