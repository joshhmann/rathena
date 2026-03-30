#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
TEST_AID="${TEST_AID:-2000004}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-item-smoke.sh [arm|run|check|check-denied]

Commands:
  arm    arm the hidden item selftest for the next test-account login, then restart the repo stack
  run    arm, launch the codex OpenKore harness in tmux, wait for item selftest
         output, then run check-denied
  check  show recent item selftest lines and latest item audit rows
  check-denied  require passing loadout denial/recovery plus refine/reform/
         enchantgrade denied-execution continuity signals
EOF
}

wait_for_item_result_line() {
	local timeout_s="${1:-210}" elapsed=0 pane
	while (( elapsed < timeout_s )); do
		pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -2200 2>/dev/null || true)"
		if printf '%s\n' "$pane" | grep -q 'playerbot_item_selftest: provision_ok='; then
			return 0
		fi
		sleep 1
		elapsed=$((elapsed + 1))
	done
	return 1
}

launch_kore() {
	tmux kill-session -t playerbot-item-kore 2>/dev/null || true
	tmux kill-session -t playerbot-foundation-kore 2>/dev/null || true
	tmux kill-session -t playerbot-combat-kore 2>/dev/null || true
	tmux kill-session -t playerbot-combat-skillunit-kore 2>/dev/null || true
	tmux kill-session -t playerbot-market-kore 2>/dev/null || true
	tmux kill-session -t playerbot-participation-kore 2>/dev/null || true
	tmux new-session -d -s playerbot-item-kore 'cd /root/testing/openkore && perl openkore.pl --control=/root/testing/openkore-control-codex'
	printf '[playerbot-item-smoke] Launched OpenKore in tmux session playerbot-item-kore.\n'
}

