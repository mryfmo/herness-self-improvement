#!/usr/bin/env bash

# @file ci/test_metrics.sh
# @brief Verify the paired metric contract and daily SQLite aggregation.
# @description
#   Checks the six required documentation fields and compares metric views
#   against hand-calculated values from one synthetic day.

set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
DOC="$ROOT/docs/reference/metrics.md"
METRICS="$ROOT/ci/hx-metrics.sh"
DB=$(mktemp "${TMPDIR:-/tmp}/hx-metrics.XXXXXX")
ROWS=$(mktemp "${TMPDIR:-/tmp}/hx-metric-rows.XXXXXX")
trap 'rm -f "$DB" "$DB-wal" "$DB-shm" "$ROWS"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

query() {
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" \
        -cmd "PRAGMA foreign_keys=ON;" "$DB" "$1"
}

[ -f "$DOC" ] || fail "missing metrics documentation"
[ -x "$METRICS" ] || fail "missing executable metrics CLI"

awk '
    /<!-- metric-schema:start -->/ { in_schema=1; next }
    /<!-- metric-schema:end -->/ { in_schema=0 }
    in_schema && /^\|/ && !/^\| *---/ && !/^\| *指標名/ { print }
' "$DOC" >"$ROWS"

awk -F '|' '
    function trim(value) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        return value
    }
    BEGIN {
        expected_class["スキル別成功率"]="接地"
        expected_class["スキル別訂正率"]="接地"
        expected_class["スキル別平均所要時間"]="派生"
        expected_class["ツール別失敗率"]="派生"
        expected_class["実行件数"]="接地"
        expected_class["繰り返しプロンプト頻度"]="派生"
        expected_class["セッション多様性"]="接地"
    }
    {
        if (NF != 8) exit 10
        for (field=2; field<=7; field++) {
            if (trim($field) == "") exit 11
        }
        name=trim($2)
        counter=trim($4)
        class=trim($5)
        owner=trim($6)
        cadence=trim($7)
        if (class != "接地" && class != "派生") exit 12
        if (class != expected_class[name]) exit 17
        if (owner != "mryfmo") exit 13
        if (cadence != "四半期") exit 14
        pair[name SUBSEP counter]=1
        count++
    }
    END {
        if (count != 8) exit 15
        for (key in pair) {
            split(key, parts, SUBSEP)
            if (!pair[parts[2] SUBSEP parts[1]]) exit 16
        }
    }
' "$ROWS" || fail "metric rows must have six fields and reciprocal pairs"

for metric in \
    スキル別成功率 スキル別訂正率 スキル別平均所要時間 \
    ツール別失敗率 実行件数 繰り返しプロンプト頻度 セッション多様性
do
    grep -q "| $metric |" "$ROWS" || fail "missing metric: $metric"
done
echo "PASS: all metric rows have the six required attributes and reciprocal pairs"

"$ROOT/db/migrate.sh" up "$DB"
for view in hx_v_skill_daily hx_v_tool_daily hx_v_prompt_repetition_daily; do
    [ "$(query "SELECT count(*) FROM sqlite_master WHERE type='view' AND name='$view';")" = 1 ] ||
        fail "missing view: $view"
done

query "
INSERT INTO hx_sessions VALUES
    ('s1', 'codex', 'demo', '2026-07-18T00:00:00Z', NULL, 'completed'),
    ('s2', 'codex', 'demo', '2026-07-18T00:00:00Z', NULL, 'completed'),
    ('s3', 'codex', 'demo', '2026-07-18T00:00:00Z', NULL, 'completed');

INSERT INTO hx_skill_runs(session_id, ts, skill_name, scope, outcome, corrected) VALUES
    ('s1', '2026-07-18T01:00:00Z', 'alpha', 'project', 'success', 1),
    ('s1', '2026-07-18T02:00:00Z', 'alpha', 'project', 'success', 0),
    ('s2', '2026-07-18T03:00:00Z', 'alpha', 'project', 'failure', 0),
    ('s3', '2026-07-18T04:00:00Z', 'beta', 'project', 'success', 1),
    ('s3', '2026-07-19T04:00:00Z', 'noise', 'project', 'failure', 0);

