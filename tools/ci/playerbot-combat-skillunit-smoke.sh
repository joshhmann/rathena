#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-combat-skillunit-smoke.sh [arm|check]

Commands:
  arm    arm the hidden skillunit probe for the next test-account login, then restart the repo stack
  check  show the recent skillunit probe line plus recent skillunit trace/audit rows
EOF
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`)
VALUES ('\$PBCSUP_AUTORUN_AID', 0, '$TEST_AID');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	printf '\n[playerbot-combat-skillunit-smoke] Armed skillunit probe for account %s.\n' "$TEST_AID"
	printf '[playerbot-combat-skillunit-smoke] Next step: log in with the codex OpenKore profile, then run this script with check.\n'
}

check() {
	tmux capture-pane -J -pt rathena-dev-map-server -S -220 \; save-buffer - 2>/dev/null | tail -n 220 | grep 'playerbot_combat_skillunit_probe' || true
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`action\`, \`target_type\`, \`reason_code\`, \`result\`, \`error_detail\`
FROM \`bot_trace_event\`
WHERE \`target_type\` IN ('skill_self','skill_pos','skillunit')
ORDER BY \`id\` DESC
LIMIT 20;

SELECT \`scope\`, \`action\`, \`result\`, \`detail\`
FROM \`bot_recovery_audit\`
WHERE \`scope\` = 'skillunit'
ORDER BY \`id\` DESC
LIMIT 12;
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
