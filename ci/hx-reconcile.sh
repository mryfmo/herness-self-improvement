#!/usr/bin/env sh

# @file ci/hx-reconcile.sh
# @brief Reconcile one UTC day of telemetry and ledger event counts.
# @description
#   Records the first daily snapshot in hx_audit. Later runs compare raw hx_
#   rows with that snapshot and append one mismatch per distinct actual value.
# @arg $1 db-path Migrated SQLite database.
# @option --date <YYYY-MM-DD> UTC date; defaults to the current UTC day.

set -eu

usage() {
    echo "usage: ci/hx-reconcile.sh <db-path> [--date YYYY-MM-DD]" >&2
    exit 2
}

[ "$#" -eq 1 ] || [ "$#" -eq 3 ] || usage
DB=$1
RECONCILE_DATE=$(date -u '+%F')
if [ "$#" -eq 3 ]; then
    [ "$2" = --date ] || usage
    RECONCILE_DATE=$3
fi
case "$RECONCILE_DATE" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) usage ;;
esac
[ -f "$DB" ] || {
    echo "hx-reconcile: database does not exist: $DB" >&2
    exit 1
}

sqlite() {
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" \
        -cmd "PRAGMA foreign_keys=ON;" "$DB" "$1"
}

[ "$(sqlite "SELECT strftime('%F', '$RECONCILE_DATE');")" = "$RECONCILE_DATE" ] || {
    echo "hx-reconcile: invalid date: $RECONCILE_DATE" >&2
    exit 1
}

[ "$(sqlite "
SELECT count(*) FROM sqlite_master
WHERE type='table' AND name IN (
    'hx_sessions', 'hx_prompts', 'hx_tool_events', 'hx_skill_runs',
    'hx_audit', 'hx_tasks', 'hx_task_messages'
);
")" = 7 ] || {
    echo "hx-reconcile: telemetry and ledger migrations are required" >&2
    exit 1
}

current=$(sqlite "
SELECT json_object(
    'session_start', (SELECT count(*) FROM hx_sessions WHERE date(started_at)='$RECONCILE_DATE'),
    'prompt_submit', (SELECT count(*) FROM hx_prompts WHERE date(ts)='$RECONCILE_DATE'),
    'post_tool_use', (SELECT count(*) FROM hx_tool_events WHERE date(ts)='$RECONCILE_DATE' AND tool <> 'subagent'),
    'stop', (SELECT count(*) FROM hx_sessions WHERE date(ended_at)='$RECONCILE_DATE'),
    'subagent_stop', (SELECT count(*) FROM hx_tool_events WHERE date(ts)='$RECONCILE_DATE' AND tool='subagent'),
    'skill_run', (SELECT count(*) FROM hx_skill_runs WHERE date(ts)='$RECONCILE_DATE'),
    'correction', (SELECT count(*) FROM hx_skill_runs WHERE date(ts)='$RECONCILE_DATE' AND corrected=1),
    'metrics_daily', (SELECT count(*) FROM hx_audit WHERE event='metrics.daily' AND ref='$RECONCILE_DATE'),
    'failures_recovered', (SELECT count(*) FROM hx_audit WHERE event='telemetry.failures.recovered' AND date(ts)='$RECONCILE_DATE'),
    'task_rows', (SELECT count(*) FROM hx_tasks WHERE date(updated_at)='$RECONCILE_DATE'),
    'task_messages', (SELECT count(*) FROM hx_task_messages WHERE date(ts)='$RECONCILE_DATE')
);
")
baseline=$(sqlite "
SELECT detail FROM hx_audit
WHERE event='telemetry.reconcile' AND ref='$RECONCILE_DATE'
ORDER BY id DESC LIMIT 1;
")

if [ -z "$baseline" ]; then
    sqlite "
INSERT INTO hx_audit(ts, actor, event, ref, detail)
VALUES (
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    'hx-reconcile',
    'telemetry.reconcile',
    '$RECONCILE_DATE',
    '$current'
);
" >/dev/null
    echo "date=$RECONCILE_DATE status=recorded"
    exit 0
fi

if [ "$baseline" = "$current" ]; then
    echo "date=$RECONCILE_DATE status=matched"
    exit 0
fi

mismatch=$(sqlite "SELECT json_object('expected', json('$baseline'), 'actual', json('$current'));")
sqlite "
INSERT INTO hx_audit(ts, actor, event, ref, detail)
SELECT
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    'hx-reconcile',
    'telemetry.reconcile.mismatch',
    '$RECONCILE_DATE',
    '$mismatch'
WHERE NOT EXISTS (
    SELECT 1 FROM hx_audit
    WHERE event='telemetry.reconcile.mismatch'
      AND ref='$RECONCILE_DATE'
      AND detail='$mismatch'
);
" >/dev/null
echo "date=$RECONCILE_DATE status=mismatch"
exit 1