arm() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
REPLACE INTO \`mapreg\` (\`varname\`, \`index\`, \`value\`) VALUES
('\$PBITST_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBFNST_AUTORUN_AID', 0, '0'),
('\$PBCST_AUTORUN_AID', 0, '0'),
('\$PBGST_AUTORUN_AID', 0, '0'),
('\$PBMST_AUTORUN_AID', 0, '0'),
('\$PBPST_AUTORUN_AID', 0, '0'),
('\$PBSTAT_AUTORUN_AID', 0, '0');
EOF

	cd "$REPO_ROOT"
	bash tools/dev/playerbot-dev.sh restart
	printf '\n[playerbot-item-smoke] Armed item selftest for account %s.\n' "$TEST_AID"
	printf '[playerbot-item-smoke] Next step: log in with the codex OpenKore profile, then run this script with check.\n'
}

check() {
	wait_for_item_result_line 40 || true
	tmux capture-pane -J -pt rathena-dev-map-server -S -200 \; save-buffer - 2>/dev/null | tail -n 200 | grep 'playerbot_item_selftest' || true
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`action\`, \`item_id\`, \`amount\`, \`location\`, \`result\`, \`detail\`
FROM \`bot_item_audit\`
ORDER BY \`id\` DESC
LIMIT 12;
EOF
}

check_denied() {
	local pane line key failures=0 denied_rows=0 conflict_clear_rows=0
	wait_for_item_result_line 180 || true
	pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -3200 \; save-buffer - 2>/dev/null | tail -n 3200 || true)"
	printf '%s\n' "$pane" | grep 'playerbot_item_selftest:' | tail -n 2 || true
	line="$(printf '%s\n' "$pane" | grep 'playerbot_item_selftest: provision_ok=' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[playerbot-item-smoke] missing item selftest result line.\n' >&2
		return 1
	fi
	for key in result=1 refine_deny_ok=1 refine_deny_clear_ok=1 phracon_grant_ok=1 refine_exec_ok=1 refine_material_ok=1 refine_level_ok=1 refine_session_clear_ok=1 refine_audit_ok=1 refine_denied_audit_ok=1 reform_deny_ok=1 reform_deny_clear_ok=1 reform_exec_ok=1 reform_result_ok=1 reform_session_clear_ok=1 reform_audit_ok=1 reform_denied_audit_ok=1 enchant_deny_ok=1 enchant_deny_clear_ok=1 enchant_exec_ok=1 enchant_material_ok=1 enchant_zeny_ok=1 enchant_session_clear_ok=1 enchant_audit_ok=1 enchant_denied_audit_ok=1 loadout_denied_set_ok=1 loadout_denied_ok=1 loadout_recover_clear_ok=1 loadout_recover_ok=1 loadout_conflict_ok=1 loadout_conflict_cleared_ok=1 loadout_map_move_ok=1 loadout_map_cont_ok=1 loadout_map_return_ok=1 loadout_map_return_cont_ok=1 loadout_audit_ok=1; do
		if [[ "$line" != *"$key"* ]]; then
			printf '[playerbot-item-smoke] required signal missing: %s\n' "$key" >&2
			failures=$((failures + 1))
		fi
	done
	read -r denied_rows conflict_clear_rows refine_rows reform_rows enchant_rows refine_denied_rows reform_denied_rows enchant_denied_rows < <(
		mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT
  COALESCE(SUM(CASE WHEN \`detail\` LIKE 'loadout.manual.%.denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`detail\` = 'loadout.manual.slot_conflict.clear' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`action\` = 'refine' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`action\` = 'reform' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`action\` = 'enchantgrade' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`action\` = 'refine' AND \`result\` = 'denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`action\` = 'reform' AND \`result\` = 'denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`action\` = 'enchantgrade' AND \`result\` = 'denied' THEN 1 ELSE 0 END), 0)
FROM \`bot_item_audit\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= 1800;
EOF
	)
	if (( denied_rows < 1 )); then
		printf '[playerbot-item-smoke] missing denied item-audit detail row (loadout.manual.*.denied).\n' >&2
		failures=$((failures + 1))
	fi
	if (( conflict_clear_rows < 1 )); then
		printf '[playerbot-item-smoke] missing slot-conflict-clear item-audit detail row.\n' >&2
		failures=$((failures + 1))
	fi
	if (( refine_rows < 1 )); then
		printf '[playerbot-item-smoke] missing refine item-audit row.\n' >&2
		failures=$((failures + 1))
	fi
	if (( reform_rows < 1 )); then
		printf '[playerbot-item-smoke] missing reform item-audit row.\n' >&2
		failures=$((failures + 1))
	fi
	if (( enchant_rows < 1 )); then
		printf '[playerbot-item-smoke] missing enchantgrade item-audit row.\n' >&2
		failures=$((failures + 1))
	fi
	if (( refine_denied_rows < 1 )); then
		printf '[playerbot-item-smoke] missing denied refine item-audit row.\n' >&2
		failures=$((failures + 1))
	fi
	if (( reform_denied_rows < 1 )); then
		printf '[playerbot-item-smoke] missing denied reform item-audit row.\n' >&2
		failures=$((failures + 1))
	fi
	if (( enchant_denied_rows < 1 )); then
		printf '[playerbot-item-smoke] missing denied enchantgrade item-audit row.\n' >&2
		failures=$((failures + 1))
	fi
	local mapchange_loadout_audits=0
	mapchange_loadout_audits="$(
		mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT COUNT(*)
FROM \`bot_recovery_audit\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= 1800
  AND \`scope\` = 'loadout'
  AND \`action\` = 'reconcile'
  AND \`detail\` LIKE 'loadout.mapchange %';
EOF
	)"
	if (( mapchange_loadout_audits < 1 )); then
		printf '[playerbot-item-smoke] missing loadout.mapchange reconcile audit row.\n' >&2
		failures=$((failures + 1))
	fi

	printf '\n[playerbot-item-smoke] Recent loadout denial/recovery audit summary\n'
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -B <<EOF
SELECT \`action\`, \`detail\`, \`result\`, COUNT(*)
FROM \`bot_item_audit\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= 1800
  AND (
    \`detail\` = 'loadout.manual.missing'
    OR \`detail\` = 'loadout.manual.slot_conflict.clear'
    OR \`detail\` LIKE 'loadout.manual.%.denied'
  )
GROUP BY \`action\`, \`detail\`, \`result\`
ORDER BY MAX(\`id\`) DESC
LIMIT 12;
EOF
	printf '\n[playerbot-item-smoke] loadout.mapchange reconcile rows (last 30m): %s\n' "$mapchange_loadout_audits"
	printf '[playerbot-item-smoke] refine item-audit rows (last 30m): %s\n' "$refine_rows"
	printf '[playerbot-item-smoke] reform item-audit rows (last 30m): %s\n' "$reform_rows"
	printf '[playerbot-item-smoke] enchantgrade item-audit rows (last 30m): %s\n' "$enchant_rows"
	printf '[playerbot-item-smoke] denied refine item-audit rows (last 30m): %s\n' "$refine_denied_rows"
	printf '[playerbot-item-smoke] denied reform item-audit rows (last 30m): %s\n' "$reform_denied_rows"
	printf '[playerbot-item-smoke] denied enchantgrade item-audit rows (last 30m): %s\n' "$enchant_denied_rows"
	if (( failures > 0 )); then
		printf '\n[playerbot-item-smoke] loadout denial/recovery check failed with %d missing signal(s).\n' "$failures" >&2
		return 1
	fi
	printf '\n[playerbot-item-smoke] loadout denial/recovery check passed.\n'
}

run() {
	arm
	launch_kore
	if ! wait_for_item_result_line 300; then
		printf '[playerbot-item-smoke] item selftest line not observed within timeout.\n' >&2
		tmux capture-pane -J -pt rathena-dev-map-server -S -220 | tail -n 80 >&2 || true
		return 1
	fi
	check_denied
}

main() {
	case "${1:-arm}" in
		arm) arm ;;
		run) run ;;
		check) check ;;
		check-denied) check_denied ;;
		-h|--help|help) usage ;;
		*)
			usage
			exit 1
			;;
	esac
}

main "$@"
