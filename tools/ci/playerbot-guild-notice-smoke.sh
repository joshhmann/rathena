#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-rathena}"
GUILD_NAME="${GUILD_NAME:-PBG150001}"
NOTICE1="${NOTICE1:-Playerbot guild notice probe}"
NOTICE2="${NOTICE2:-Scheduler demand should see this.}"

usage() {
	cat <<'EOF'
Usage: tools/ci/playerbot-guild-notice-smoke.sh <clear|seed|check>

Commands:
  clear   Reset guild notice text for the target guild
  seed    Set sentinel guild notice text for the target guild
  check   Print the current notice signal count for the target guild
EOF
}

cmd="${1:-check}"

case "$cmd" in
	clear)
		mysql -uroot -D "$DB_NAME" -e \
			"UPDATE \`guild\` SET \`mes1\` = '', \`mes2\` = '' WHERE \`name\` = '$GUILD_NAME';"
		echo "cleared guild notice for $GUILD_NAME"
		;;
	seed)
		mysql -uroot -D "$DB_NAME" -e \
			"UPDATE \`guild\` SET \`mes1\` = '$NOTICE1', \`mes2\` = '$NOTICE2' WHERE \`name\` = '$GUILD_NAME';"
		echo "seeded guild notice for $GUILD_NAME"
		;;
	check)
		mysql -uroot -N -B -D "$DB_NAME" -e \
			"SELECT \`name\`, (\`mes1\` <> '' OR \`mes2\` <> '') AS notice_present, \`mes1\`, \`mes2\` FROM \`guild\` WHERE \`name\` = '$GUILD_NAME';"
		;;
	*)
		usage >&2
		exit 1
		;;
esac
