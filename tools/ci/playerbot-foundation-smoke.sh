#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-foundation-smoke"
PB_STREAM_MAP="${PB_STREAM_MAP:-0}"
PB_MAP_STREAM_PID=""

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-foundation-smoke.sh [arm|run|run-rich|check|check-rich]

Commands:
  arm    arm the sequenced foundation selftest for the next test-account login,
         then restart the repo stack
  run    arm the selftest, launch the codex OpenKore harness in tmux, wait for
         the sequenced pass to finish, then run check
  run-rich  run the normal foundation gate, then run a separate skillunit probe
         gate and a separate skillunit precheck gate (each in separate
         restart/login cycles) and require all to pass
  check  print recent foundation stage lines plus selftest results and a compact
         foundation audit summary
  check-rich  require a passing skillunit probe line and print its trace/audit
         summary

Workflow:
  1. bash tools/ci/playerbot-foundation-smoke.sh arm
  2. log in once with the codex OpenKore profile
  3. bash tools/ci/playerbot-foundation-smoke.sh check
EOF
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

start_map_stream() {
	if (( PB_STREAM_MAP == 0 )); then
		return 1
	fi
	if [[ -n "$PB_MAP_STREAM_PID" ]] && kill -0 "$PB_MAP_STREAM_PID" 2>/dev/null; then
		return 0
	fi
	(
		local last_sig=""
		printf '[%s] map-stream: enabled (poll=2s, pane=rathena-dev-map-server)\n' "$PB_SMOKE_LABEL"
		while true; do
			local pane sig
			pane="$(tmux capture-pane -J -pt rathena-dev-map-server -S -120 2>/dev/null || true)"
			sig="$(printf '%s' "$pane" | cksum | awk '{print $1 ":" $2}')"
			if [[ -n "$pane" && "$sig" != "$last_sig" ]]; then
				printf '[%s] map-stream snapshot >>>\n' "$PB_SMOKE_LABEL"
				printf '%s\n' "$pane"
				printf '[%s] map-stream snapshot <<<\n' "$PB_SMOKE_LABEL"
				last_sig="$sig"
			fi
			sleep 2
		done
	) &
	PB_MAP_STREAM_PID="$!"
	return 0
}

stop_map_stream() {
	if [[ -n "$PB_MAP_STREAM_PID" ]]; then
		kill "$PB_MAP_STREAM_PID" 2>/dev/null || true
		wait "$PB_MAP_STREAM_PID" 2>/dev/null || true
		PB_MAP_STREAM_PID=""
	fi
}

arm() {
	pb_smoke_arm_restart_wait "$PB_SMOKE_LABEL" \
		"('\$PBFNST_AUTORUN_AID', 0, '$TEST_AID'),
('\$PBFNST_ACTIVE', 0, '0'),
('\$PBCST_AUTORUN_AID', 0, '0'),
('\$PBCEDGE_AUTORUN_AID', 0, '0'),
('\$PBGST_AUTORUN_AID', 0, '0'),
('\$PBITST_AUTORUN_AID', 0, '0'),
('\$PBMST_AUTORUN_AID', 0, '0'),
('\$PBPST_AUTORUN_AID', 0, '0'),
('\$PBLGST_AUTORUN_AID', 0, '0'),
('\$PBLSF_AUTORUN_AID', 0, '0'),
('\$PBSTAT_AUTORUN_AID', 0, '0'),
('\$PBCST_MANUAL_AID', 0, '0'),
('\$PBFNST_MANUAL_AID', 0, '0'),
('\$PBGST_MANUAL_AID', 0, '0'),
('\$PBITST_MANUAL_AID', 0, '0'),
('\$PBMST_MANUAL_AID', 0, '0'),
('\$PBPST_MANUAL_AID', 0, '0'),
('\$PBSTAT_MANUAL_AID', 0, '0')"
}

run() {
	local stream_started=0
	arm
	pb_smoke_launch_kore playerbot-foundation-kore
	if start_map_stream; then
		stream_started=1
	fi
	if ! pb_smoke_wait_pattern 'playerbot_foundation_selftest: stage=done' 300; then
		(( stream_started > 0 )) && stop_map_stream
		printf '[%s] foundation pass did not reach stage=done within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 80 >&2
		return 1
	fi
	pb_smoke_wait_pattern 'playerbot_combat_selftest:' 60 || true
	wait_for_all_selftests 180 || true
	(( stream_started > 0 )) && stop_map_stream
	check
}

check_rich() {
	local failed=0
	pb_smoke_wait_pattern 'playerbot_combat_skillunit_probe:' 90 || true
	if ! bash tools/ci/playerbot-combat-skillunit-smoke.sh check; then
		failed=1
	fi
	pb_smoke_wait_pattern 'playerbot_combat_skillunit_precheck:' 90 || true
	if ! bash tools/ci/playerbot-combat-skillunit-precheck-smoke.sh check; then
		failed=1
	fi
	if (( failed > 0 )); then
		printf '\n[%s] rich gate failed.\n' "$PB_SMOKE_LABEL" >&2
		return 1
	fi
	printf '\n[%s] rich gate pass ok.\n' "$PB_SMOKE_LABEL"
}

