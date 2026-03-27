#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
GUILD_NAME="${GUILD_NAME:-PBG150001}"
CASTLE_ID="${CASTLE_ID:-999}"
STATE_FILE="${STATE_FILE:-/tmp/pb_guild_castle_smoke.state}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-guild-castle-smoke.sh <seed|check|clear>

Commands:
  seed   assign the configured castle to the configured guild and save prior owner to a temp state file
  check  show owned castle count for the configured guild
  clear  restore the previous owner for the configured castle if state exists, otherwise set it to 0
EOF
}

guild_id() {
	mysql -N -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT guild_id FROM guild WHERE name = '${GUILD_NAME}' LIMIT 1"
}

seed() {
	local gid prev
	gid="$(guild_id)"
	[[ -n "$gid" ]] || { echo "Guild not found: $GUILD_NAME" >&2; exit 1; }
	prev="$(mysql -N -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT guild_id FROM guild_castle WHERE castle_id = ${CASTLE_ID} LIMIT 1")"
	echo "${prev:-0}" > "$STATE_FILE"
	if [[ -n "$prev" ]]; then
		mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "UPDATE guild_castle SET guild_id = ${gid} WHERE castle_id = ${CASTLE_ID};"
	else
		mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
INSERT INTO guild_castle
  (castle_id, guild_id, economy, defense, triggerE, triggerD, nextTime, payTime, createTime,
   visibleC, visibleG0, visibleG1, visibleG2, visibleG3, visibleG4, visibleG5, visibleG6, visibleG7)
VALUES
  (${CASTLE_ID}, ${gid}, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
SQL
	fi
}

check() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
SELECT gu.name, COUNT(*) AS owned_castles
FROM guild gu
JOIN guild_castle gc ON gc.guild_id = gu.guild_id
WHERE gu.name = '${GUILD_NAME}'
GROUP BY gu.guild_id, gu.name;
SQL
}

clear() {
	local prev
	if [[ -f "$STATE_FILE" ]]; then
		prev="$(cat "$STATE_FILE")"
	else
		prev="0"
	fi
	if [[ "$prev" == "0" ]]; then
		mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DELETE FROM guild_castle WHERE castle_id = ${CASTLE_ID};"
	else
		mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "UPDATE guild_castle SET guild_id = ${prev} WHERE castle_id = ${CASTLE_ID};"
	fi
	rm -f "$STATE_FILE"
}

case "${1:-check}" in
	seed) seed ;;
	check) check ;;
	clear) clear ;;
	-h|--help|help) usage ;;
	*)
		usage
		exit 1
		;;
esac
