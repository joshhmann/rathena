#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-item-smoke"

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

arm() {
	pb_smoke_arm_and_restart "$PB_SMOKE_LABEL" \
		"('\$PBITST_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBFNST_AUTORUN_AID', 0, '0'),
('\$PBCST_AUTORUN_AID', 0, '0'),
('\$PBGST_AUTORUN_AID', 0, '0'),
('\$PBMST_AUTORUN_AID', 0, '0'),
('\$PBPST_AUTORUN_AID', 0, '0'),
('\$PBSTAT_AUTORUN_AID', 0, '0')"
}

launch_kore() {
	pb_smoke_kill_kore playerbot-item-kore playerbot-foundation-kore \
		playerbot-combat-kore playerbot-combat-skillunit-kore \
		playerbot-market-kore playerbot-participation-kore
	pb_smoke_launch_kore playerbot-item-kore
}

check() {
	pb_smoke_wait_pattern 'playerbot_item_selftest: provision_ok=' 40 2200 || true
	pb_smoke_capture 200 | grep 'playerbot_item_selftest' || true
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `item_id`, `amount`, `location`, `result`, `detail`
FROM `bot_item_audit`
ORDER BY `id` DESC
LIMIT 12;
EOF
}

check_denied() {
	local pane line mech_line consume_line failures=0
	pb_smoke_wait_pattern 'playerbot_item_selftest: provision_ok=' 180 2200 || true
	pane="$(pb_smoke_capture 3200)"
	printf '%s\n' "$pane" | grep 'playerbot_item_selftest:' | tail -n 2 || true
	printf '%s\n' "$pane" | grep 'playerbot_item_selftest_mech_reexec:' | tail -n 1 || true
	printf '%s\n' "$pane" | grep 'playerbot_item_selftest_consume:' | tail -n 1 || true
	line="$(printf '%s\n' "$pane" | grep 'playerbot_item_selftest: provision_ok=' | tail -n 1 || true)"
	if [[ -z "$line" ]]; then
		printf '[%s] missing item selftest result line.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	mech_line="$(printf '%s\n' "$pane" | grep 'playerbot_item_selftest_mech_reexec:' | tail -n 1 || true)"
	if [[ -z "$mech_line" ]]; then
		printf '[%s] missing item mech reexec line.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	consume_line="$(printf '%s\n' "$pane" | grep 'playerbot_item_selftest_consume:' | tail -n 1 || true)"
	if [[ -z "$consume_line" ]]; then
		printf '[%s] missing item consume line.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	local signal_failures=0
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$line" \
		card_sword_grant_ok=1 card_deny_grant_ok=1 card_exec_grant_ok=1 \
		card_deny_ok=1 card_exec_ok=1 card_result_ok=1 \
		result=1 refine_deny_ok=1 refine_deny_clear_ok=1 phracon_grant_ok=1 \
		refine_exec_ok=1 refine_material_ok=1 refine_level_ok=1 \
		refine_session_clear_ok=1 reform_deny_ok=1 reform_deny_clear_ok=1 \
		reform_exec_ok=1 reform_result_ok=1 reform_session_clear_ok=1 \
		enchant_deny_ok=1 enchant_deny_clear_ok=1 enchant_exec_ok=1 \
		enchant_material_ok=1 enchant_zeny_ok=1 enchant_session_clear_ok=1 \
		mechanic_rollback_ok=1 refine_audit_ok=1 refine_denied_audit_ok=1 \
		mech_refine_regrant_ok=1 mech_refine_reexec_ok=1 \
		mech_refine_reexec_clear_ok=1 \
		reform_audit_ok=1 reform_denied_audit_ok=1 enchant_audit_ok=1 \
		enchant_denied_audit_ok=1 loadout_denied_set_ok=1 loadout_denied_ok=1 \
		loadout_recover_clear_ok=1 loadout_recover_ok=1 loadout_conflict_ok=1 \
		loadout_conflict_cleared_ok=1 loadout_map_move_ok=1 \
		loadout_map_cont_ok=1 loadout_map_return_ok=1 \
		loadout_map_return_cont_ok=1 loadout_continuity_ok=1 \
		loadout_cycle_count=3 \
		loadout_audit_ok=1 || signal_failures=$?
	failures=$((failures + signal_failures))
	signal_failures=0
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$mech_line" \
		reform_regrant_ok=1 reform_reexec_ok=1 reform_reexec_clear_ok=1 \
		enchant_regrant_ok=1 enchant_reexec_ok=1 enchant_reexec_clear_ok=1 || signal_failures=$?
	failures=$((failures + signal_failures))

	signal_failures=0
	pb_smoke_check_signals "$PB_SMOKE_LABEL" "$consume_line" \
		missing_ok=1 missing_audit_ok=1 || signal_failures=$?
	failures=$((failures + signal_failures))

	local denied_rows=0 conflict_clear_rows=0 refine_rows=0 reform_rows=0 enchant_rows=0
	local refine_denied_rows=0 reform_denied_rows=0 enchant_denied_rows=0
	read -r denied_rows conflict_clear_rows refine_rows reform_rows enchant_rows \
		refine_denied_rows reform_denied_rows enchant_denied_rows < <(
		pb_smoke_sql_heredoc <<'EOF'
SELECT
  COALESCE(SUM(CASE WHEN `detail` LIKE 'loadout.manual.%.denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `detail` = 'loadout.manual.slot_conflict.clear' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `action` = 'refine' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `action` = 'reform' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `action` = 'enchantgrade' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `action` = 'refine' AND `result` = 'denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `action` = 'reform' AND `result` = 'denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `action` = 'enchantgrade' AND `result` = 'denied' THEN 1 ELSE 0 END), 0)
FROM `bot_item_audit`
WHERE UNIX_TIMESTAMP() - `ts` <= 1800;
EOF
	)

	local consume_open_trace_rows=0 consume_open_audit_rows=0 consume_interrupt_rows=0
	local card_exec_trace_rows=0 card_denied_trace_rows=0
	local refine_exec_trace_rows=0 refine_denied_trace_rows=0
	local reform_success_trace_rows=0 reform_denied_trace_rows=0
	local enchant_exec_trace_rows=0 enchant_denied_trace_rows=0
	read -r consume_open_trace_rows consume_open_audit_rows consume_interrupt_rows \
		card_exec_trace_rows card_denied_trace_rows refine_exec_trace_rows refine_denied_trace_rows \
		reform_success_trace_rows reform_denied_trace_rows \
		enchant_exec_trace_rows enchant_denied_trace_rows < <(
		pb_smoke_sql_heredoc <<'EOF'
SELECT
  COALESCE(SUM(CASE WHEN `target_type` = 'item_use' AND `target_id` = '611' AND `error_detail` LIKE 'session.opened%' THEN 1 ELSE 0 END), 0),
  COALESCE((SELECT COUNT(*)
            FROM `bot_item_audit`
            WHERE UNIX_TIMESTAMP() - `ts` <= 1800
              AND `action` = 'consume'
              AND `item_id` = '611'
              AND `result` = 'ok'
              AND `detail` LIKE 'session.opened%'), 0),
  COALESCE((SELECT COUNT(*)
            FROM `bot_recovery_audit`
            WHERE UNIX_TIMESTAMP() - `ts` <= 1800
              AND `scope` IN ('session.skillitem','session.itemctx')
              AND `action` = 'interrupt'
              AND `result` = 'ok'
              AND (`detail` LIKE 'combat.death.interrupt%' OR `detail` LIKE 'mapchange.session%')), 0),
  COALESCE(SUM(CASE WHEN `target_type` = 'cardinsert' AND `error_code` = 'cardinsert.outcome' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `target_type` = 'cardinsert' AND `error_code` = 'cardinsert.execute' AND `result` = 'denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `target_type` = 'refine' AND `error_code` = 'refine.outcome' AND `error_detail` LIKE 'refine.%' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `target_type` = 'refine' AND `error_code` = 'refine.execute' AND `result` = 'denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `target_type` = 'reform' AND `error_code` = 'reform.outcome' AND `result` = 'ok' AND `error_detail` LIKE 'reform.success%' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `target_type` = 'reform' AND `error_code` = 'reform.execute' AND `result` = 'denied' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `target_type` = 'enchantgrade' AND `error_code` = 'enchantgrade.outcome' AND `error_detail` LIKE 'enchantgrade.%' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN `target_type` = 'enchantgrade' AND `error_code` = 'enchantgrade.execute' AND `result` = 'denied' THEN 1 ELSE 0 END), 0)
FROM `bot_trace_event`
WHERE UNIX_TIMESTAMP() - `ts` <= 1800
  AND `phase` = 'interaction';
EOF
	)

	pb_smoke_require_rows "$PB_SMOKE_LABEL" "denied item-audit detail row (loadout.manual.*.denied)" "$denied_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "slot-conflict-clear item-audit detail row" "$conflict_clear_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "refine item-audit row" "$refine_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "reform item-audit row" "$reform_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "enchantgrade item-audit row" "$enchant_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "denied refine item-audit row" "$refine_denied_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "denied reform item-audit row" "$reform_denied_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "denied enchantgrade item-audit row" "$enchant_denied_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "delayed item-use session-open trace row" "$consume_open_trace_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "delayed item-use session-open audit row" "$consume_open_audit_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "delayed item-use interrupt audit row" "$consume_interrupt_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "cardinsert execution outcome trace row" "$card_exec_trace_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "denied cardinsert trace row" "$card_denied_trace_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "refine execution outcome trace row" "$refine_exec_trace_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "denied refine trace row" "$refine_denied_trace_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "reform success trace row" "$reform_success_trace_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "denied reform trace row" "$reform_denied_trace_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "enchantgrade execution outcome trace row" "$enchant_exec_trace_rows" || failures=$((failures + 1))
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "denied enchantgrade trace row" "$enchant_denied_trace_rows" || failures=$((failures + 1))

	local mapchange_loadout_audits=0
	mapchange_loadout_audits="$(pb_smoke_sql "
		SELECT COUNT(*)
		FROM \`bot_recovery_audit\`
		WHERE UNIX_TIMESTAMP() - \`ts\` <= 1800
		  AND \`scope\` = 'loadout'
		  AND \`action\` = 'reconcile'
		  AND \`detail\` LIKE 'loadout.mapchange %';"
	)"
	pb_smoke_require_rows "$PB_SMOKE_LABEL" "loadout.mapchange reconcile audit row" "$mapchange_loadout_audits" || failures=$((failures + 1))

	printf '\n[%s] Recent loadout denial/recovery audit summary\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `detail`, `result`, COUNT(*)
FROM `bot_item_audit`
WHERE UNIX_TIMESTAMP() - `ts` <= 1800
  AND (
    `detail` = 'loadout.manual.missing'
    OR `detail` = 'loadout.manual.slot_conflict.clear'
    OR `detail` LIKE 'loadout.manual.%.denied'
  )
GROUP BY `action`, `detail`, `result`
ORDER BY MAX(`id`) DESC
LIMIT 12;
EOF
	printf '\n[%s] loadout.mapchange reconcile rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$mapchange_loadout_audits"
	printf '[%s] refine item-audit rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$refine_rows"
	printf '[%s] reform item-audit rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$reform_rows"
	printf '[%s] enchantgrade item-audit rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$enchant_rows"
	printf '[%s] denied refine item-audit rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$refine_denied_rows"
	printf '[%s] denied reform item-audit rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$reform_denied_rows"
	printf '[%s] denied enchantgrade item-audit rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$enchant_denied_rows"
	printf '[%s] delayed item-use session-open trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$consume_open_trace_rows"
	printf '[%s] delayed item-use session-open audit rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$consume_open_audit_rows"
	printf '[%s] delayed item-use interrupt audit rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$consume_interrupt_rows"
	printf '[%s] cardinsert execution outcome trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$card_exec_trace_rows"
	printf '[%s] denied cardinsert trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$card_denied_trace_rows"
	printf '[%s] refine execution outcome trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$refine_exec_trace_rows"
	printf '[%s] denied refine trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$refine_denied_trace_rows"
	printf '[%s] reform success trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$reform_success_trace_rows"
	printf '[%s] denied reform trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$reform_denied_trace_rows"
	printf '[%s] enchantgrade execution outcome trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$enchant_exec_trace_rows"
	printf '[%s] denied enchantgrade trace rows (last 30m): %s\n' "$PB_SMOKE_LABEL" "$enchant_denied_trace_rows"
	if (( failures > 0 )); then
		printf '\n[%s] loadout denial/recovery check failed with %d missing signal(s).\n' "$PB_SMOKE_LABEL" "$failures" >&2
		return 1
	fi
	printf '\n[%s] loadout denial/recovery check passed.\n' "$PB_SMOKE_LABEL"
}

run() {
	arm
	launch_kore
	if ! pb_smoke_wait_pattern 'playerbot_item_selftest: provision_ok=' 300 2200; then
		printf '[%s] item selftest line not observed within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 80 >&2
		return 1
	fi
	check_denied
}

pb_smoke_main "$@"
