#!/usr/bin/env sh

# @file ci/test_task_ledger.sh
# @brief Verify the task ledger migration and CLI against an isolated SQLite database.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MIGRATE="$ROOT/db/migrate.sh"
CLI="$ROOT/db/hx-task.sh"
DOC="$ROOT/docs/reference/telemetry-schema.md"
DB=$(mktemp "${TMPDIR:-/tmp}/hx-task-ledger.XXXXXX")
trap 'rm -f "$DB" "$DB-wal" "$DB-shm"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

query() {
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$DB" "$1"
}

state() {
    query "SELECT state FROM hx_tasks WHERE task_id='$1';"
}

assert_state() {
    actual=$(state "$1")
    [ "$actual" = "$2" ] || fail "$1 state: expected $2, got $actual"
}

expect_fail() {
    label=$1
    shift
    if "$@" >/dev/null 2>&1; then
        fail "$label succeeded"
    fi
}

create_task() {
    "$CLI" "$DB" create "$1" P1-F1-T4 "f1-t4/$1" "complete $1" "${2:-2}"
}

[ -x "$MIGRATE" ] || fail "missing executable db/migrate.sh"
[ -x "$CLI" ] || fail "missing executable db/hx-task.sh"
[ -f "$DOC" ] || fail "missing schema documentation"

"$MIGRATE" up "$DB"
"$MIGRATE" up "$DB"
[ "$(query "SELECT count(*) FROM hx_schema_migrations;")" = 2 ] || fail "migration ledger"
for object in hx_tasks hx_task_messages hx_tasks_state_updated_idx hx_task_messages_task_ts_idx hx_tasks_state_transition; do
    [ "$(query "SELECT count(*) FROM sqlite_master WHERE name='$object';")" = 1 ] || fail "missing $object"
    grep -q "\`$object\`" "$DOC" || fail "$object missing from telemetry-schema.md"
done

"$CLI" --help >/dev/null
"$CLI" "$DB" --help >/dev/null

done_id=$(create_task done-path)
"$CLI" "$DB" claim "$done_id" worker-a >/dev/null
"$CLI" "$DB" start "$done_id" >/dev/null
"$CLI" "$DB" progress "$done_id" "tests running" >/dev/null
"$CLI" "$DB" "done" "$done_id" "PR ready" >/dev/null
assert_state "$done_id" "done"

failed_id=$(create_task failed-path)
"$CLI" "$DB" claim "$failed_id" worker-b >/dev/null
"$CLI" "$DB" start "$failed_id" >/dev/null
"$CLI" "$DB" fail "$failed_id" "test failed" >/dev/null
assert_state "$failed_id" failed

blocked_id=$(create_task blocked-path)
"$CLI" "$DB" claim "$blocked_id" worker-c >/dev/null
"$CLI" "$DB" start "$blocked_id" >/dev/null
"$CLI" "$DB" block "$blocked_id" "awaiting approval" >/dev/null
assert_state "$blocked_id" blocked

queued_id=$(create_task invalid-queued)
expect_fail "queued to running" "$CLI" "$DB" start "$queued_id"
expect_fail "direct queued to running" query "UPDATE hx_tasks SET state='running' WHERE task_id='$queued_id';"
expect_fail "done to claimed" "$CLI" "$DB" claim "$done_id" worker-d
expect_fail "invalid message kind" query "INSERT INTO hx_task_messages(task_id, ts, kind, payload) VALUES ('$queued_id', 'x', 'bad.kind', 'x');"
echo "PASS: normal terminal paths and invalid transitions"

