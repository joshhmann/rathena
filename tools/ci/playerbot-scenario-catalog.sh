#!/usr/bin/env bash

playerbot_scenario_ids() {
	printf '%s\n' \
		'combat-baseline' \
		'combat-skillunit-mapchange-cleanup' \
		'combat-skillunit-death-cleanup' \
		'combat-skillunit-quit-cleanup' \
		'combat-skillunit-promotion-precheck' \
		'combat-pvp-woe-death-semantics' \
		'combat-repeated-transition-stress' \
		'companion-spawn-continuity' \
		'behavior-social-presence' \
		'behavior-party-support' \
		'status-continuity' \
		'status-death-cleanup' \
		'status-map-continuity' \
		'status-respawn-reconcile' \
		'status-recovery-integrity' \
		'death-respawn' \
		'item-loadout-continuity' \
		'loadout-denied-recover' \
		'loadout-overlap-continuity' \
		'mechanic-cleanup' \
		'mechanic-execution-rollback' \
		'guild-storage-signal-integrity' \
		'market-buyingstore-partial-fill' \
		'market-buyingstore-reopen' \
		'market-buyingstore-denial-continuity' \
		'market-mail-delivery-integrity' \
		'market-rodex-receive-attachments' \
		'market-session-restart-continuity' \
		'lifecycle-spawn-failure-cleanup' \
		'lifecycle-despawn-grace-window' \
		'foundation-rich-gate'
}

playerbot_scenario_title() {
	case "${1:-}" in
		combat-baseline) printf '%s\n' 'Combat Baseline' ;;
		combat-skillunit-mapchange-cleanup) printf '%s\n' 'Combat Skillunit Mapchange Cleanup' ;;
		combat-skillunit-death-cleanup) printf '%s\n' 'Combat Skillunit Death Cleanup' ;;
		combat-skillunit-quit-cleanup) printf '%s\n' 'Combat Skillunit Quit Cleanup' ;;
		combat-skillunit-promotion-precheck) printf '%s\n' 'Combat Skillunit Promotion Precheck' ;;
		combat-pvp-woe-death-semantics) printf '%s\n' 'Combat PvP / WoE Death Semantics' ;;
		combat-repeated-transition-stress) printf '%s\n' 'Combat Repeated Transition Stress' ;;
		companion-spawn-continuity) printf '%s\n' 'Companion Spawn Continuity' ;;
		behavior-social-presence) printf '%s\n' 'Behavior Social Presence' ;;
		behavior-party-support) printf '%s\n' 'Behavior Party Support' ;;
		status-continuity) printf '%s\n' 'Status Continuity' ;;
		status-death-cleanup) printf '%s\n' 'Status Death Cleanup' ;;
		status-map-continuity) printf '%s\n' 'Status Map Continuity' ;;
		status-respawn-reconcile) printf '%s\n' 'Status Respawn Reconcile' ;;
		status-recovery-integrity) printf '%s\n' 'Status Recovery Integrity' ;;
		death-respawn) printf '%s\n' 'Death / Respawn Continuity' ;;
		item-loadout-continuity) printf '%s\n' 'Item / Loadout Continuity' ;;
		loadout-denied-recover) printf '%s\n' 'Loadout Denied / Recover' ;;
		loadout-overlap-continuity) printf '%s\n' 'Loadout Overlap Continuity' ;;
		mechanic-cleanup) printf '%s\n' 'Mechanic Cleanup' ;;
		mechanic-execution-rollback) printf '%s\n' 'Mechanic Execution Rollback' ;;
		guild-storage-signal-integrity) printf '%s\n' 'Guild Storage Signal Integrity' ;;
		market-buyingstore-partial-fill) printf '%s\n' 'Market Buyingstore Partial Fill' ;;
		market-buyingstore-reopen) printf '%s\n' 'Market Buyingstore Reopen' ;;
		market-buyingstore-denial-continuity) printf '%s\n' 'Market Buyingstore Denial Continuity' ;;
		market-mail-delivery-integrity) printf '%s\n' 'Market Mail Delivery Integrity' ;;
		market-rodex-receive-attachments) printf '%s\n' 'Market Rodex Receive / Attachments' ;;
		market-session-restart-continuity) printf '%s\n' 'Market Session Restart Continuity' ;;
		lifecycle-spawn-failure-cleanup) printf '%s\n' 'Lifecycle Spawn-Failure Cleanup' ;;
		lifecycle-despawn-grace-window) printf '%s\n' 'Lifecycle Despawn Grace Window' ;;
		foundation-rich-gate) printf '%s\n' 'Foundation Rich Gate' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_phase() {
	case "${1:-}" in
		combat-baseline|combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup|combat-skillunit-promotion-precheck|combat-pvp-woe-death-semantics|combat-repeated-transition-stress) printf '%s\n' 'combat' ;;
		companion-spawn-continuity) printf '%s\n' 'lifecycle' ;;
		behavior-social-presence) printf '%s\n' 'behavior' ;;
		behavior-party-support) printf '%s\n' 'behavior' ;;
		status-continuity|status-death-cleanup|status-map-continuity|status-respawn-reconcile|status-recovery-integrity) printf '%s\n' 'status' ;;
		death-respawn) printf '%s\n' 'respawn' ;;
		item-loadout-continuity|loadout-denied-recover|loadout-overlap-continuity) printf '%s\n' 'equipment' ;;
		mechanic-cleanup|mechanic-execution-rollback) printf '%s\n' 'participation' ;;
		guild-storage-signal-integrity) printf '%s\n' 'guild' ;;
		market-buyingstore-partial-fill|market-buyingstore-reopen|market-buyingstore-denial-continuity|market-mail-delivery-integrity|market-rodex-receive-attachments|market-session-restart-continuity) printf '%s\n' 'market' ;;
		lifecycle-spawn-failure-cleanup|lifecycle-despawn-grace-window) printf '%s\n' 'lifecycle' ;;
		foundation-rich-gate) printf '%s\n' 'foundation' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_kind() {
	playerbot_scenario_ids | grep -qx "${1:-}" && printf '%s\n' 'runbook' || return 1
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
Validate that the bot correctly evaluates blocked cast pre-conditions before placing a ground skill unit — confirming that cast-condition denials, invalid targets, and near-NPC/cell contexts all block placement and leave no orphaned skillunit state.
EOF
			;;
		combat-pvp-woe-death-semantics)
			cat <<'EOF'
