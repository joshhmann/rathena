#!/usr/bin/env bash

playerbot_scenario_ids() {
	printf '%s\n' \
		'combat-baseline' \
		'combat-skillunit-mapchange-cleanup' \
		'combat-skillunit-death-cleanup' \
		'combat-skillunit-quit-cleanup' \
		'combat-skillunit-promotion-precheck' \
		'status-continuity' \
		'status-death-cleanup' \
		'status-map-continuity' \
		'status-respawn-reconcile' \
		'status-recovery-integrity' \
		'death-respawn' \
		'item-loadout-continuity' \
		'loadout-denied-recover' \
		'mechanic-cleanup' \
		'market-buyingstore-partial-fill' \
		'market-buyingstore-reopen' \
		'foundation-rich-gate'
}

playerbot_scenario_title() {
	case "${1:-}" in
		combat-baseline) printf '%s\n' 'Combat Baseline' ;;
		combat-skillunit-mapchange-cleanup) printf '%s\n' 'Combat Skillunit Mapchange Cleanup' ;;
		combat-skillunit-death-cleanup) printf '%s\n' 'Combat Skillunit Death Cleanup' ;;
		combat-skillunit-quit-cleanup) printf '%s\n' 'Combat Skillunit Quit Cleanup' ;;
		combat-skillunit-promotion-precheck) printf '%s\n' 'Combat Skillunit Promotion Precheck' ;;
		status-continuity) printf '%s\n' 'Status Continuity' ;;
		status-death-cleanup) printf '%s\n' 'Status Death Cleanup' ;;
		status-map-continuity) printf '%s\n' 'Status Map Continuity' ;;
		status-respawn-reconcile) printf '%s\n' 'Status Respawn Reconcile' ;;
		status-recovery-integrity) printf '%s\n' 'Status Recovery Integrity' ;;
		death-respawn) printf '%s\n' 'Death / Respawn Continuity' ;;
		item-loadout-continuity) printf '%s\n' 'Item / Loadout Continuity' ;;
		loadout-denied-recover) printf '%s\n' 'Loadout Denied / Recover' ;;
		mechanic-cleanup) printf '%s\n' 'Mechanic Cleanup' ;;
		market-buyingstore-partial-fill) printf '%s\n' 'Market Buyingstore Partial Fill' ;;
		market-buyingstore-reopen) printf '%s\n' 'Market Buyingstore Reopen' ;;
		foundation-rich-gate) printf '%s\n' 'Foundation Rich Gate' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_phase() {
	case "${1:-}" in
		combat-baseline|combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup|combat-skillunit-promotion-precheck) printf '%s\n' 'combat' ;;
		status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity) printf '%s\n' 'status' ;;
		death-respawn) printf '%s\n' 'respawn' ;;
		item-loadout-continuity|loadout-denied-recover) printf '%s\n' 'equipment' ;;
		mechanic-cleanup) printf '%s\n' 'participation' ;;
		market-buyingstore-partial-fill|market-buyingstore-reopen) printf '%s\n' 'market' ;;
		foundation-rich-gate) printf '%s\n' 'foundation' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_kind() {
	case "${1:-}" in
		combat-baseline|combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup|combat-skillunit-promotion-precheck|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity|death-respawn)
			printf '%s\n' 'runbook'
			;;
		item-loadout-continuity|loadout-denied-recover)
			printf '%s\n' 'runbook'
			;;
		mechanic-cleanup)
			printf '%s\n' 'runbook'
			;;
		market-buyingstore-partial-fill|market-buyingstore-reopen)
			printf '%s\n' 'runbook'
			;;
		foundation-rich-gate)
			printf '%s\n' 'runbook'
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_purpose() {
	case "${1:-}" in
		combat-baseline)
			cat <<'EOF'
Validate the first legal combat-intent lifecycle once the combat hooks exist.
EOF
			;;
		combat-skillunit-mapchange-cleanup)
			cat <<'EOF'
Validate that a live ground-skill unit is created and then cleared cleanly by a successful map change.
EOF
			;;
		combat-skillunit-death-cleanup)
			cat <<'EOF'
Validate that a live ground-skill unit is interrupted and cleared when the bot dies, and stays fresh after respawn.
EOF
			;;
		combat-skillunit-quit-cleanup)
			cat <<'EOF'
