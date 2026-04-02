#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCENARIO_CATALOG="$REPO_ROOT/tools/ci/playerbot-scenario-catalog.sh"

if [[ ! -r "$SCENARIO_CATALOG" ]]; then
	echo "Missing scenario catalog: $SCENARIO_CATALOG" >&2
	exit 1
fi

# shellcheck disable=SC1090
source "$SCENARIO_CATALOG"

RAW=0
NO_COLOR=0

if [[ "${1:-}" == "--raw" ]]; then
	RAW=1
	shift
fi

if [[ "${1:-}" == "--no-color" ]]; then
	NO_COLOR=1
	shift
fi

if [[ "${1:-}" == "--color" ]]; then
	NO_COLOR=0
	shift
fi

if [[ "${1:-}" == "" ]]; then
	set -- list
fi

if [[ "$NO_COLOR" -eq 1 || ! -t 1 ]]; then
	C_RESET=''
	C_BOLD=''
	C_DIM=''
	C_GREEN=''
	C_YELLOW=''
	C_RED=''
	C_CYAN=''
else
	C_RESET=$'\033[0m'
	C_BOLD=$'\033[1m'
	C_DIM=$'\033[2m'
	C_GREEN=$'\033[32m'
	C_YELLOW=$'\033[33m'
	C_RED=$'\033[31m'
	C_CYAN=$'\033[36m'
fi

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-scenario.sh [--raw] [--no-color] <command> [scenario]

Commands:
  list                 List the current scenario catalog
  show <scenario>      Show the scenario brief, checklist, and notes
  describe <scenario>  Print machine-readable key=value metadata
  checklist <scenario> Print the checklist for a scenario
  template [name]      Print a copy/paste scenario stub for a new scenario
  run <scenario>      Print the scenario runbook and mention launch status

Current catalog:
  combat-baseline
  combat-skillunit-mapchange-cleanup
  combat-skillunit-death-cleanup
  combat-skillunit-quit-cleanup
  combat-skillunit-promotion-precheck
  combat-repeated-transition-stress
  behavior-social-presence
  behavior-party-support
  behavior-merchant-economy
  behavior-combat-selection
  status-continuity
  status-death-cleanup
  status-map-continuity
  status-respawn-reconcile
  death-respawn
  status-recovery-integrity
  item-loadout-continuity
  loadout-denied-recover
  loadout-overlap-continuity
  mechanic-cleanup
  mechanic-execution-rollback
  market-buyingstore-partial-fill
  market-buyingstore-reopen
  market-buyingstore-denial-continuity
  market-mail-delivery-integrity
  market-session-restart-continuity
  foundation-rich-gate
EOF
}

scenario_exists() {
	local scenario="${1:-}"
	[[ -n "$scenario" ]] || return 1
	playerbot_scenario_title "$scenario" >/dev/null 2>&1
}

print_heading() {
	local title="${1:-}"
	printf '%b%s%b\n' "${C_BOLD}${C_CYAN}" "$title" "$C_RESET"
}

print_list() {
	local id title phase kind purpose
	if [[ "$RAW" -eq 1 ]]; then
		printf 'scenario_id\ttitle\tphase\tkind\tpurpose\n'
		while IFS= read -r id; do
			title="$(playerbot_scenario_title "$id")"
			phase="$(playerbot_scenario_phase "$id")"
			kind="$(playerbot_scenario_kind "$id")"
			purpose="$(playerbot_scenario_purpose "$id" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//')"
			printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$title" "$phase" "$kind" "$purpose"
		done < <(playerbot_scenario_ids)
		return 0
	fi

	print_heading "Playerbot Scenario Catalog"
	printf '%-26s %-24s %-12s %-10s %s\n' "SCENARIO" "TITLE" "PHASE" "KIND" "PURPOSE"
	printf '%s\n' "-----------------------------------------------------------------------------------------------"
	while IFS= read -r id; do
		title="$(playerbot_scenario_title "$id")"
		phase="$(playerbot_scenario_phase "$id")"
		kind="$(playerbot_scenario_kind "$id")"
		purpose="$(playerbot_scenario_purpose "$id" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//')"
		printf '%-26s %-24s %-12s %-10s %s\n' "$id" "$title" "$phase" "$kind" "$purpose"
	done < <(playerbot_scenario_ids)
}

