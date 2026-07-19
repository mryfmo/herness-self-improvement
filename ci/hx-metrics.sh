#!/usr/bin/env bash

# @file ci/hx-metrics.sh
# @brief Print one day of harness metrics and append its audit summary.
# @description
#   Reads migration 0003 views from an injected SQLite database. The date
#   defaults to the current UTC day.
# @arg $1 db-path Migrated SQLite database.
# @option --date <YYYY-MM-DD> UTC metric date.

set -euo pipefail

usage() {
    echo "usage: ci/hx-metrics.sh <db-path> [--date YYYY-MM-DD]" >&2
    exit 2
}

[ "$#" -eq 1 ] || [ "$#" -eq 3 ] || usage
DB=$1
METRIC_DATE=$(date -u '+%F')
if [ "$#" -eq 3 ]; then
    [ "$2" = --date ] || usage
    METRIC_DATE=$3
fi
case "$METRIC_DATE" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) usage ;;
esac
[ -f "$DB" ] || {
    echo "hx-metrics: database does not exist: $DB" >&2
    exit 1
}

sqlite() {
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" \
        -cmd "PRAGMA foreign_keys=ON;" "$DB" "$1"
}

[ "$(sqlite "SELECT strftime('%F', '$METRIC_DATE');")" = "$METRIC_DATE" ] || {
    echo "hx-metrics: invalid date: $METRIC_DATE" >&2
    exit 1
}

[ "$(sqlite "
SELECT count(*) FROM sqlite_master
WHERE type='view' AND name IN (
    'hx_v_skill_daily',
    'hx_v_tool_daily',
    'hx_v_prompt_repetition_daily'
);
")" = 3 ] || {
    echo "hx-metrics: migration 0003_metric_views is required" >&2
    exit 1
}

printf 'date=%s\n[skill]\n' "$METRIC_DATE"
sqlite3 -header -column -cmd ".bail on" -cmd ".timeout 5000" "$DB" "
SELECT skill_name, run_count, success_rate, correction_rate, avg_duration_ms
FROM hx_v_skill_daily
WHERE metric_date='$METRIC_DATE'
ORDER BY skill_name;
"

printf '[tool]\n'
sqlite3 -header -column -cmd ".bail on" -cmd ".timeout 5000" "$DB" "
SELECT tool, execution_count, failure_count, failure_rate
FROM hx_v_tool_daily
WHERE metric_date='$METRIC_DATE'
ORDER BY tool;
"

printf '[prompt]\n'
sqlite3 -header -column -cmd ".bail on" -cmd ".timeout 5000" "$DB" "
SELECT repeated_prompt_count, distinct_session_count
FROM hx_v_prompt_repetition_daily
WHERE metric_date='$METRIC_DATE';
"

IFS='|' read -r skill_runs tool_events repeated_prompts <<EOF
$(sqlite "
SELECT
    (SELECT count(*) FROM hx_skill_runs WHERE date(ts)='$METRIC_DATE'),
    (SELECT count(*) FROM hx_tool_events WHERE date(ts)='$METRIC_DATE'),
    COALESCE((
        SELECT repeated_prompt_count
        FROM hx_v_prompt_repetition_daily
        WHERE metric_date='$METRIC_DATE'
    ), 0);
")
EOF

sqlite "
INSERT INTO hx_audit(ts, actor, event, ref, detail)
VALUES (
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    'hx-metrics',
    'metrics.daily',
    '$METRIC_DATE',
    '{\"date\":\"$METRIC_DATE\",\"skill_runs\":$skill_runs,\"tool_events\":$tool_events,\"repeated_prompts\":$repeated_prompts}'
);
" >/dev/null
echo "audit=metrics.daily"