Validate that PvP nightmare-drop handling does not strip headless bot gear/items and that PvP/GvG-style death respawn routing returns the bot to its configured savepoint cleanly.
EOF
			;;
		combat-repeated-transition-stress)
			cat <<'EOF'
Validate repeated sequential combat/status/death/respawn transitions stay deterministic and do not leak stale combat/session state across loops.
EOF
			;;
		companion-spawn-continuity)
			cat <<'EOF'
Validate that helper-backed mercenary, elemental, and pet state can survive headless despawn/respawn without blocking bring-up and can be cleaned up afterward.
EOF
			;;
		behavior-social-presence)
			cat <<'EOF'
Validate the first town/social behavior family on top of the shared behavior kernel: a recurring bot should choose among idle, emote, and hotspot reposition actions and leave inspectable decision memory.
EOF
			;;
		behavior-party-support)
			cat <<'EOF'
Validate the first party/support behavior family on top of the shared behavior kernel: a party-capable bot should choose assist as the winning action under party-friendly policy and then complete the existing assist-anchor runtime.
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
Validate that when a legal equip attempt is rejected by the engine (wrong job, weight over limit, item locked), and when refine/reform/enchantgrade execution is denied by preconditions, session ownership still clears cleanly and the next reconcile/execute attempt recovers without duplicate ownership or phantom state.
EOF
			;;
		loadout-overlap-continuity)
			cat <<'EOF'
Validate that intended loadout and item ownership remain correct when equipment/use flows overlap with combat/session/mechanic transitions.
EOF
			;;
		mechanic-cleanup)
			cat <<'EOF'
