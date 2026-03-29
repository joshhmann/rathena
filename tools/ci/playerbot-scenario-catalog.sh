#!/usr/bin/env bash

playerbot_scenario_ids() {
	printf '%s\n' \
		'combat-baseline' \
		'combat-skillunit-mapchange-cleanup' \
		'combat-skillunit-death-cleanup' \
		'combat-skillunit-quit-cleanup' \
		'status-continuity' \
		'status-death-cleanup' \
		'status-map-continuity' \
		'status-respawn-reconcile' \
		'status-recovery-integrity' \
		'death-respawn' \
		'item-loadout-continuity' \
		'mechanic-cleanup'
}

playerbot_scenario_title() {
	case "${1:-}" in
		combat-baseline) printf '%s\n' 'Combat Baseline' ;;
		combat-skillunit-mapchange-cleanup) printf '%s\n' 'Combat Skillunit Mapchange Cleanup' ;;
		combat-skillunit-death-cleanup) printf '%s\n' 'Combat Skillunit Death Cleanup' ;;
		combat-skillunit-quit-cleanup) printf '%s\n' 'Combat Skillunit Quit Cleanup' ;;
		status-continuity) printf '%s\n' 'Status Continuity' ;;
		status-death-cleanup) printf '%s\n' 'Status Death Cleanup' ;;
		status-map-continuity) printf '%s\n' 'Status Map Continuity' ;;
		status-respawn-reconcile) printf '%s\n' 'Status Respawn Reconcile' ;;
		status-recovery-integrity) printf '%s\n' 'Status Recovery Integrity' ;;
		death-respawn) printf '%s\n' 'Death / Respawn Continuity' ;;
		item-loadout-continuity) printf '%s\n' 'Item / Loadout Continuity' ;;
		mechanic-cleanup) printf '%s\n' 'Mechanic Cleanup' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_phase() {
	case "${1:-}" in
		combat-baseline|combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup) printf '%s\n' 'combat' ;;
		status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity) printf '%s\n' 'status' ;;
		death-respawn) printf '%s\n' 'respawn' ;;
		item-loadout-continuity) printf '%s\n' 'equipment' ;;
		mechanic-cleanup) printf '%s\n' 'participation' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_kind() {
	case "${1:-}" in
		combat-baseline|combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity|death-respawn)
			printf '%s\n' 'runbook'
			;;
		item-loadout-continuity)
			printf '%s\n' 'runbook'
			;;
		mechanic-cleanup)
			printf '%s\n' 'skeleton'
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
		mechanic-cleanup)
			cat <<'EOF'
Validate that interrupted NPC, trade, storage, and participation flows clean up their claims and runtime state.
EOF
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_prereqs() {
	case "${1:-}" in
		combat-baseline|combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity|death-respawn|item-loadout-continuity|mechanic-cleanup)
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
		mechanic-cleanup)
			cat <<'EOF'
- interrupt an NPC/dialog flow during active participation
- interrupt a trade or storage flow during active participation
- warp the bot while a participation session is still active
- verify the cleanup path releases claims and clears runtime state for each case
- confirm the recovery surface records each interruption cleanly
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
		mechanic-cleanup)
			cat <<'EOF'
- interrupted dialog, trade, storage, and warp flows leave a clean recovery/audit trail
- claims and runtime state are released for each interrupted session
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
		item-loadout-continuity)
			cat <<'EOF'
This scenario now has a repo-local smoke helper through
`tools/ci/playerbot-item-smoke.sh`. The scenario runner remains the canonical
runbook layer, while the item smoke helper is the concrete launcher/check
surface.
EOF
			;;
		mechanic-cleanup)
			cat <<'EOF'
This scenario is intentionally a skeleton definition. It is a stable contract
for future automation, not a claim that the runtime hook is implemented yet.
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
		status-recovery-integrity)
			printf '%s\n' 'bash tools/ci/playerbot-combat-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-combat-smoke.sh check'
			;;
		item-loadout-continuity)
			printf '%s\n' 'bash tools/ci/playerbot-item-smoke.sh arm && <log in with codex> && bash tools/ci/playerbot-item-smoke.sh check'
			;;
		mechanic-cleanup)
			printf '%s\n' ''
			;;
		*)
			return 1
			;;
	esac
}