Validate that a live ground-skill unit is cleared when the bot is parked/removed and that quit cleanup is traced and audited.
EOF
			;;
		combat-skillunit-promotion-precheck)
			cat <<'EOF'
Validate that the bot correctly evaluates pre-conditions before placing a ground skill unit — confirming that insufficient SP, out-of-range targets, and invalid cell flags all block placement and leave no orphaned skillunit state.
EOF
			;;
		status-continuity)
			cat <<'EOF'
Validate that status effects are observed, summarized, and cleaned up through the combat frontier.
EOF
			;;
		status-death-cleanup)
			cat <<'EOF'
Validate that buffs and ailments are cleared correctly when a bot dies.
EOF
			;;
		status-map-continuity)
			cat <<'EOF'
Validate that buffs and ailments persist correctly across map changes.
EOF
			;;
		status-respawn-reconcile)
			cat <<'EOF'
Validate that the bot returns to a clean status state after respawning.
EOF
			;;
		status-recovery-integrity)
			cat <<'EOF'
Validate that participation recovery does not mutate live status continuity.
EOF
			;;
		death-respawn)
			cat <<'EOF'
Validate death, respawn, and stale-state cleanup without leaving split-brain runtime state.
EOF
			;;
		item-loadout-continuity)
			cat <<'EOF'
Validate intended loadout continuity across spawn, death, and respawn.
EOF
			;;
		loadout-denied-recover)
			cat <<'EOF'
Validate that when a legal equip attempt is rejected by the engine (wrong job, weight over limit, item locked), the bot's intended loadout record remains intact and the next reconciliation attempt recovers cleanly without duplicate ownership or phantom equip claims.
EOF
			;;
		mechanic-cleanup)
			cat <<'EOF'
Validate that interrupted NPC, trade, storage, and participation flows clean up their claims and runtime state.
EOF
			;;
		market-buyingstore-partial-fill)
			cat <<'EOF'
Validate that a buying store receives a partial fill — some items purchased, zeny deducted, store remains open — and that the bot's market session state reflects the partial fulfillment without claiming full completion or leaving a stale reservation.
EOF
			;;
		market-buyingstore-reopen)
			cat <<'EOF'
Validate that a buying store session that was closed (zeny depleted or operator stop) can be reopened cleanly — confirming that the prior session's zeny/reservation state is fully released before the new session starts and that no double-reservation or orphaned store record exists.
EOF
			;;
		foundation-rich-gate)
			cat <<'EOF'
Validate the promoted richer foundation gate: aggregate foundation pass plus separate passing skillunit probe cycle.
EOF
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_prereqs() {
	case "${1:-}" in
		combat-baseline|combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup|combat-skillunit-promotion-precheck|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity|death-respawn|item-loadout-continuity|loadout-denied-recover|mechanic-cleanup|market-buyingstore-partial-fill|market-buyingstore-reopen|foundation-rich-gate)
			cat <<'EOF'
- repo-local dev stack is restarted
- current foundation smoke remains green
- OpenKore login harness is available for CLI observation if needed
EOF
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_steps() {
	case "${1:-}" in
		combat-baseline)
			cat <<'EOF'
- enter a safe combat test map or combat-enabled observation area
- acquire a hostile target through the combat frontier hooks
- issue attack intent
- confirm the intent can be cleared cleanly
- confirm any required target cleanup/release path is visible in the trace
EOF
			;;
		combat-skillunit-mapchange-cleanup)
			cat <<'EOF'
- arm the dedicated skillunit probe helper
- log in once with the `codex` OpenKore profile
- verify the probe creates a live positional skill unit
- verify a successful map change clears the skill unit
- confirm `reconcile.fixed / skillunit / map.changed / ok` is present in the trace/audit output
EOF
			;;
		combat-skillunit-death-cleanup)
			cat <<'EOF'
- arm the dedicated skillunit probe helper
- log in once with the `codex` OpenKore profile
- verify the probe creates a live positional skill unit
- verify the bot dies with the skill unit active
- confirm the skill unit is cleared on death and remains absent after respawn
- confirm `combat.completed / skillunit / restart.recovery / ok / combat.death.interrupt` is present
EOF
			;;
		combat-skillunit-quit-cleanup)
			cat <<'EOF'