print_describe() {
	local scenario="${1:-}"
	if ! scenario_exists "$scenario"; then
		echo "Unknown scenario: $scenario" >&2
		exit 1
	fi

	local title phase kind launcher purpose steps_count
	title="$(playerbot_scenario_title "$scenario")"
	phase="$(playerbot_scenario_phase "$scenario")"
	kind="$(playerbot_scenario_kind "$scenario")"
	launcher="$(playerbot_scenario_launcher "$scenario" || true)"
	purpose="$(playerbot_scenario_purpose "$scenario" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//')"
	steps_count="$(playerbot_scenario_steps "$scenario" | grep -c '^- ' || true)"

	printf 'scenario_id=%s\n' "$scenario"
	printf 'scenario_title=%s\n' "$title"
	printf 'scenario_phase=%s\n' "$phase"
	printf 'scenario_kind=%s\n' "$kind"
	printf 'scenario_launcher=%s\n' "${launcher:-none}"
	printf 'scenario_steps=%s\n' "$steps_count"
	printf 'scenario_purpose=%s\n' "$purpose"
}

print_show() {
	local scenario="${1:-}"
	if ! scenario_exists "$scenario"; then
		echo "Unknown scenario: $scenario" >&2
		exit 1
	fi

	local title phase kind launcher
	title="$(playerbot_scenario_title "$scenario")"
	phase="$(playerbot_scenario_phase "$scenario")"
	kind="$(playerbot_scenario_kind "$scenario")"
	launcher="$(playerbot_scenario_launcher "$scenario" || true)"

	print_heading "$title"
	printf 'Scenario: %s\n' "$scenario"
	printf 'Phase: %s\n' "$phase"
	printf 'Kind: %s\n' "$kind"
	printf 'Launcher: %s\n' "${launcher:-none}"
	printf '\nPurpose:\n'
	printf '%s\n' "$(playerbot_scenario_purpose "$scenario")"
	printf '\nPrerequisites:\n'
	printf '%s\n' "$(playerbot_scenario_prereqs "$scenario")"
	printf '\nChecklist:\n'
	printf '%s\n' "$(playerbot_scenario_steps "$scenario")"
	printf '\nExpected signals:\n'
	printf '%s\n' "$(playerbot_scenario_expected "$scenario")"
	printf '\nNotes:\n'
	printf '%s\n' "$(playerbot_scenario_notes "$scenario")"
}

print_checklist() {
	local scenario="${1:-}"
	if ! scenario_exists "$scenario"; then
		echo "Unknown scenario: $scenario" >&2
		exit 1
	fi
	printf '%s\n' "$(playerbot_scenario_steps "$scenario")"
}

print_template() {
	local scenario="${1:-combat-baseline}"
	cat <<EOF
playerbot_scenario_title() {
	case "\${1:-}" in
		$scenario) printf '%s\n' 'Human-readable title' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_phase() {
	case "\${1:-}" in
		$scenario) printf '%s\n' '<phase>' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_kind() {
	case "\${1:-}" in
		$scenario) printf '%s\n' 'skeleton' ;;
		*) return 1 ;;
	esac
}

playerbot_scenario_purpose() {
	case "\${1:-}" in
		$scenario)
			cat <<'EOF2'
One-paragraph purpose statement.
EOF2
			;;
		*) return 1 ;;
	esac
}

playerbot_scenario_prereqs() {
	case "\${1:-}" in
		$scenario)
			cat <<'EOF2'
- prerequisite one
- prerequisite two
EOF2
			;;
		*) return 1 ;;
	esac
}

playerbot_scenario_steps() {
	case "\${1:-}" in
		$scenario)
			cat <<'EOF2'
- step one
- step two
EOF2
			;;
		*) return 1 ;;
	esac
}

playerbot_scenario_expected() {
	case "\${1:-}" in
		$scenario)
			cat <<'EOF2'
- expected signal one
- expected signal two
EOF2
			;;
		*) return 1 ;;
	esac
}

playerbot_scenario_launcher() {
	case "\${1:-}" in
		$scenario)
			printf '%s\n' ''
			;;
		*) return 1 ;;
	esac
}
EOF
}

run() {
	local scenario="${1:-}"
	if ! scenario_exists "$scenario"; then
		echo "Unknown scenario: $scenario" >&2
		exit 1
	fi

	print_show "$scenario"
	printf '\n'
	printf '%bRun status%b\n' "${C_BOLD}${C_YELLOW}" "${C_RESET}"
	local launcher
	launcher="$(playerbot_scenario_launcher "$scenario" || true)"
	if [[ -n "$launcher" ]]; then
		printf 'Repo-local launcher available:\n'
		printf '%s\n' "$launcher"
	else
		printf 'This scenario is currently a skeleton definition only.\n'
		printf 'There is no automated runtime launcher yet; use this as the canonical runbook for future frontier work.\n'
	fi
}

main() {
	case "${1:-list}" in
		list) shift; print_list ;;
		show) shift; print_show "${1:-}" ;;
		describe) shift; print_describe "${1:-}" ;;
		checklist) shift; print_checklist "${1:-}" ;;
		template) shift; print_template "${1:-combat-baseline}" ;;
		run) shift; run "${1:-}" ;;
		-h|--help|help) usage ;;
		*)
			usage
			exit 1
			;;
	esac
}

main "$@"
