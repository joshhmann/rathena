#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-state-smoke.sh [arm|check]

Commands:
  arm    arm the hidden state/ownership selftest for the next test-account login, then restart the repo stack
  check  show recent state selftest lines and recent ownership recovery audits
EOF
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`)
VALUES ('\$PBSTAT_AUTORUN_AID', 0, '$TEST_AID');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	printf '\n[playerbot-state-smoke] Armed state selftest for account %s.\n' "$TEST_AID"
	printf '[playerbot-state-smoke] Next step: log in with the codex OpenKore profile, then run this script with check.\n'
}

check() {
	tmux capture-pane -J -pt rathena-dev-map-server -S -220 \; save-buffer - 2>/dev/null | tail -n 220 | grep 'playerbot_state_selftest' || true
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`scope\`, \`action\`, \`result\`, \`detail\`
FROM \`bot_recovery_audit\`
WHERE \`scope\` = 'ownership'
ORDER BY \`id\` DESC
LIMIT 8;
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
