#!/usr/bin/env bash

playerbot_scenario_ids() {
	printf '%s\n' \
		'combat-baseline' \
		'status-continuity' \
		'status-death-cleanup' \
		'status-map-continuity' \
		'status-respawn-reconcile' \
		'death-respawn' \
		'item-loadout-continuity' \
		'mechanic-cleanup'
}

playerbot_scenario_title() {
	case "${1:-}" in
		combat-baseline) printf '%s\n' 'Combat Baseline' ;;
		status-continuity) printf '%s\n' 'Status Continuity' ;;
		status-death-cleanup) printf '%s\n' 'Status Death Cleanup' ;;
		status-map-continuity) printf '%s\n' 'Status Map Continuity' ;;
		status-respawn-reconcile) printf '%s\n' 'Status Respawn Reconcile' ;;
		death-respawn) printf '%s\n' 'Death / Respawn Continuity' ;;
		item-loadout-continuity) printf '%s\n' 'Item / Loadout Continuity' ;;
		mechanic-cleanup) printf '%s\n' 'Mechanic Cleanup' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_phase() {
	case "${1:-}" in
		combat-baseline) printf '%s\n' 'combat' ;;
		status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile) printf '%s\n' 'status' ;;
		death-respawn) printf '%s\n' 'respawn' ;;
		item-loadout-continuity) printf '%s\n' 'equipment' ;;
		mechanic-cleanup) printf '%s\n' 'participation' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_kind() {
	case "${1:-}" in
		combat-baseline|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|death-respawn)
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
		combat-baseline|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|death-respawn|item-loadout-continuity|mechanic-cleanup)
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
- interrupt an NPC/dialog flow
- interrupt a trade or storage flow
- verify the cleanup path releases claims and clears runtime state
- confirm the recovery surface records the interruption cleanly
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
		status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile)
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
- interrupted participation flows leave a clean recovery/audit trail
- claims and runtime state are released
EOF
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_notes() {
	case "${1:-}" in
		combat-baseline|status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|death-respawn)
			cat <<'EOF'
This scenario now has a repo-local smoke helper through
`tools/ci/playerbot-combat-smoke.sh`. The scenario runner remains the canonical
runbook layer, while the smoke helper is the concrete launcher/check surface.
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
