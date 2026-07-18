#!/usr/bin/env sh

# @file ci/test_migrations.sh
# @brief Verify telemetry migrations against an isolated temporary SQLite database.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MIGRATE="$ROOT/db/migrate.sh"
UP="$ROOT/db/migrations/0001_telemetry.up.sql"
DOC="$ROOT/docs/reference/telemetry-schema.md"
DB=$(mktemp "${TMPDIR:-/tmp}/hx-telemetry.XXXXXX")
trap 'rm -f "$DB" "$DB-wal" "$DB-shm"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

query() {
    sqlite3 -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$DB" "$1"
}

assert_object() {
    type=$1
    name=$2
    expected=$3
    actual=$(query "SELECT count(*) FROM sqlite_master WHERE type='$type' AND name='$name';")
    [ "$actual" = "$expected" ] || fail "$type $name: expected $expected, got $actual"
}

[ -x "$MIGRATE" ] || fail "missing executable db/migrate.sh"
[ -f "$UP" ] || fail "missing up migration"
[ -f "$DOC" ] || fail "missing schema documentation"

"$MIGRATE" up "$DB"
"$MIGRATE" up "$DB"
[ "$("$MIGRATE" status "$DB")" = "0001_telemetry applied" ] || fail "up status"

TABLES="hx_schema_migrations hx_sessions hx_prompts hx_tool_events hx_skill_runs hx_patterns hx_audit hx_prompts_fts hx_skill_runs_fts"
TRIGGERS="hx_audit_no_update hx_audit_no_delete hx_prompts_fts_ai hx_prompts_fts_ad hx_prompts_fts_au hx_skill_runs_fts_ai hx_skill_runs_fts_ad hx_skill_runs_fts_au"
for table in $TABLES; do
    assert_object table "$table" 1
done
for trigger in $TRIGGERS; do
    assert_object trigger "$trigger" 1
done

query "
INSERT INTO hx_sessions VALUES ('s1', 'codex', 'demo', '2026-07-18T00:00:00Z', NULL, 'running');
INSERT INTO hx_prompts(session_id, ts, role, content) VALUES ('s1', '2026-07-18T00:00:01Z', 'user', 'migration smoke');
INSERT INTO hx_skill_runs(session_id, ts, skill_name, scope, outcome) VALUES ('s1', '2026-07-18T00:00:02Z', 'schema-test', 'project', 'success');
INSERT INTO hx_audit(ts, actor, event) VALUES ('2026-07-18T00:00:03Z', 'test', 'insert');
"
[ "$(query "SELECT count(*) FROM hx_prompts_fts WHERE hx_prompts_fts MATCH 'migration';")" = 1 ] || fail "prompt FTS"
[ "$(query "SELECT count(*) FROM hx_skill_runs_fts WHERE hx_skill_runs_fts MATCH 'schema';")" = 1 ] || fail "skill FTS"

if query "INSERT INTO hx_prompts(session_id, ts, role, content) VALUES ('missing', 'x', 'user', 'x');" >/dev/null 2>&1; then
    fail "orphan prompt accepted"
fi
if query "UPDATE hx_audit SET event='changed';" >/dev/null 2>&1; then
    fail "audit update accepted"
fi
if query "DELETE FROM hx_audit;" >/dev/null 2>&1; then
    fail "audit delete accepted"
fi

[ "$(query "PRAGMA journal_mode;")" = "wal" ] || fail "WAL mode"
busy_timeout=$(sqlite3 "$DB" "PRAGMA busy_timeout=5000; PRAGMA busy_timeout;" | tail -1)
[ "$busy_timeout" = 5000 ] || fail "busy_timeout"
echo "PASS: up/up, FTS5, foreign keys, append-only audit, WAL, busy_timeout"

"$MIGRATE" down "$DB"
"$MIGRATE" down "$DB"
[ "$("$MIGRATE" status "$DB")" = "0001_telemetry pending" ] || fail "down status"
assert_object table hx_schema_migrations 1
for table in hx_sessions hx_prompts hx_tool_events hx_skill_runs hx_patterns hx_audit hx_prompts_fts hx_skill_runs_fts; do
    assert_object table "$table" 0
done
for trigger in $TRIGGERS; do
    assert_object trigger "$trigger" 0
done
echo "PASS: down/down"

"$MIGRATE" up "$DB"
[ "$("$MIGRATE" status "$DB")" = "0001_telemetry applied" ] || fail "final up status"
echo "PASS: final up"

ddl_tables=$(sed -nE 's/^[[:space:]]*CREATE (VIRTUAL )?TABLE IF NOT EXISTS (hx_[a-z0-9_]+).*/\2/p' "$UP")
for table in hx_schema_migrations $ddl_tables; do
    grep -q "\`$table\`" "$DOC" || fail "$table missing from telemetry-schema.md"
done
echo "PASS: schema documentation table names"
