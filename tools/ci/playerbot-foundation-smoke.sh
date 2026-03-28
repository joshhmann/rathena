#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-foundation-smoke.sh [arm|check]

Commands:
  arm    arm the sequenced foundation selftest for the next test-account login,
         then restart the repo stack
  check  print recent foundation stage lines plus selftest results and a compact
         foundation audit summary

Workflow:
  1. bash tools/ci/playerbot-foundation-smoke.sh arm
  2. log in once with the codex OpenKore profile
  3. bash tools/ci/playerbot-foundation-smoke.sh check
EOF
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`) VALUES
('\$PBFNST_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBGST_AUTORUN_AID', 0, '0'),
('\$PBITST_AUTORUN_AID', 0, '0'),
('\$PBMST_AUTORUN_AID', 0, '0'),
('\$PBPST_AUTORUN_AID', 0, '0'),
('\$PBSTAT_AUTORUN_AID', 0, '0'),
('\$PBFNST_MANUAL_AID', 0, '0'),
('\$PBGST_MANUAL_AID', 0, '0'),
('\$PBITST_MANUAL_AID', 0, '0'),
('\$PBMST_MANUAL_AID', 0, '0'),
('\$PBPST_MANUAL_AID', 0, '0'),
('\$PBSTAT_MANUAL_AID', 0, '0');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	printf '\n[playerbot-foundation-smoke] Armed foundation selftests for account %s.\n' "$TEST_AID"
	printf '[playerbot-foundation-smoke] Next step: log in once with the codex OpenKore profile, then run this script with check.\n'
}

check() {
	declare -A patterns=(
		[guild]='playerbot_guild_selftest:'
		[item]='playerbot_item_selftest:'
		[merchant]='playerbot_merchant_selftest:'
		[participation]='playerbot_participation_selftest:'
		[state]='playerbot_state_selftest:'
	)
	local pane lines line key failures=0
	pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -600 \; save-buffer - 2>/dev/null | tail -n 600 || true)"
	printf '%s\n' "$pane" | grep 'playerbot_foundation_selftest:' | tail -n 12 || true
	printf '\n'
	lines="$(printf '%s\n' "$pane" | grep -E 'playerbot_(guild|item|merchant|participation|state)_selftest' || true)"
	printf '%s\n' "$lines"
	for key in guild item merchant participation state; do
		line="$(printf '%s\n' "$lines" | grep "${patterns[$key]}" | tail -n 1 || true)"
		if [[ -z "$line" ]]; then
			printf '[playerbot-foundation-smoke] missing %s selftest line\n' "$key" >&2
			failures=$((failures + 1))
			continue
		fi
		if [[ "$line" != *"result=1"* ]]; then
			printf '[playerbot-foundation-smoke] %s selftest did not pass: %s\n' "$key" "$line" >&2
			failures=$((failures + 1))
		fi
	done
	printf '\n[playerbot-foundation-smoke] Recent recovery audit summary\n'
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`scope\`, \`action\`, \`result\`, \`detail\`, COUNT(*)
FROM \`bot_recovery_audit\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= 1800
  AND \`scope\` IN ('npc','storage','trade','participation','reservation','ownership')
GROUP BY \`scope\`, \`action\`, \`result\`, \`detail\`
ORDER BY MAX(\`id\`) DESC
LIMIT 16;
EOF
	printf '\n[playerbot-foundation-smoke] Recent structured trace summary\n'
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`action\`, \`target_type\`, \`reason_code\`, \`result\`, COUNT(*)
FROM \`bot_trace_event\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= 1800
  AND \`phase\` IN ('interaction','reservation','reconcile')
GROUP BY \`action\`, \`target_type\`, \`reason_code\`, \`result\`
ORDER BY MAX(\`id\`) DESC
LIMIT 20;
EOF
	if (( failures > 0 )); then
		printf '\n[playerbot-foundation-smoke] foundation pass failed with %d missing/failing selftest(s).\n' "$failures" >&2
		return 1
	fi
	printf '\n[playerbot-foundation-smoke] foundation pass ok.\n'
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
