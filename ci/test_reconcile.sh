#!/usr/bin/env sh

# @file ci/test_reconcile.sh
# @brief Verify daily telemetry reconciliation and mismatch deduplication.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
RECONCILE="$ROOT/ci/hx-reconcile.sh"
DOC="$ROOT/docs/reference/telemetry-schema.md"
WORKFLOW="$ROOT/.github/workflows/ci.yml"
DB=$(mktemp "${TMPDIR:-/tmp}/hx-reconcile.XXXXXX")
trap 'rm -f "$DB" "$DB-wal" "$DB-shm"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

query() {
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" \
        -cmd "PRAGMA foreign_keys=ON;" "$DB" "$1"
}

[ -x "$RECONCILE" ] || fail "missing executable reconcile CLI"

"$ROOT/db/migrate.sh" up "$DB"
query "
INSERT INTO hx_sessions VALUES
    ('s1', 'codex', 'demo', '2026-07-18T00:00:00Z', '2026-07-18T01:00:00Z', 'completed'),
    ('s2', 'codex', 'demo', '2026-07-18T02:00:00Z', NULL, 'running');
INSERT INTO hx_prompts(session_id, ts, role, content) VALUES
    ('s1', '2026-07-18T00:10:00Z', 'user', 'one'),
    ('s2', '2026-07-18T02:10:00Z', 'user', 'two');
INSERT INTO hx_tool_events(session_id, ts, tool, status) VALUES
    ('s1', '2026-07-18T00:20:00Z', 'Bash', 'success'),
    ('s1', '2026-07-18T00:30:00Z', 'Skill', 'success'),
    ('s2', '2026-07-18T02:20:00Z', 'subagent', 'success');
INSERT INTO hx_skill_runs(session_id, ts, skill_name, scope, outcome, corrected)
VALUES ('s1', '2026-07-18T00:30:00Z', 'demo', 'project', 'success', 1);
INSERT INTO hx_audit(ts, actor, event, ref, detail) VALUES
    ('2026-07-19T00:00:00Z', 'hx-metrics', 'metrics.daily', '2026-07-18', '{}'),
    ('2026-07-18T03:00:00Z', 'hx-telemetry', 'telemetry.failures.recovered', 's1', '{\"failures\":1}');
INSERT INTO hx_tasks(
    task_id, idempotency_key, state, owner, workplan_ref, branch,
    done_criteria, updated_at
) VALUES
    ('t1', 'k1', 'running', 'worker', 'P1', 'b1', 'done', '2026-07-18T04:00:00Z'),
    ('t2', 'k2', 'queued', NULL, 'P1', 'b2', 'done', '2026-07-18T05:00:00Z');
INSERT INTO hx_task_messages(task_id, ts, kind, payload) VALUES
    ('t1', '2026-07-18T04:00:00Z', 'task.assign', 'one'),
    ('t1', '2026-07-18T04:10:00Z', 'task.progress', 'two'),
    ('t2', '2026-07-18T05:00:00Z', 'task.assign', 'three');
"

output=$("$RECONCILE" "$DB" --date 2026-07-18)
[ "$output" = "date=2026-07-18 status=recorded" ] || fail "first reconcile output"
[ "$(query "
SELECT json_extract(detail, '$.session_start') || '|' ||
       json_extract(detail, '$.prompt_submit') || '|' ||
       json_extract(detail, '$.post_tool_use') || '|' ||
       json_extract(detail, '$.stop') || '|' ||
       json_extract(detail, '$.subagent_stop') || '|' ||
       json_extract(detail, '$.skill_run') || '|' ||
       json_extract(detail, '$.correction') || '|' ||
       json_extract(detail, '$.metrics_daily') || '|' ||
       json_extract(detail, '$.failures_recovered') || '|' ||
       json_extract(detail, '$.task_rows') || '|' ||
       json_extract(detail, '$.task_messages')
FROM hx_audit
WHERE event='telemetry.reconcile' AND ref='2026-07-18';
")" = "2|2|2|1|1|1|1|1|1|2|3" ] || fail "reconcile counts"
echo "PASS: synthetic counts recorded"

query "DELETE FROM hx_prompts WHERE id=(SELECT max(id) FROM hx_prompts);"
if "$RECONCILE" "$DB" --date 2026-07-18 >"$DB.out"; then
    fail "missing prompt was not detected"
fi
[ "$(cat "$DB.out")" = "date=2026-07-18 status=mismatch" ] || fail "mismatch output"
[ "$(query "
SELECT json_extract(detail, '$.expected.prompt_submit') || '|' ||
       json_extract(detail, '$.actual.prompt_submit')
FROM hx_audit
WHERE event='telemetry.reconcile.mismatch' AND ref='2026-07-18';
")" = "2|1" ] || fail "mismatch detail"
echo "PASS: missing raw event detected"

if "$RECONCILE" "$DB" --date 2026-07-18 >/dev/null; then
    fail "repeated mismatch returned success"
fi
[ "$(query "
SELECT count(*) FROM hx_audit
WHERE event='telemetry.reconcile.mismatch' AND ref='2026-07-18';
")" = 1 ] || fail "duplicate mismatch"
echo "PASS: repeated mismatch is idempotent"

if "$RECONCILE" "$DB" --date 2026-02-30 >/dev/null 2>&1; then
    fail "invalid calendar date accepted"
fi
grep -q 'F3-T3' "$DOC" || fail "local nightly handoff is undocumented"
grep -q 'ci/test_reconcile.sh' "$WORKFLOW" || fail "reconcile test is missing from CI"
echo "PASS: invalid date rejected and local scheduling premise documented"