Validate that interrupted NPC, trade, storage, and participation flows clean up their claims and runtime state.
EOF
			;;
		mechanic-execution-rollback)
			cat <<'EOF'
Validate that denied or interrupted refine/reform/enchantgrade execution rolls back safely and leaves clean session ownership for the next legal attempt.
EOF
			;;
		guild-storage-signal-integrity)
			cat <<'EOF'
Validate that guild storage demand/activity signals can be seeded, observed, and cleaned up safely through the real guild storage tables.
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
		market-buyingstore-denial-continuity)
			cat <<'EOF'
Validate that buyingstore sell denials for browse-inactive, wrong-item, overfill, and zeny-limit attempts do not tear down either side of the market session and that continuity still reaches legal partial-fill and close/reopen flow.
EOF
			;;
		market-mail-delivery-integrity)
			cat <<'EOF'
Validate market-adjacent mail/session continuity so send/delivery checks remain deterministic and do not block legal session close/recover paths.
EOF
			;;
		market-rodex-receive-attachments)
			cat <<'EOF'
Validate that Rodex inbox refresh, receive, and attachment retrieval work for a live playerbot without duplicating inventory or leaving attachment residue in the mail tables.
EOF
			;;
		market-session-restart-continuity)
			cat <<'EOF'
Validate market/session state remains consistent across restart/reconnect cycles without orphaned reservations, stale opens, or split ownership.
EOF
			;;
		lifecycle-spawn-failure-cleanup)
			cat <<'EOF'
Validate the explicit spawn-failure cleanup path now covered in runtime: if headless load reaches map-side visibility setup and fails before spawn-ready completion, partial runtime state must roll back and spawn-time follow-on reconcile must stop.
EOF
			;;
		lifecycle-despawn-grace-window)
			cat <<'EOF'
Validate the runtime-visible grace-window behavior for controller-owned actors: demand drop should mark live actors as `park_state='grace'` with a `despawn_grace_until` deadline before final park/remove.
EOF
			;;
		foundation-rich-gate)
			cat <<'EOF'
Validate the promoted richer foundation gate: aggregate foundation pass plus separate passing skillunit probe and skillunit precheck cycles.
EOF
			;;
		*)
			return 1
			;;
	esac
}

playerbot_scenario_prereqs() {
	playerbot_scenario_ids | grep -qx "${1:-}" || return 1
	cat <<'EOF'
- repo-local dev stack is restarted
- current foundation smoke remains green
- OpenKore login harness is available for CLI observation if needed
EOF
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
- arm the dedicated skillunit precheck helper
- log in once with the `codex` OpenKore profile
- run `bash tools/ci/playerbot-combat-skillunit-precheck-smoke.sh check`
- confirm the first cast-condition precheck attempt is denied (`low_sp_apply_ok=1`) with no unit created
- confirm invalid-target attempt is denied (`range_apply_ok=1`) with no unit created
- confirm near-NPC/cell attempt is denied (`cell_apply_ok=1`) with no unit created
- confirm the probe line ends with `result=1`
- note: successful control placement remains covered by the dedicated
  `playerbot-combat-skillunit-smoke.sh` probe lane
EOF
			;;
		combat-pvp-woe-death-semantics)
			cat <<'EOF'
- arm the dedicated combat edge probe helper
- log in once with the `codex` OpenKore profile
- verify a PvP nightmare-drop death keeps the bot's equipped knife intact
- verify a later PvP death enters respawning state and returns the bot to its savepoint
- verify a GvG/WoE-style death also enters respawning state and returns the bot to its savepoint
- confirm the probe line ends with `result=1`
EOF
			;;
		combat-repeated-transition-stress)
			cat <<'EOF'
- run repeated aggregate foundation cycles (`run`) in a single window
- verify each cycle reports pass without manual cleanup between loops
- verify no drift in recovery/audit signal counts across early and late loops
- verify restart/respawn/cleanup transitions remain deterministic end-to-end
EOF
			;;
		companion-spawn-continuity)
			cat <<'EOF'