run_rich() {
	local stream_started=0
	run
	bash tools/ci/playerbot-combat-skillunit-smoke.sh arm
	pb_smoke_launch_kore playerbot-foundation-kore
	if start_map_stream; then
		stream_started=1
	fi
	if ! pb_smoke_wait_pattern 'playerbot_combat_skillunit_probe:' 180; then
		(( stream_started > 0 )) && stop_map_stream
		printf '[%s] rich gate did not observe skillunit probe within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 80 >&2
		return 1
	fi
	(( stream_started > 0 )) && stop_map_stream
	if ! bash tools/ci/playerbot-combat-skillunit-smoke.sh check; then
		return 1
	fi
	bash tools/ci/playerbot-combat-skillunit-precheck-smoke.sh arm
	pb_smoke_launch_kore playerbot-foundation-kore
	if start_map_stream; then
		stream_started=1
	fi
	if ! pb_smoke_wait_pattern 'playerbot_combat_skillunit_precheck:' 180; then
		(( stream_started > 0 )) && stop_map_stream
		printf '[%s] rich gate did not observe skillunit precheck within timeout.\n' "$PB_SMOKE_LABEL" >&2
		pb_smoke_capture 80 >&2
		return 1
	fi
	(( stream_started > 0 )) && stop_map_stream
	check_rich
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
	pb_smoke_wait_pattern 'playerbot_foundation_selftest: stage=done' 30 || true
	pb_smoke_wait_pattern 'playerbot_combat_selftest:' 60 || true
	wait_for_all_selftests 120 || true
	pane="$(pb_smoke_capture 2400)"
	printf '%s\n' "$pane" | grep 'playerbot_foundation_selftest:' | tail -n 12 || true
	printf '\n'
	lines="$(printf '%s\n' "$pane" | grep -E 'playerbot_(guild|item|merchant|participation|state|combat)_selftest' || true)"
	printf '%s\n' "$lines"
	for key in guild item merchant participation state combat; do
		line="$(printf '%s\n' "$lines" | grep "${patterns[$key]}" | tail -n 1 || true)"
		if [[ -z "$line" ]]; then
			printf '[%s] missing %s selftest line\n' "$PB_SMOKE_LABEL" "$key" >&2
			failures=$((failures + 1))
			continue
		fi
		if [[ "$line" != *"result=1"* ]]; then
			printf '[%s] %s selftest did not pass: %s\n' "$PB_SMOKE_LABEL" "$key" "$line" >&2
			failures=$((failures + 1))
			continue
		fi
		if [[ "$key" == "combat" && "$line" != *"continuity_loop_ok=1"* ]]; then
			printf '[%s] combat continuity loop gate failed: %s\n' "$PB_SMOKE_LABEL" "$line" >&2
			failures=$((failures + 1))
			continue
		fi
		if [[ "$key" == "combat" && "$line" != *"continuity_loop_count=3"* ]]; then
			printf '[%s] combat continuity loop depth gate failed: %s\n' "$PB_SMOKE_LABEL" "$line" >&2
			failures=$((failures + 1))
			continue
		fi
		if [[ "$key" == "item" && "$line" != *"loadout_continuity_ok=1"* ]]; then
			printf '[%s] item loadout continuity gate failed: %s\n' "$PB_SMOKE_LABEL" "$line" >&2
			failures=$((failures + 1))
			continue
		fi
		if [[ "$key" == "item" && "$line" != *"mechanic_rollback_ok=1"* ]]; then
			printf '[%s] item mechanic rollback gate failed: %s\n' "$PB_SMOKE_LABEL" "$line" >&2
			failures=$((failures + 1))
			continue
		fi
		if [[ "$key" == "merchant" && "$line" != *"mail_delivery_ok=1"* ]]; then
			printf '[%s] merchant mail delivery gate failed: %s\n' "$PB_SMOKE_LABEL" "$line" >&2
			failures=$((failures + 1))
		fi
	done
	printf '\n[%s] Recent recovery audit summary\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'EOF'
SELECT `scope`, `action`, `result`, `detail`, COUNT(*)
FROM `bot_recovery_audit`
WHERE UNIX_TIMESTAMP() - `ts` <= 1800
  AND `scope` IN ('combat','loadout','npc','storage','trade','skillunit','participation','reservation','ownership')
GROUP BY `scope`, `action`, `result`, `detail`
ORDER BY MAX(`id`) DESC
LIMIT 16;
EOF
	printf '\n[%s] Recent structured trace summary\n' "$PB_SMOKE_LABEL"
	pb_smoke_sql_heredoc <<'EOF'
SELECT `action`, `target_type`, `reason_code`, `result`, COUNT(*)
FROM `bot_trace_event`
WHERE UNIX_TIMESTAMP() - `ts` <= 1800
  AND `phase` IN ('interaction','reservation','reconcile','combat')
GROUP BY `action`, `target_type`, `reason_code`, `result`
ORDER BY MAX(`id`) DESC
LIMIT 20;
EOF
	if (( failures > 0 )); then
		printf '\n[%s] foundation pass failed with %d missing/failing selftest(s).\n' "$PB_SMOKE_LABEL" "$failures" >&2
		return 1
	fi
	printf '\n[%s] foundation pass ok.\n' "$PB_SMOKE_LABEL"
}

pb_smoke_main "$@"