- arm the dedicated skillunit probe helper
- log in once with the `codex` OpenKore profile
- verify the probe creates a live positional skill unit
- verify the bot is parked/removed while the skill unit is active
- confirm quit cleanup clears the skill unit
- confirm `reconcile.fixed / skillunit / operator.stop / ok / quit.interrupt` is present
EOF
			;;
		combat-skillunit-promotion-precheck)
			cat <<'EOF'
- set the test actor's SP below the cost threshold for a ground skill
- attempt to promote a skillunit placement via the combat frontier
- confirm the placement is blocked and no skillunit record is created
- restore SP to a legal value and attempt again with an out-of-range target
- confirm the placement is blocked and no skillunit record is created
- restore range and attempt with a cell flagged as skill-blocked
- confirm the placement is blocked and no skillunit record is created
- perform one successful placement with all conditions met
- confirm `playerbot_skillunitcount(...)` becomes positive and `skillunit.precheck / ok` is present in the trace
EOF
			;;
		status-continuity)
			cat <<'EOF'
- apply a status-affecting event
- verify the status summary reports the active condition
- verify the condition is removed or preserved according to engine rules
- confirm no stale participation or reservation state remains afterward
EOF
			;;
		status-death-cleanup)
			cat <<'EOF'
- apply a buff (e.g., SC_BLESSING) to the bot
- trigger a death event
- verify that playerbot_isdead is true
- verify that playerbot_statusactive for that buff is now false
- check for status.cleared trace and status cleanup audit
EOF
			;;
		status-map-continuity)
			cat <<'EOF'
- apply a buff (e.g., SC_BLESSING) to the bot
- warp the bot to a new map
- verify that the buff remains active after the map change
- confirm status.applied trace persists
EOF
			;;
		status-respawn-reconcile)
			cat <<'EOF'
- trigger a death and respawn sequence
- verify that the bot returns to a fresh state
- confirm that no stale ailments from the previous life remain
- check for status reconcile audit rows
EOF
			;;
		status-recovery-integrity)
			cat <<'EOF'
- trigger a participation recovery event while status effects are active
- verify that the recovery path does not clear or invent status state
- confirm the status summary before and after recovery is unchanged
- check that the recovery audit records the recovery without a status mutation
EOF
			;;
		death-respawn)
			cat <<'EOF'
- trigger a death event in a controlled scenario
- verify death traces and recovery/audit rows are emitted
- respawn the actor
- confirm stale claims, targets, and runtime state are cleaned up
EOF
			;;
		item-loadout-continuity)
			cat <<'EOF'
- define an intended loadout for the test actor
- spawn or respawn the actor
- verify the intended equipment summary is readable
- confirm legal equip reconciliation occurs without duplicate ownership
EOF
			;;
		loadout-denied-recover)
			cat <<'EOF'
- arm the item smoke helper
- log in once with the `codex` OpenKore profile
- run `bash tools/ci/playerbot-item-smoke.sh check-denied`
- confirm the selftest line contains `loadout_denied_ok=1` and `loadout_recover_ok=1`
- confirm `loadout_conflict_cleared_ok=1`, `loadout_audit_ok=1`, and `result=1` are present
- confirm the printed item-audit summary includes denied and slot-conflict-clear rows
EOF
			;;
		mechanic-cleanup)
			cat <<'EOF'
- arm the participation smoke helper
- log in once with the `codex` OpenKore profile
- verify the selftest drives interrupted NPC/dialog, storage, trade, and reservation flows
- confirm the cleanup path releases claims and clears runtime state for each case
- confirm the recovery surface records each interruption cleanly
EOF
			;;
		market-buyingstore-partial-fill)
			cat <<'EOF'
- arm the market smoke helper
- log in once with the `codex` OpenKore profile
- run `bash tools/ci/playerbot-market-smoke.sh check`
- confirm the selftest line contains `buying_sell_first_ok=1` and `buying_partial_ok=1`
- confirm `result=1` and `market_trace_ok=1` are present on the same line
- confirm the printed interaction summary includes `buyingtrade` and `buyingstore` rows
EOF
			;;
		market-buyingstore-reopen)
			cat <<'EOF'