- arm the dedicated companion selftest helper
- log in once with the `codex` OpenKore profile
- verify mercenary state survives one despawn/respawn cycle and can be cleaned up
- verify elemental state survives one despawn/respawn cycle and can be cleaned up
- verify pet state survives one despawn/respawn cycle and can be cleaned up
- confirm the helper ends with `result=1`
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
- trigger a successful map change and return
- confirm intended equipment continuity survives the map transition
- confirm legal equip reconciliation occurs without duplicate ownership
EOF
			;;
		loadout-denied-recover)
			cat <<'EOF'
- arm the item smoke helper
- log in once with the `codex` OpenKore profile
- run `bash tools/ci/playerbot-item-smoke.sh check-denied`
- confirm the selftest line contains `loadout_denied_ok=1` and `loadout_recover_ok=1`
- confirm `refine_deny_ok=1`, `reform_deny_ok=1`, and `enchant_deny_ok=1` are present with corresponding `*_deny_clear_ok=1`
- confirm `refine_exec_ok=1`, `refine_material_ok=1`, `refine_level_ok=1`, and `refine_session_clear_ok=1` are present
- confirm `loadout_conflict_cleared_ok=1`, `loadout_audit_ok=1`, and `result=1` are present
- confirm the printed item-audit summary includes denied and slot-conflict-clear rows
EOF
			;;
		loadout-overlap-continuity)
			cat <<'EOF'
- run `check-denied` to establish denied/recover baseline and clean ownership
- run aggregate foundation smoke immediately after item lane completion
- rerun `check-denied` and verify the same denied/recover proofs remain green
- confirm no duplicate ownership, stale session claims, or phantom item state appears between passes
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
		mechanic-execution-rollback)
			cat <<'EOF'
- run item denied/recover execution checks (`check-denied`) in one window
- verify denied refine/reform/enchantgrade attempts clear execution/session ownership
- verify the next legal execution attempt succeeds and session ownership clears again
- verify rollback leaves no stuck participation/session state
EOF
			;;
		behavior-social-presence)
			cat <<'EOF'
- arm the dedicated social-behavior helper
- log in once with the `codex` OpenKore profile
- run `bash tools/ci/playerbot-social-behavior-smoke.sh check`
- confirm the selftest line contains `ticks_ok=1`, `decision_ok=1`, `move_ok=1`, and `result=1`
- confirm the printed behavior memory rows include `last_action`, `last_reason`, and the social hotspot memory row
EOF
			;;
		behavior-party-support)
			cat <<'EOF'
- arm the dedicated party-behavior helper
- log in once with the `codex` OpenKore profile
- run `bash tools/ci/playerbot-party-behavior-smoke.sh check`
- confirm the selftest line contains `policy_pick$=assist`, `assist_ok=1`, and `result=1`
- confirm the printed behavior memory rows include `last_action=assist` and `last_reason=party.assist.policy`
EOF
			;;
		guild-storage-signal-integrity)
			cat <<'EOF'
- clear any previous sentinel guild-storage probe rows
- run `bash tools/ci/playerbot-guild-storage-smoke.sh seed`
- run `bash tools/ci/playerbot-guild-storage-smoke.sh check`
- verify the configured guild reports one storage row and one recent log row
- run `bash tools/ci/playerbot-guild-storage-smoke.sh clear`
- confirm the helper leaves no sentinel residue behind
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
		market-buyingstore-denial-continuity)
			cat <<'EOF'
- arm the market smoke helper
- log in once with the `codex` OpenKore profile
- run `bash tools/ci/playerbot-market-smoke.sh check`
- confirm the selftest line contains `buying_browse_inactive_denied_ok=1`, `buying_wrong_item_denied_ok=1`, `buying_overfill_denied_ok=1`, `buying_zeny_limit_denied_ok=1`, and `buying_denial_trace_ok=1`
- confirm `result=1`, `buying_partial_ok=1`, and `buying_reopen_ok=1` remain present on the same line
- confirm the printed interaction summary includes `buyingtrade` denials and completed rows in the same test window
EOF
			;;
		market-mail-delivery-integrity)
			cat <<'EOF'
