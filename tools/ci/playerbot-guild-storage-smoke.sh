#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${DB_NAME:-rathena}"
DB_USER="${DB_USER:-rathena}"
DB_PASS="${RATHENA_DB_PASS:-rathena_secure_2024}"
GUILD_NAME="${GUILD_NAME:-PBG150001}"
PROBE_UNIQUE_ID="${PROBE_UNIQUE_ID:-9000000000000001}"
PROBE_ITEM_ID="${PROBE_ITEM_ID:-501}"
PROBE_CHAR_ID="${PROBE_CHAR_ID:-150001}"
PROBE_CHAR_NAME="${PROBE_CHAR_NAME:-codex}"

usage() {
	cat <<EOF
Usage: bash tools/ci/playerbot-guild-storage-smoke.sh <seed|check|clear>

Commands:
  seed   insert one sentinel guild_storage row and one fresh guild_storage_log row
  check  show guild storage and recent guild log counts for the configured guild
  clear  remove sentinel probe rows only
EOF
}

guild_id_sql() {
	cat <<SQL
SELECT guild_id FROM guild WHERE name = '${GUILD_NAME}' LIMIT 1
SQL
}

seed() {
	local guild_id
	guild_id="$(mysql -N -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$(guild_id_sql)")"
	[[ -n "$guild_id" ]] || { echo "Guild not found: $GUILD_NAME" >&2; exit 1; }

	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
DELETE FROM guild_storage WHERE guild_id = ${guild_id} AND unique_id = ${PROBE_UNIQUE_ID};
INSERT INTO guild_storage
  (guild_id, nameid, amount, equip, identify, refine, attribute, card0, card1, card2, card3,
   option_id0, option_val0, option_parm0, option_id1, option_val1, option_parm1,
   option_id2, option_val2, option_parm2, option_id3, option_val3, option_parm3,
   option_id4, option_val4, option_parm4, expire_time, bound, unique_id, enchantgrade)
VALUES
  (${guild_id}, ${PROBE_ITEM_ID}, 1, 0, 1, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, ${PROBE_UNIQUE_ID}, 0);
INSERT INTO guild_storage_log
  (guild_id, time, char_id, name, nameid, amount, identify, refine, attribute, card0, card1, card2, card3,
   option_id0, option_val0, option_parm0, option_id1, option_val1, option_parm1,
   option_id2, option_val2, option_parm2, option_id3, option_val3, option_parm3,
   option_id4, option_val4, option_parm4, expire_time, unique_id, bound, enchantgrade)
VALUES
  (${guild_id}, NOW(), ${PROBE_CHAR_ID}, '${PROBE_CHAR_NAME}', ${PROBE_ITEM_ID}, 1, 1, 0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, 0, 0,
   0, 0, 0, 0, ${PROBE_UNIQUE_ID}, 0, 0);
SQL
}

check() {
	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
SELECT gu.name,
  (SELECT COUNT(*) FROM guild_storage gs WHERE gs.guild_id = gu.guild_id) AS storage_rows,
  (SELECT COUNT(*) FROM guild_storage_log gsl WHERE gsl.guild_id = gu.guild_id AND gsl.time >= DATE_SUB(NOW(), INTERVAL 15 MINUTE)) AS recent_log_rows
FROM guild gu
WHERE gu.name = '${GUILD_NAME}';
SQL
}

clear() {
	local guild_id
	guild_id="$(mysql -N -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$(guild_id_sql)")"
	[[ -n "$guild_id" ]] || { echo "Guild not found: $GUILD_NAME" >&2; exit 1; }

	mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<SQL
DELETE FROM guild_storage WHERE guild_id = ${guild_id} AND unique_id = ${PROBE_UNIQUE_ID};
DELETE FROM guild_storage_log WHERE guild_id = ${guild_id} AND unique_id = ${PROBE_UNIQUE_ID};
SQL
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