- arm the market smoke helper
- log in once with the `codex` OpenKore profile
- run `bash tools/ci/playerbot-market-smoke.sh check`
- confirm the selftest line contains `buying_reopen_ok=1`, `buying_close_ok=1`, and `buying_closed_ok=1`
- confirm `result=1` and `market_trace_ok=1` are present on the same line
- confirm the printed interaction summary includes `buyingstore` close/open lifecycle rows
EOF
			;;
		foundation-rich-gate)
			cat <<'EOF'
- run the canonical richer gate command:
  - `bash tools/ci/playerbot-foundation-smoke.sh run-rich`
- confirm the aggregate foundation gate passes first
- confirm the separate skillunit probe cycle passes
- confirm the final line reports `rich gate pass ok`
EOF
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_expected() {
	case "${1:-}" in
		combat-baseline)
			cat <<'EOF'
- combat-intent trace rows exist
- combat-clear / target-release rows exist
- no stale claim remains after the intent is cleared
EOF
			;;
		combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup)
			cat <<'EOF'
- `playerbot_combat_skillunit_probe ... result=1` is present
- `playerbot_skillunitcount(...)` becomes positive during the probe
- `scope = 'skillunit'` recovery audits are emitted for the targeted transition
- the trace output shows both the `skill_pos` request/completion and the `skillunit` cleanup event
EOF
			;;
		combat-skillunit-promotion-precheck)
			cat <<'EOF'
- each blocked attempt produces a `skillunit.precheck / denied / <reason>` trace row
- `playerbot_skillunitcount(...)` remains zero for all denied attempts
- one successful placement produces `skillunit.precheck / ok` in the trace
- `playerbot_skillunitcount(...)` becomes positive for the successful attempt
- no orphaned skillunit ownership or pending placement rows exist after blocked attempts
EOF
			;;
		status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity)
			cat <<'EOF'
- status summary reflects the live effect
- recovery or cleanup rows reflect the transition
EOF
			;;
		death-respawn)
			cat <<'EOF'
- death and respawn trace rows exist
- stale ownership, target, and reservation rows are cleared
EOF
			;;
		item-loadout-continuity)
			cat <<'EOF'
- intended loadout is visible in the summary
- legal equip reconciliation leaves a clean inventory/equipment state
EOF
			;;
		loadout-denied-recover)
			cat <<'EOF'
- `playerbot_item_selftest ... loadout_denied_ok=1 ... loadout_recover_ok=1 ... result=1` is present
- `loadout_conflict_ok=1` and `loadout_conflict_cleared_ok=1` are present
- `loadout_audit_ok=1` is present
- recent `bot_item_audit` summary shows one denied detail row (`loadout.manual.*.denied`) and `loadout.manual.slot_conflict.clear`
EOF
			;;
		mechanic-cleanup)
			cat <<'EOF'
- `playerbot_participation_selftest ... result=1` is present
- interrupted dialog, storage, trade, reservation, and quit flows leave a clean recovery/audit trail
- claims and runtime state are released for each interrupted session
- recent `interaction` trace rows show the participation targets completing or failing cleanly
EOF
			;;
		market-buyingstore-partial-fill)
			cat <<'EOF'
- `playerbot_merchant_selftest ... buying_partial_ok=1 ... result=1` is present
- `buying_sell_first_ok=1` and `buying_sell_ok=1` are both present
- `market_trace_ok=1` is present
- recent interaction summary shows `buyingtrade` and `buyingstore` target rows
EOF
			;;
		market-buyingstore-reopen)
			cat <<'EOF'
- `playerbot_merchant_selftest ... buying_reopen_ok=1 ... result=1` is present
- `buying_close_ok=1` and `buying_closed_ok=1` are both present
- `market_trace_ok=1` is present
- recent interaction summary shows `buyingstore` lifecycle target rows
EOF
			;;
		foundation-rich-gate)
			cat <<'EOF'
- `[playerbot-foundation-smoke] foundation pass ok.` is present
- `playerbot_combat_skillunit_probe ... result=1` is present in the rich cycle
- `[playerbot-foundation-smoke] rich gate pass ok.` is present
EOF
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_notes() {
	case "${1:-}" in
		combat-baseline|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity|death-respawn)
			cat <<'EOF'