- run aggregate foundation smoke and capture market/session trace output
- verify mail-related market/session transitions do not leave stale reservations
- verify market session close/recover paths still pass after mail activity
EOF
			;;
		market-rodex-receive-attachments)
			cat <<'EOF'
- arm the dedicated Rodex attachment selftest helper
- log in once with the `codex` OpenKore profile
- verify the helper seeds one Rodex mail with one item attachment and zeny
- verify inbox refresh finds the seeded mail
- verify attachment retrieval increases the bot inventory and zeny exactly once
- verify the mail row is cleared of attachment/zeny residue and the helper ends with `result=1`
EOF
			;;
		market-session-restart-continuity)
			cat <<'EOF'
- run the market smoke restart-oriented cycle
- verify market session state remains consistent across restart/reconnect boundary
- verify no orphaned reservation or stale open-session state remains after restart
EOF
			;;
		lifecycle-spawn-failure-cleanup)
			cat <<'EOF'
- inspect the current headless bring-up failure contract in:
  - `src/map/clif.cpp`
  - `src/map/pc.cpp`
  - `doc/project/headless-pc-edge-cases.md`
  - `doc/project/playerbot-rathena-system-coverage.md`
- run `bash tools/ci/playerbot-lifecycle-spawnfail-smoke.sh run`
- confirm spawn-ready completion remains the only accepted success boundary
- confirm the runtime now aborts partial spawn state on the documented failure path:
  - `map_addblock(sd)` failure before `chrif_headlesspc_mark_spawn_ready(...)`
- confirm spawn-time loadout reconcile does not run after failed headless load
EOF
			;;
		lifecycle-despawn-grace-window)
			cat <<'EOF'
- inspect the current lifecycle/grace-window contract in:
  - `doc/project/headless-pc-edge-cases.md`
  - `doc/project/playerbot-rathena-system-coverage.md`
  - scheduler/playerbot closeout docs
- run `bash tools/ci/playerbot-lifecycle-grace-smoke.sh run`
- confirm demand-drop now writes runtime grace state:
  - `park_state='grace'`
  - `despawn_grace_until > now`
- confirm final park/remove still clears runtime state back to parked/offline
EOF
			;;
		foundation-rich-gate)
			cat <<'EOF'
- run the canonical richer gate command:
  - `bash tools/ci/playerbot-foundation-smoke.sh run-rich`
- confirm the aggregate foundation gate passes first
- confirm the separate skillunit probe cycle passes
- confirm the separate skillunit precheck cycle passes
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
		combat-repeated-transition-stress)
			cat <<'EOF'
- repeated closeout loops pass without manual intervention
- recovery/audit signals stay stable across loop progression
- no stale combat or participation/session ownership appears after loops
EOF
			;;
		combat-skillunit-promotion-precheck)
			cat <<'EOF'
- `playerbot_combat_skillunit_precheck ... result=1` is present
- `low_sp_apply_ok=1`, `range_apply_ok=1`, and `cell_apply_ok=1` are present
- denied attempts keep skillunit count unchanged (`*_unit_ok=1`)
- recent `skill_pos` traces show denied rows with precheck detail coverage
- successful control placement is verified separately by
  `playerbot_combat_skillunit_probe`
EOF
			;;
		combat-pvp-woe-death-semantics)
			cat <<'EOF'
- `playerbot_combat_edge_probe ... result=1` is present
- the probe reports `pvp_keep1_ok=1`, `pvp_auto_ok=1`, and `pvp_keep2_ok=1`
- the probe reports `gvg_auto_ok=1` and `gvg_keep_ok=1`
- recent combat traces show both death and respawn rows
- recent combat recovery audits show death/respawn rows through the normal recovery path
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
- map-change loadout reconcile audits (`loadout.mapchange ...`) are emitted
EOF
			;;
		loadout-denied-recover)
			cat <<'EOF'
