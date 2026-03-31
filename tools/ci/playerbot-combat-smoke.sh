#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-combat-smoke.sh [arm|check]

Commands:
  arm    arm the hidden combat selftest for the next test-account login, then restart the repo stack
  check  show recent combat selftest lines plus recent combat trace/audit rows
EOF
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`)
VALUES ('\$PBCST_AUTORUN_AID', 0, '$TEST_AID');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	printf '\n[playerbot-combat-smoke] Armed combat selftest for account %s.\n' "$TEST_AID"
	printf '[playerbot-combat-smoke] Next step: log in with the codex OpenKore profile, then run this script with check.\n'
}

check() {
	local line
	line="$(tmux capture-pane -J -pt rathena-dev-map-server -S -260 \; save-buffer - 2>/dev/null | tail -n 260 | grep 'playerbot_combat_selftest' | tail -n 1 || true)"
	if [[ -n "$line" ]]; then
		printf '%s\n' "$line"
	else
		printf '[playerbot-combat-smoke] missing playerbot_combat_selftest line\n' >&2
		return 1
	fi
	if [[ "$line" != *"continuity_loop_ok=1"* ]]; then
		printf '[playerbot-combat-smoke] continuity loop gate failed: %s\n' "$line" >&2
		return 1
	fi
	if [[ "$line" != *"result=1"* ]]; then
		printf '[playerbot-combat-smoke] combat selftest did not pass: %s\n' "$line" >&2
		return 1
	fi
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`phase\`, \`action\`, \`target_type\`, \`reason_code\`, \`result\`, \`error_detail\`
FROM \`bot_trace_event\`
WHERE \`phase\` = 'combat'
   OR (\`phase\` = 'reconcile' AND \`target_type\` = 'skillunit')
ORDER BY \`id\` DESC
LIMIT 20;

SELECT \`scope\`, \`action\`, \`result\`, \`detail\`
FROM \`bot_recovery_audit\`
WHERE \`scope\` IN ('combat','npc','storage','trade','skillunit')
ORDER BY \`id\` DESC
LIMIT 16;
EOF
}

main() {
	case "${1:-arm}" in
		arm) arm ;;
		check) check ;;
		-h|--help|help) usage ;;
		*)
			usage
			exit 1
			;;
	esac
}

main "$@"
