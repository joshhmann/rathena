#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-combat-transition-stress"

RUNS=5
STRICT_DRIFT=0

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-combat-transition-stress.sh [options]

Options:
  --runs N         Number of aggregate foundation cycles to execute (default: 5)
  --strict-drift   Fail if per-run trace/audit deltas drift > 50% from run 1
  -h, --help       Show this help

Notes:
  - This script validates repeated combat/status/death/respawn transition stability.
  - It executes `playerbot-foundation-smoke.sh run` in a loop and checks:
    - combat continuity signal
    - item mechanic re-execution signal
    - market partial/reopen commit signal
  - It also reports per-run recovery/trace delta counts for drift inspection.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--runs)
			RUNS="${2:?missing value for --runs}"
			shift 2
			;;
		--strict-drift)
			STRICT_DRIFT=1
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			usage
			exit 1
			;;
	esac
done

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || (( RUNS < 1 )); then
	echo "--runs must be a positive integer" >&2
	exit 1
fi

cd "$REPO_ROOT"

declare -a trace_deltas=()
declare -a audit_deltas=()
failures=0

check_output_signals() {
	local output="$1"
	local combat_line item_line mech_line market_line

	combat_line="$(printf '%s\n' "$output" | grep 'playerbot_combat_selftest:' | tail -n 1 || true)"
	item_line="$(printf '%s\n' "$output" | grep 'playerbot_item_selftest:' | tail -n 1 || true)"
	mech_line="$(printf '%s\n' "$output" | grep 'playerbot_item_selftest_mech_reexec:' | tail -n 1 || true)"
	market_line="$(printf '%s\n' "$output" | grep 'playerbot_merchant_selftest: bot_id=' | tail -n 1 || true)"

	if [[ -z "$combat_line" || "$combat_line" != *"continuity_loop_ok=1"* || "$combat_line" != *"continuity_loop_count=3"* || "$combat_line" != *"npc_interrupt_clear_ok=1"* || "$combat_line" != *"storage_interrupt_clear_ok=1"* || "$combat_line" != *"trade_interrupt_clear_ok=1"* || "$combat_line" != *"trace_ok=1"* || "$combat_line" != *"audit_ok=1"* || "$combat_line" != *"result=1"* ]]; then
		printf '[%s] missing/failed combat continuity signal.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	if [[ -z "$item_line" || "$item_line" != *"loadout_continuity_ok=1"* || "$item_line" != *"result=1"* ]]; then
		printf '[%s] missing/failed item mechanic re-execution signal.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	if [[ -z "$mech_line" || "$mech_line" != *"refine_reexec_ok=1"* || "$mech_line" != *"reform_reexec_ok=1"* || "$mech_line" != *"enchant_reexec_ok=1"* ]]; then
		printf '[%s] missing/failed item mech re-exec detail signal.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	if [[ -z "$market_line" || "$market_line" != *"buying_commit_total_ok=1"* || "$market_line" != *"result=1"* ]]; then
		printf '[%s] missing/failed market commit signal.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	return 0
}

for i in $(seq 1 "$RUNS"); do
	printf '[%s] run %d/%d\n' "$PB_SMOKE_LABEL" "$i" "$RUNS"

	trace_before="$(pb_smoke_sql "SELECT COALESCE(MAX(\`id\`),0) FROM \`bot_trace_event\`;")"
	audit_before="$(pb_smoke_sql "SELECT COALESCE(MAX(\`id\`),0) FROM \`bot_recovery_audit\`;")"

	if ! output="$(bash tools/ci/playerbot-foundation-smoke.sh run 2>&1)"; then
		printf '%s\n' "$output" >&2
		printf '[%s] aggregate run failed on iteration %d.\n' "$PB_SMOKE_LABEL" "$i" >&2
		failures=$((failures + 1))
		continue
	fi

	if ! check_output_signals "$output"; then
		failures=$((failures + 1))
		continue
	fi

	trace_delta="$(pb_smoke_sql "
		SELECT COUNT(*)
		FROM \`bot_trace_event\`
		WHERE \`id\` > ${trace_before}
		  AND \`phase\` IN ('combat','interaction','reconcile');")"
	audit_delta="$(pb_smoke_sql "
		SELECT COUNT(*)
		FROM \`bot_recovery_audit\`
		WHERE \`id\` > ${audit_before}
		  AND \`scope\` IN ('combat','loadout','npc','storage','trade','skillunit','participation');")"
	read -r npc_interrupt_count storage_interrupt_count trade_interrupt_count skillunit_interrupt_count < <(
		pb_smoke_sql_heredoc <<EOF
SELECT
  COALESCE(SUM(CASE WHEN \`scope\` = 'npc' AND \`action\` = 'interrupt' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`scope\` = 'storage' AND \`action\` = 'interrupt' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`scope\` = 'trade' AND \`action\` = 'interrupt' THEN 1 ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN \`scope\` = 'skillunit' AND \`action\` = 'interrupt' THEN 1 ELSE 0 END), 0)
FROM \`bot_recovery_audit\`
WHERE \`id\` > ${audit_before};
EOF
	)
	if (( npc_interrupt_count < 1 || storage_interrupt_count < 1 || trade_interrupt_count < 1 || skillunit_interrupt_count < 1 )); then
		printf '[%s] missing interrupt audit evidence at run %d (npc=%s storage=%s trade=%s skillunit=%s).\n' \
			"$PB_SMOKE_LABEL" "$i" "$npc_interrupt_count" "$storage_interrupt_count" "$trade_interrupt_count" "$skillunit_interrupt_count" >&2
		failures=$((failures + 1))
		continue
	fi

	trace_deltas+=("$trace_delta")
	audit_deltas+=("$audit_delta")
	printf '[%s] run %d deltas: trace=%s audit=%s interrupts(npc/storage/trade/skillunit)=%s/%s/%s/%s\n' \
		"$PB_SMOKE_LABEL" "$i" "$trace_delta" "$audit_delta" \
		"$npc_interrupt_count" "$storage_interrupt_count" "$trade_interrupt_count" "$skillunit_interrupt_count"
done

if (( failures > 0 )); then
	printf '[%s] failed with %d run-level error(s).\n' "$PB_SMOKE_LABEL" "$failures" >&2
	exit 1
fi

baseline_trace="${trace_deltas[0]}"
baseline_audit="${audit_deltas[0]}"

for idx in "${!trace_deltas[@]}"; do
	t="${trace_deltas[$idx]}"
	a="${audit_deltas[$idx]}"
	if (( t < 1 || a < 1 )); then
		printf '[%s] non-positive delta at run %d (trace=%s audit=%s).\n' "$PB_SMOKE_LABEL" "$((idx + 1))" "$t" "$a" >&2
		exit 1
	fi
	if (( STRICT_DRIFT > 0 )); then
		trace_low=$(( baseline_trace / 2 ))
		trace_high=$(( baseline_trace + (baseline_trace / 2) + 1 ))
		audit_low=$(( baseline_audit / 2 ))
		audit_high=$(( baseline_audit + (baseline_audit / 2) + 1 ))
		if (( t < trace_low || t > trace_high || a < audit_low || a > audit_high )); then
			printf '[%s] strict drift failure at run %d (trace=%s audit=%s baseline_trace=%s baseline_audit=%s).\n' \
				"$PB_SMOKE_LABEL" "$((idx + 1))" "$t" "$a" "$baseline_trace" "$baseline_audit" >&2
			exit 1
		fi
	fi
done

printf '[%s] pass: %d repeated transition runs completed.\n' "$PB_SMOKE_LABEL" "$RUNS"