- `playerbot_item_selftest ... loadout_denied_ok=1 ... loadout_recover_ok=1 ... result=1` is present
- `refine_deny_ok=1`, `reform_deny_ok=1`, and `enchant_deny_ok=1` are present with corresponding `*_deny_clear_ok=1`
- `phracon_grant_ok=1`, `refine_exec_ok=1`, `refine_material_ok=1`, `refine_level_ok=1`, and `refine_session_clear_ok=1` are present
- `loadout_conflict_ok=1` and `loadout_conflict_cleared_ok=1` are present
- `loadout_audit_ok=1`, `refine_denied_audit_ok=1`, `reform_denied_audit_ok=1`, and `enchant_denied_audit_ok=1` are present
- recent `bot_item_audit` summary shows one denied detail row (`loadout.manual.*.denied`), `loadout.manual.slot_conflict.clear`, and denied rows for `refine`, `reform`, and `enchantgrade`
EOF
			;;
		loadout-overlap-continuity)
			cat <<'EOF'
- denied/recover item proofs remain green before and after aggregate foundation runs
- loadout/session ownership remains single-owner (no duplicates/split claims)
- no phantom item state appears after overlap transitions
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
		mechanic-execution-rollback)
			cat <<'EOF'
- denied refine/reform/enchantgrade attempts emit rollback-clean ownership signals
- next legal execution attempt succeeds and clears ownership cleanly
- no stuck execution/session state remains after denial/retry sequence
EOF
			;;
		guild-storage-signal-integrity)
			cat <<'EOF'
- the helper reports one guild storage row for the configured guild after seeding
- the helper reports one recent guild storage log row for the configured guild after seeding
- clearing the helper removes the sentinel rows cleanly
EOF
			;;
		companion-spawn-continuity)
			cat <<'EOF'
- `playerbot_companion_selftest ... result=1` is present
- the helper reports successful mercenary, elemental, and pet respawn continuity
- cleanup leaves the companion-bearing bot parked and cleared
EOF
			;;
		behavior-social-presence)
			cat <<'EOF'
- `playerbot_social_behavior_selftest ... result=1` is present
- the selftest reports successful ticks, decision memory, and hotspot movement
- current behavior memory rows include `last_action`, `last_reason`, and `social.hotspot`
EOF
			;;
		behavior-party-support)
			cat <<'EOF'
- `playerbot_party_behavior_selftest ... result=1` is present
- the selftest reports `policy_pick$=assist`, `policy_ok=1`, and `assist_ok=1`
- current behavior memory rows include `last_action=assist` and `last_reason=party.assist.policy`
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
		market-buyingstore-denial-continuity)
			cat <<'EOF'
- `playerbot_merchant_selftest ... buying_browse_inactive_denied_ok=1 ... buying_wrong_item_denied_ok=1 ... buying_overfill_denied_ok=1 ... buying_zeny_limit_denied_ok=1 ... buying_denial_trace_ok=1 ... result=1` is present
- `buying_partial_ok=1` and `buying_reopen_ok=1` are both still present
- `market_trace_ok=1` is present
- recent interaction summary shows denied and completed `buyingtrade` rows within the same run
EOF
			;;
		market-mail-delivery-integrity)
			cat <<'EOF'
- mail/session operations do not orphan market reservations
- market close/recover continuity remains green after mail activity
- no stale market session ownership remains in trace/audit outputs
EOF
			;;
		market-rodex-receive-attachments)
			cat <<'EOF'
- `playerbot_mail_selftest ... result=1` is present
- the selftest reports successful inbox refresh, mail lookup, attachment retrieval, and cleanup
- recent traces show `mail_inbox` refresh and `mail_attach` request rows
- mail table residue is cleared after retrieval
EOF
			;;
		market-session-restart-continuity)
			cat <<'EOF'
- restart/reconnect preserves consistent market session ownership
- no orphaned reservations remain after restart window
- market session open/close lifecycle remains deterministic post-restart
EOF
			;;
		lifecycle-spawn-failure-cleanup)
			cat <<'EOF'
- the runtime explicitly rolls back partial spawn state on the documented `map_addblock` failure path
- spawn-time loadout reconcile does not continue after failed headless load
- `playerbot_lifecycle_spawnfail_selftest ... result=1` is present
EOF
			;;
		lifecycle-despawn-grace-window)
			cat <<'EOF'
