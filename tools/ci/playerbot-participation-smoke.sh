#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-participation-smoke.sh [arm|check]

Commands:
  arm    arm the hidden participation selftest for the next test-account login, then restart the repo stack
  check  show recent participation selftest lines and recent interaction trace rows
EOF
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`)
VALUES ('\$PBPST_AUTORUN_AID', 0, '$TEST_AID');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	printf '\n[playerbot-participation-smoke] Armed participation selftest for account %s.\n' "$TEST_AID"
	printf '[playerbot-participation-smoke] Next step: log in with the codex OpenKore profile, then run this script with check.\n'
}

check() {
	tmux capture-pane -J -pt rathena-dev-map-server -S -220 \; save-buffer - 2>/dev/null | tail -n 220 | grep 'playerbot_participation_selftest' || true
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`action\`, \`target_type\`, \`target_id\`, \`result\`, \`error_code\`, \`error_detail\`
FROM \`bot_trace_event\`
WHERE \`phase\` = 'interaction'
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