first_id=$(create_task same-key)
second_id=$("$CLI" "$DB" create same-key P1-F1-T4 f1-t4/same "same criteria")
[ "$first_id" = "$second_id" ] || fail "idempotent create returned a new task"
[ "$(query "SELECT count(*) FROM hx_tasks WHERE idempotency_key='same-key';")" = 1 ] || fail "duplicate task"
[ "$(query "SELECT count(*) FROM hx_task_messages WHERE task_id='$first_id' AND kind='task.assign';")" = 1 ] || fail "duplicate assignment message"
quoted_id=$("$CLI" "$DB" create "key'quoted" P1-F1-T4 "branch'quoted" "criteria 'quoted'")
[ -n "$quoted_id" ] || fail "quoted create"
echo "PASS: idempotent create and SQL quoting"

requeue_id=$(create_task requeue 2)
"$CLI" "$DB" claim "$requeue_id" worker-r >/dev/null
"$CLI" "$DB" start "$requeue_id" >/dev/null
query "UPDATE hx_tasks SET updated_at='2000-01-01T00:00:00Z' WHERE task_id='$requeue_id';"
"$CLI" "$DB" requeue "$requeue_id" >/dev/null
assert_state "$requeue_id" queued
[ "$(query "SELECT attempts FROM hx_tasks WHERE task_id='$requeue_id';")" = 1 ] || fail "first attempt"

"$CLI" "$DB" claim "$requeue_id" worker-r >/dev/null
query "UPDATE hx_tasks SET updated_at='2000-01-01T00:00:00Z' WHERE task_id='$requeue_id';"
"$CLI" "$DB" requeue "$requeue_id" 1 >/dev/null
assert_state "$requeue_id" queued
[ "$(query "SELECT attempts FROM hx_tasks WHERE task_id='$requeue_id';")" = 2 ] || fail "second attempt"

"$CLI" "$DB" claim "$requeue_id" worker-r >/dev/null
query "UPDATE hx_tasks SET updated_at='2000-01-01T00:00:00Z' WHERE task_id='$requeue_id';"
"$CLI" "$DB" requeue "$requeue_id" >/dev/null
assert_state "$requeue_id" failed
[ "$(query "SELECT attempts FROM hx_tasks WHERE task_id='$requeue_id';")" = 3 ] || fail "third attempt"
expect_fail "terminal requeue" "$CLI" "$DB" requeue "$requeue_id" 0

fresh_id=$(create_task fresh)
"$CLI" "$DB" claim "$fresh_id" worker-f >/dev/null
expect_fail "fresh claim requeue" "$CLI" "$DB" requeue "$fresh_id" 15
echo "PASS: timed requeue and attempts ceiling"

expect_fail "missing create fields" "$CLI" "$DB" create only-key
expect_fail "empty workplan ref" "$CLI" "$DB" create empty-workplan "" branch criteria
expect_fail "empty branch" "$CLI" "$DB" create empty-branch P1-F1-T4 "" criteria
expect_fail "empty criteria" "$CLI" "$DB" create empty-criteria P1-F1-T4 branch ""
expect_fail "invalid max attempts" "$CLI" "$DB" create bad-max P1-F1-T4 branch criteria x
expect_fail "empty owner" "$CLI" "$DB" claim "$fresh_id" ""
expect_fail "empty progress" "$CLI" "$DB" progress "$fresh_id" ""
expect_fail "invalid timeout" "$CLI" "$DB" requeue "$fresh_id" x
echo "PASS: required payload validation"

[ -n "$("$CLI" "$DB" show "$done_id")" ] || fail "show output"
[ "$("$CLI" "$DB" list | wc -l | tr -d ' ')" -ge 8 ] || fail "list output"

"$MIGRATE" down "$DB"
"$MIGRATE" down "$DB"
[ "$(query "SELECT count(*) FROM sqlite_master WHERE name IN ('hx_tasks', 'hx_task_messages', 'hx_tasks_state_transition');")" = 0 ] || fail "ledger down"
"$MIGRATE" up "$DB"
[ "$(query "SELECT count(*) FROM hx_schema_migrations;")" = 2 ] || fail "ledger final up"
echo "PASS: ledger up/up/down/down/up"