INSERT INTO hx_tool_events(session_id, ts, tool, status, duration_ms) VALUES
    ('s1', '2026-07-18T01:00:00Z', 'Skill', 'success', 100),
    ('s1', '2026-07-18T02:00:00Z', 'Skill', 'success', 200),
    ('s2', '2026-07-18T03:00:00Z', 'Skill', 'failure', NULL),
    ('s3', '2026-07-18T04:00:00Z', 'Skill', 'success', 400),
    ('s1', '2026-07-18T05:00:00Z', 'Bash', 'success', 10),
    ('s2', '2026-07-18T06:00:00Z', 'Bash', 'failure', 20),
    ('s3', '2026-07-18T07:00:00Z', 'Bash', 'failure', 30),
    ('s1', '2026-07-18T08:00:00Z', 'Read', 'success', 5),
    ('s2', '2026-07-18T09:00:00Z', 'Read', 'success', 5);

INSERT INTO hx_prompts(session_id, ts, role, content) VALUES
    ('s1', '2026-07-18T10:00:00Z', 'user', 'repeat'),
    ('s1', '2026-07-18T10:01:00Z', 'user', 'repeat'),
    ('s2', '2026-07-18T10:02:00Z', 'user', 'repeat'),
    ('s3', '2026-07-18T10:03:00Z', 'user', 'again'),
    ('s3', '2026-07-18T10:04:00Z', 'user', 'again'),
    ('s2', '2026-07-18T10:05:00Z', 'user', 'solo'),
    ('s1', '2026-07-19T10:00:00Z', 'user', 'noise');
"

skill=$(query "
SELECT skill_name, run_count, success_count, printf('%.6f', success_rate),
       correction_count, printf('%.6f', correction_rate),
       printf('%.1f', avg_duration_ms)
FROM hx_v_skill_daily
WHERE metric_date='2026-07-18'
ORDER BY skill_name;
")
[ "$skill" = "$(printf '%s\n' \
    'alpha|3|2|0.666667|1|0.333333|150.0' \
    'beta|1|1|1.000000|1|1.000000|400.0')" ] ||
    fail "skill metrics differ from hand calculation"

tools=$(query "
SELECT tool, execution_count, failure_count, printf('%.6f', failure_rate)
FROM hx_v_tool_daily
WHERE metric_date='2026-07-18'
ORDER BY tool;
")
[ "$tools" = "$(printf '%s\n' \
    'Bash|3|2|0.666667' \
    'Read|2|0|0.000000' \
    'Skill|4|1|0.250000')" ] ||
    fail "tool metrics differ from hand calculation"

[ "$(query "
SELECT metric_date, repeated_prompt_count, distinct_session_count
FROM hx_v_prompt_repetition_daily
WHERE metric_date='2026-07-18';
")" = '2026-07-18|3|3' ] ||
    fail "prompt metrics differ from hand calculation"

report=$("$METRICS" "$DB" --date 2026-07-18)
case "$report" in
    *"[skill]"*"[tool]"*"[prompt]"*) ;;
    *) fail "report sections are missing" ;;
esac
[ "$(query "
SELECT count(*) FROM hx_audit
WHERE event='metrics.daily' AND ref='2026-07-18'
  AND instr(detail, '\"skill_runs\":4') > 0
  AND instr(detail, '\"repeated_prompts\":3') > 0;
")" = 1 ] || fail "daily audit summary"

if "$METRICS" "$DB" --date 2026-7-18 >/dev/null 2>&1; then
    fail "invalid date accepted"
fi
if "$METRICS" "$DB" --date 2026-02-30 >/dev/null 2>&1; then
    fail "invalid calendar date accepted"
fi

echo "PASS: metric views, daily report, and audit summary match hand calculation"
