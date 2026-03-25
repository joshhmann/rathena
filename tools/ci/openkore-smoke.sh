#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: tools/ci/openkore-smoke.sh [--no-launch] <scenario>

Scenarios:
  login-baseline
  scheduler-status
  prontera-repopulate
  alberta-gate

Flags:
  --no-launch   Print the scenario checklist and exit without starting OpenKore
EOF
}

launch=1
scenario="${1:-scheduler-status}"

if [[ "${1:-}" == "--no-launch" ]]; then
	launch=0
	shift
	scenario="${1:-scheduler-status}"
fi

case "$scenario" in
	login-baseline)
		title="Login Baseline"
		steps=(
			"Confirm account server login"
			"Confirm character server login"
			"Confirm map-server entry into prontera"
			"Run \`pl\` and \`nl\`"
		)
		;;
	scheduler-status)
		title="Scheduler Status"
		steps=(
			"Open \`Headless Scheduler\` in Prontera"
			"Choose \`Status\`"
			"Choose \`Controller drill-down\`"
			"Inspect Prontera and Alberta controller summaries"
		)
		;;
	prontera-repopulate)
		title="Prontera Repopulation"
		steps=(
			"Open \`Headless Scheduler\` in Prontera"
			"Choose \`Start scheduler\`"
			"Run \`pl\` and confirm BotPc06 through BotPc10 appear"
		)
		;;
	alberta-gate)
		title="Alberta Gate"
		steps=(
			"Log a second observer into Alberta, or move an observer there"
			"Open \`Headless Scheduler\` in Prontera"
			"Choose \`Start scheduler\`"
			"Confirm Alberta transitions from idle to active when the gate is met"
		)
		;;
	*)
		echo "Unknown scenario: $scenario" >&2
		usage
		exit 1
		;;
esac

cat <<EOF
OpenKore Smoke Scenario: $title

Checklist:
EOF
for step in "${steps[@]}"; do
	printf '  - %s\n' "$step"
done
cat <<'EOF'

Expected harness:
  - account: codexbot
  - password: codexbot
  - control overlay: /root/testing/openkore-control-codex
  - tables overlay: /root/testing/openkore-tables-codex:/root/testing/openkore/tables
EOF

if [[ "$launch" -eq 0 ]]; then
	exit 0
fi

cd /root/testing/openkore
exec perl openkore.pl \
	--control=/root/testing/openkore-control-codex \
	--tables=/root/testing/openkore-tables-codex:/root/testing/openkore/tables \
	--interface=Console \
	--ai=off