This scenario now has a repo-local smoke helper through
`tools/ci/playerbot-combat-smoke.sh`. The scenario runner remains the canonical
runbook layer, while the smoke helper is the concrete launcher/check surface.
EOF
			;;
		combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup)
			cat <<'EOF'
These scenarios are backed by the dedicated skillunit probe helper:
`tools/ci/playerbot-combat-skillunit-smoke.sh`.

They remain separate from the aggregate combat selftest on purpose. The current
foundation baseline proves skillunit creation and cleanup through the dedicated
probe, while the aggregate combat gate stays on the last stable combat path.
EOF
			;;
		combat-skillunit-promotion-precheck)
			cat <<'EOF'
This scenario is a skeleton runbook definition — there is no automated smoke
helper yet. It documents the pre-condition validation surface that must be
confirmed before the combat skillunit frontier can promote to a wider gate.

Once the skillunit precheck hook is implemented in the runtime layer, this
scenario should be backed by a dedicated smoke helper and its launcher field
populated.
EOF
			;;
		item-loadout-continuity)
			cat <<'EOF'
This scenario now has a repo-local smoke helper through
`tools/ci/playerbot-item-smoke.sh`. The scenario runner remains the canonical
runbook layer, while the item smoke helper is the concrete launcher/check
surface.
EOF
			;;
		loadout-denied-recover)
			cat <<'EOF'
This scenario is now backed by the item smoke helper:
`tools/ci/playerbot-item-smoke.sh` with `check-denied`.

It extends the base item continuity proof with explicit denial/recovery checks
and required item-audit signals for the loadout reconcile frontier.
EOF
			;;
		mechanic-cleanup)
			cat <<'EOF'
This scenario is now backed by the participation smoke helper:
`tools/ci/playerbot-participation-smoke.sh`.

It is the accepted runbook for interrupted participation cleanup across dialog,
storage, trade, reservations, and quit/remove cleanup on the current baseline.
EOF
			;;
		market-buyingstore-partial-fill|market-buyingstore-reopen)
			cat <<'EOF'
These scenarios are now backed by the market smoke helper:
`tools/ci/playerbot-market-smoke.sh`.

The accepted proof uses the merchant selftest result line plus interaction trace
summary to prove partial-fill and reopen continuity in one deterministic path.
EOF
			;;
		foundation-rich-gate)
			cat <<'EOF'
This scenario is backed by the integrated richer gate command:
`bash tools/ci/playerbot-foundation-smoke.sh run-rich`.

It is intentionally two-phase:
1. aggregate foundation gate (`run`)
2. separate skillunit probe gate

That split preserves aggregate determinism while still requiring richer
skillunit proof as part of promoted foundation validation.
EOF
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_launcher() {
	case "${1:-}" in
		combat-baseline|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|death-respawn)
			printf '%s\n' 'bash tools/ci/playerbot-combat-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-combat-smoke.sh check'
			;;
		combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup)
			printf '%s\n' 'bash tools/ci/playerbot-combat-skillunit-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-combat-skillunit-smoke.sh check'
			;;
		combat-skillunit-promotion-precheck)
			return 1
			;;
		status-recovery-integrity)
			printf '%s\n' 'bash tools/ci/playerbot-combat-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-combat-smoke.sh check'
			;;
		item-loadout-continuity)
			printf '%s\n' 'bash tools/ci/playerbot-item-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-item-smoke.sh check'
			;;
		loadout-denied-recover)
			printf '%s\n' 'bash tools/ci/playerbot-item-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-item-smoke.sh check-denied'
			;;
		mechanic-cleanup)
			printf '%s\n' 'bash tools/ci/playerbot-participation-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-participation-smoke.sh check'
			;;
		market-buyingstore-partial-fill|market-buyingstore-reopen)
			printf '%s\n' 'bash tools/ci/playerbot-market-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-market-smoke.sh check'
			;;
		foundation-rich-gate)
			printf '%s\n' 'bash tools/ci/playerbot-foundation-smoke.sh run-rich'
			;;
		*)
			return 1
			;;
	esac
}
