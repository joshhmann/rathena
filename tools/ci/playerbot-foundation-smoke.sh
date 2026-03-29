#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-foundation-smoke.sh [arm|run|check]

Commands:
  arm    arm the sequenced foundation selftest for the next test-account login,
         then restart the repo stack
  run    arm the selftest, launch the codex OpenKore harness in tmux, wait for
         the sequenced pass to finish, then run check
  check  print recent foundation stage lines plus selftest results and a compact
         foundation audit summary

Workflow:
  1. bash tools/ci/playerbot-foundation-smoke.sh arm
  2. log in once with the codex OpenKore profile
  3. bash tools/ci/playerbot-foundation-smoke.sh check
EOF
}

wait_for_stage_done() {
	local timeout_s="${1:-150}" elapsed=0 pane
	while (( elapsed < timeout_s )); do
		pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -200 2>/dev/null || true)"
		if printf '%s\n' "$pane" | grep -q 'playerbot_foundation_selftest: stage=done'; then
			return 0
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 1
}

wait_for_selftest_line() {
	local pattern="${1:?pattern required}" timeout_s="${2:-60}" elapsed=0 pane
	while (( elapsed < timeout_s )); do
		pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -800 2>/dev/null || true)"
		if printf '%s\n' "$pane" | grep -q "$pattern"; then
			return 0
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 1
}

wait_for_all_selftests() {
	local timeout_s="${1:-120}" elapsed=0 pane
	while (( elapsed < timeout_s )); do
		pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -2400 2>/dev/null || true)"
		if printf '%s\n' "$pane" | grep -q 'playerbot_state_selftest:' \
			&& printf '%s\n' "$pane" | grep -q 'playerbot_guild_selftest:' \
			&& printf '%s\n' "$pane" | grep -q 'playerbot_item_selftest:' \
			&& printf '%s\n' "$pane" | grep -q 'playerbot_merchant_selftest:' \
			&& printf '%s\n' "$pane" | grep -q 'playerbot_participation_selftest:' \
			&& printf '%s\n' "$pane" | grep -q 'playerbot_combat_selftest:'; then
			return 0
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 1
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`) VALUES
('\$PBFNST_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBFNST_ACTIVE', 0, '0'),
('\$PBCST_AUTORUN_AID', 0, '0'),
('\$PBGST_AUTORUN_AID', 0, '0'),
('\$PBITST_AUTORUN_AID', 0, '0'),
('\$PBMST_AUTORUN_AID', 0, '0'),
('\$PBPST_AUTORUN_AID', 0, '0'),
('\$PBSTAT_AUTORUN_AID', 0, '0'),
('\$PBCST_MANUAL_AID', 0, '0'),
('\$PBFNST_MANUAL_AID', 0, '0'),
('\$PBGST_MANUAL_AID', 0, '0'),
('\$PBITST_MANUAL_AID', 0, '0'),
('\$PBMST_MANUAL_AID', 0, '0'),
('\$PBPST_MANUAL_AID', 0, '0'),
('\$PBSTAT_MANUAL_AID', 0, '0');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	for _ in $(seq 1 20); do
		if tmux capture-pane -J -pt rathena-dev-map-server -S -80 2>/dev/null | grep -q "Map Server is now online."; then
			break
		fi
		sleep 1
	done
	printf '\n[playerbot-foundation-smoke] Armed foundation selftests for account %s.\n' "$TEST_AID"
	printf '[playerbot-foundation-smoke] Next step: log in once with the codex OpenKore profile, then run this script with check.\n'
}

run() {
	arm
	tmux kill-session -t playerbot-foundation-kore 2>/dev/null || true
	tmux new-session -d -s playerbot-foundation-kore 'cd /root/testing/openkore && perl openkore.pl --control=/root/testing/openkore-control-codex'
	printf '[playerbot-foundation-smoke] Launched OpenKore in tmux session playerbot-foundation-kore.\n'
	if ! wait_for_stage_done 150; then
		printf '[playerbot-foundation-smoke] foundation pass did not reach stage=done within timeout.\n' >&2
		tmux capture-pane -J -pt rathena-dev-map-server -S -220 | tail -n 80 >&2 || true
		return 1
	fi
	wait_for_all_selftests 180 || true
	check
}

check() {
	declare -A patterns=(
		[guild]='playerbot_guild_selftest:'
		[item]='playerbot_item_selftest:'
		[merchant]='playerbot_merchant_selftest:'
		[participation]='playerbot_participation_selftest:'
		[state]='playerbot_state_selftest:'
		[combat]='playerbot_combat_selftest:'
	)
	local pane lines line key failures=0
	wait_for_all_selftests 120 || true
	pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -2400 \; save-buffer - 2>/dev/null | tail -n 2400 || true)"
	printf '%s\n' "$pane" | grep 'playerbot_foundation_selftest:' | tail -n 12 || true
	printf '\n'
	lines="$(printf '%s\n' "$pane" | grep -E 'playerbot_(guild|item|merchant|participation|state|combat)_selftest' || true)"
	printf '%s\n' "$lines"
	for key in guild item merchant participation state combat; do
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
  AND \`scope\` IN ('combat','loadout','npc','storage','trade','participation','reservation','ownership')
GROUP BY \`scope\`, \`action\`, \`result\`, \`detail\`
ORDER BY MAX(\`id\`) DESC
LIMIT 16;
EOF
	printf '\n[playerbot-foundation-smoke] Recent structured trace summary\n'
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`action\`, \`target_type\`, \`reason_code\`, \`result\`, COUNT(*)
FROM \`bot_trace_event\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= 1800
  AND \`phase\` IN ('interaction','reservation','reconcile','combat')
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