- controller grace is now runtime-visible through `park_state='grace'` and `despawn_grace_until`
- `playerbot_lifecycle_grace_selftest ... result=1` is present
- final park/remove clears runtime state back to `offline/parked`
EOF
			;;
		foundation-rich-gate)
			cat <<'EOF'
- `[playerbot-foundation-smoke] foundation pass ok.` is present
- `playerbot_combat_skillunit_probe ... result=1` is present in the rich cycle
- `playerbot_combat_skillunit_precheck ... result=1` is present in the rich cycle
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
		combat-repeated-transition-stress)
			cat <<'EOF'
This scenario uses the closeout loop helper:
`tools/ci/playerbot-foundation-closeout.sh`.

It is the promoted stability gate for repeated aggregate transitions across a
single process window.
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
This scenario is now backed by the dedicated precheck helper:
`tools/ci/playerbot-combat-skillunit-precheck-smoke.sh`.

It is the accepted gate for blocked skillunit placement preconditions
(insufficient cast conditions, invalid target/cell contexts) before the
successful control placement.
EOF
			;;
		combat-pvp-woe-death-semantics)
			cat <<'EOF'
This scenario is backed by the dedicated combat edge helper:
`tools/ci/playerbot-combat-edge-smoke.sh`.

It keeps PvP nightmare-drop retention and WoE-style respawn routing in a
separate proof lane so aggregate combat acceptance stays focused on the stable
baseline combat lifecycle.
EOF
			;;
		companion-spawn-continuity)
			cat <<'EOF'
This scenario is backed by the dedicated companion helper:
`tools/ci/playerbot-companion-smoke.sh`.

It proves helper-backed spawn continuity for mercenary, elemental, and pet
state while leaving homunculus explicitly out of scope.
EOF
			;;
		behavior-social-presence)
			cat <<'EOF'
This scenario is backed by the dedicated social behavior helper:
`tools/ci/playerbot-social-behavior-smoke.sh`.

It is the first real behavior-family proof on top of the kernel scaffold and is
currently limited to deterministic town/social presence choices.
EOF
			;;
		behavior-party-support)
			cat <<'EOF'
This scenario is backed by the dedicated party behavior helper:
`tools/ci/playerbot-party-behavior-smoke.sh`.

It proves the first kernel-backed party/support behavior slice by combining
config-driven assist choice with the existing hidden party assist runtime.
EOF
			;;
		guild-storage-signal-integrity)
			cat <<'EOF'
This scenario is backed by the SQL-safe guild storage helper:
`tools/ci/playerbot-guild-storage-smoke.sh`.

It proves the current foundation surface for guild storage demand/activity
signals, not a full bot-driven guild-storage UI/runtime loop.
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
		market-buyingstore-partial-fill|market-buyingstore-reopen|market-buyingstore-denial-continuity)
			cat <<'EOF'
These scenarios are now backed by the market smoke helper:
`tools/ci/playerbot-market-smoke.sh`.

The accepted proof uses the merchant selftest result line plus interaction trace
summary to prove partial-fill and reopen continuity in one deterministic path.
EOF
			;;
		market-rodex-receive-attachments)
			cat <<'EOF'
This scenario is backed by the dedicated Rodex helper:
`tools/ci/playerbot-rodex-attachment-smoke.sh`.

It proves inbox refresh plus attachment retrieval as a helper-backed mail
surface without claiming full Rodex return/delete workflow coverage.
EOF
			;;
		market-mail-delivery-integrity|market-session-restart-continuity)
			cat <<'EOF'
These scenarios extend market/session continuity coverage through aggregate
foundation and restart windows, where session drift is most likely.
EOF
			;;
		lifecycle-spawn-failure-cleanup)
			cat <<'EOF'
This lifecycle scenario is now backed by the dedicated helper:
`tools/ci/playerbot-lifecycle-spawnfail-smoke.sh`.

It proves the explicit forced-failure cleanup path without relying on organic
`map_addblock` failure reproduction.
EOF
			;;
		lifecycle-despawn-grace-window)
			cat <<'EOF'
