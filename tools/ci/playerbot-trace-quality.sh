#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/playerbot-smoke-common.sh"
PB_SMOKE_LABEL="playerbot-trace-quality"

SINCE_MINUTES=180

usage() {
	cat <<'EOF'
Usage: bash tools/ci/playerbot-trace-quality.sh [options]

Options:
  --since MINUTES   Lookback window in minutes (default: 180)
  -h, --help        Show this help

Checks:
  1) Failed/denied/aborted trace rows must include error_code + error_detail.
  2) Interrupt recovery audit rows must include a non-empty detail.

This script is a quality gate for trace/audit debuggability; it does not change
runtime state.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--since)
			SINCE_MINUTES="${2:?missing value for --since}"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			usage
			exit 1
			;;
	esac
done

if ! [[ "$SINCE_MINUTES" =~ ^[0-9]+$ ]] || (( SINCE_MINUTES < 1 )); then
	echo "--since must be a positive integer" >&2
	exit 1
fi

cd "$REPO_ROOT"

read -r fail_rows missing_error_code_rows missing_error_detail_rows failed_rows_with_none_reason denied_rows_with_none_reason interrupt_audit_rows missing_interrupt_detail_rows < <(
	pb_smoke_sql_heredoc <<EOF
SELECT
  COALESCE(SUM(CASE WHEN \`result\` IN ('aborted','denied','fatal','timeout','desynced') THEN 1 ELSE 0 END), 0) AS fail_rows,
  COALESCE(SUM(CASE WHEN \`result\` IN ('aborted','denied','fatal','timeout','desynced') AND COALESCE(\`error_code\`,'') = '' THEN 1 ELSE 0 END), 0) AS missing_error_code_rows,
  COALESCE(SUM(CASE WHEN \`result\` IN ('aborted','denied','fatal','timeout','desynced') AND COALESCE(\`error_detail\`,'') = '' THEN 1 ELSE 0 END), 0) AS missing_error_detail_rows,
  COALESCE(SUM(CASE WHEN \`action\` LIKE '%.failed' AND \`reason_code\` = 'none' THEN 1 ELSE 0 END), 0) AS failed_rows_with_none_reason,
  COALESCE(SUM(CASE WHEN \`result\` = 'denied' AND \`reason_code\` = 'none' THEN 1 ELSE 0 END), 0) AS denied_rows_with_none_reason,
  (
    SELECT COUNT(*)
    FROM \`bot_recovery_audit\`
    WHERE UNIX_TIMESTAMP() - \`ts\` <= ${SINCE_MINUTES} * 60
      AND \`action\` = 'interrupt'
  ) AS interrupt_audit_rows,
  (
    SELECT COUNT(*)
    FROM \`bot_recovery_audit\`
    WHERE UNIX_TIMESTAMP() - \`ts\` <= ${SINCE_MINUTES} * 60
      AND \`action\` = 'interrupt'
      AND COALESCE(\`detail\`,'') = ''
  ) AS missing_interrupt_detail_rows
FROM \`bot_trace_event\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= ${SINCE_MINUTES} * 60;
EOF
)

printf '[%s] window=%sm fail_rows=%s missing_error_code=%s missing_error_detail=%s failed_reason_none=%s denied_reason_none=%s\n' \
	"$PB_SMOKE_LABEL" "$SINCE_MINUTES" "$fail_rows" "$missing_error_code_rows" "$missing_error_detail_rows" "$failed_rows_with_none_reason" "$denied_rows_with_none_reason"
printf '[%s] interrupt_audits=%s missing_interrupt_detail=%s\n' \
	"$PB_SMOKE_LABEL" "$interrupt_audit_rows" "$missing_interrupt_detail_rows"

failures=0
if (( fail_rows > 0 && missing_error_code_rows > 0 )); then
	printf '[%s] failed rows missing error_code: %s\n' "$PB_SMOKE_LABEL" "$missing_error_code_rows" >&2
	failures=$((failures + 1))
fi
if (( fail_rows > 0 && missing_error_detail_rows > 0 )); then
	printf '[%s] failed rows missing error_detail: %s\n' "$PB_SMOKE_LABEL" "$missing_error_detail_rows" >&2
	failures=$((failures + 1))
fi
if (( failed_rows_with_none_reason > 0 )); then
	printf '[%s] failed rows with reason_code=none: %s\n' "$PB_SMOKE_LABEL" "$failed_rows_with_none_reason" >&2
	failures=$((failures + 1))
fi
if (( denied_rows_with_none_reason > 0 )); then
	printf '[%s] denied rows with reason_code=none: %s\n' "$PB_SMOKE_LABEL" "$denied_rows_with_none_reason" >&2
	failures=$((failures + 1))
fi
if (( interrupt_audit_rows > 0 && missing_interrupt_detail_rows > 0 )); then
	printf '[%s] interrupt audit rows missing detail: %s\n' "$PB_SMOKE_LABEL" "$missing_interrupt_detail_rows" >&2
	failures=$((failures + 1))
fi

printf '\n[%s] top failure reasons (trace)\n' "$PB_SMOKE_LABEL"
pb_smoke_sql_heredoc <<EOF
SELECT \`phase\`, \`action\`, \`reason_code\`, \`result\`, COUNT(*) AS \`rows\`
FROM \`bot_trace_event\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= ${SINCE_MINUTES} * 60
  AND \`result\` IN ('aborted','denied','fatal','timeout','desynced')
GROUP BY \`phase\`, \`action\`, \`reason_code\`, \`result\`
ORDER BY \`rows\` DESC
LIMIT 20;
EOF

printf '\n[%s] top interrupt details (audit)\n' "$PB_SMOKE_LABEL"
pb_smoke_sql_heredoc <<EOF
SELECT \`scope\`, \`action\`, \`result\`, \`detail\`, COUNT(*) AS \`rows\`
FROM \`bot_recovery_audit\`
WHERE UNIX_TIMESTAMP() - \`ts\` <= ${SINCE_MINUTES} * 60
  AND \`action\` = 'interrupt'
GROUP BY \`scope\`, \`action\`, \`result\`, \`detail\`
ORDER BY \`rows\` DESC
LIMIT 20;
EOF

if (( failures > 0 )); then
	printf '\n[%s] trace quality check failed with %d issue(s).\n' "$PB_SMOKE_LABEL" "$failures" >&2
	exit 1
fi

printf '\n[%s] trace quality check passed.\n' "$PB_SMOKE_LABEL"