This lifecycle scenario is now backed by the dedicated helper:
`tools/ci/playerbot-lifecycle-grace-smoke.sh`.

It proves runtime-visible grace entry and final parked/offline cleanup, but it
is not yet promoted into the automated closeout set.
EOF
			;;
		foundation-rich-gate)
			cat <<'EOF'
This scenario is backed by the integrated richer gate command:
`bash tools/ci/playerbot-foundation-smoke.sh run-rich`.

It is intentionally three-phase:
1. aggregate foundation gate (`run`)
2. separate skillunit probe gate
3. separate skillunit precheck gate

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
			printf '%s\n' 'bash tools/ci/playerbot-combat-smoke.sh run'
			;;
		combat-skillunit-mapchange-cleanup|combat-skillunit-death-cleanup|combat-skillunit-quit-cleanup)
			printf '%s\n' 'bash tools/ci/playerbot-combat-skillunit-smoke.sh run'
			;;
		combat-skillunit-promotion-precheck)
			printf '%s\n' 'bash tools/ci/playerbot-combat-skillunit-precheck-smoke.sh run'
			;;
		combat-pvp-woe-death-semantics)
			printf '%s\n' 'bash tools/ci/playerbot-combat-edge-smoke.sh run'
			;;
		combat-repeated-transition-stress)
			printf '%s\n' 'bash tools/ci/playerbot-combat-transition-stress.sh --runs 10'
			;;
		companion-spawn-continuity)
			printf '%s\n' 'bash tools/ci/playerbot-companion-smoke.sh run'
			;;
		behavior-social-presence)
			printf '%s\n' 'bash tools/ci/playerbot-social-behavior-smoke.sh run'
			;;
		behavior-party-support)
			printf '%s\n' 'bash tools/ci/playerbot-party-behavior-smoke.sh run'
			;;
		status-recovery-integrity)
			printf '%s\n' 'bash tools/ci/playerbot-combat-smoke.sh run'
			;;
		item-loadout-continuity)
			printf '%s\n' 'bash tools/ci/playerbot-item-smoke.sh run'
			;;
		loadout-denied-recover)
			printf '%s\n' 'bash tools/ci/playerbot-item-smoke.sh run'
			;;
		loadout-overlap-continuity)
			printf '%s\n' 'bash tools/ci/playerbot-item-overlap-stress.sh --cycles 1'
			;;
		mechanic-cleanup)
			printf '%s\n' 'bash tools/ci/playerbot-participation-smoke.sh run'
			;;
		mechanic-execution-rollback)
			printf '%s\n' 'bash tools/ci/playerbot-item-smoke.sh run'
			;;
		guild-storage-signal-integrity)
			printf '%s\n' 'bash tools/ci/playerbot-guild-storage-smoke.sh seed && bash tools/ci/playerbot-guild-storage-smoke.sh check && bash tools/ci/playerbot-guild-storage-smoke.sh clear'
			;;
		market-buyingstore-partial-fill|market-buyingstore-reopen|market-buyingstore-denial-continuity)
			printf '%s\n' 'bash tools/ci/playerbot-market-smoke.sh run'
			;;
		market-mail-delivery-integrity)
			printf '%s\n' 'bash tools/ci/playerbot-market-session-stress.sh --cycles 1'
			;;
		market-rodex-receive-attachments)
			printf '%s\n' 'bash tools/ci/playerbot-rodex-attachment-smoke.sh run'
			;;
		market-session-restart-continuity)
			printf '%s\n' 'bash tools/ci/playerbot-market-session-stress.sh --cycles 2'
			;;
		lifecycle-despawn-grace-window)
			printf '%s\n' 'bash tools/ci/playerbot-lifecycle-grace-smoke.sh run'
			;;
		lifecycle-spawn-failure-cleanup)
			printf '%s\n' 'bash tools/ci/playerbot-lifecycle-spawnfail-smoke.sh run'
			;;
		foundation-rich-gate)
			printf '%s\n' 'bash tools/ci/playerbot-foundation-smoke.sh run-rich'
			;;
		*)
			return 1
			;;
	esac
}
