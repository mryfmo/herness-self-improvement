#!/usr/bin/env bash

# @file ci/test_worker_bridge.sh
# @brief Exercise the Codex worker wrapper and AGMSG ledger adapter.
# @description
#   Uses temporary ledger and AGMSG databases plus a fake codex executable.
#   No real worker is launched and no production AGMSG database is written.

set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
ADAPTER="$ROOT/bin/hx-agmsg-adapter.sh"
WORKER="$ROOT/bin/hx-worker.sh"
TASK="$ROOT/db/hx-task.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_eq() {
    [ "$1" = "$2" ] || fail "expected '$2', got '$1'"
}

assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) fail "expected output to contain '$2'" ;;
    esac
}

query() {
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" "$LEDGER_DB" "$1"
}

message_count() {
    if [ ! -f "$AGMSG_DB" ]; then
        echo 0
        return
    fi
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" "$AGMSG_DB" \
        "SELECT count(*) FROM messages;"
}

expect_failure() {
    if "$@" >"$TMP/rejected.out" 2>"$TMP/rejected.err"; then
        fail "command unexpectedly succeeded: $*"
    fi
}

LEDGER_DB="$TMP/ledger.db"
AGMSG_DIR="$TMP/agmsg"
AGMSG_DB="$AGMSG_DIR/messages.db"
HOME_DIR="$TMP/home"
GOOD_REPO="$TMP/good-repo"
BAD_REPO="$TMP/bad-repo"
mkdir -p "$AGMSG_DIR" "$HOME_DIR" "$GOOD_REPO" "$BAD_REPO" "$TMP/bin"
printf '# Test instructions\n' >"$GOOD_REPO/AGENTS.md"
"$ROOT/db/migrate.sh" up "$LEDGER_DB"
sqlite3 "$AGMSG_DB" "
CREATE TABLE messages (
    id INTEGER PRIMARY KEY,
    team TEXT NOT NULL,
    from_agent TEXT NOT NULL,
    to_agent TEXT NOT NULL,
    body TEXT NOT NULL
);"
cat >"$TMP/bin/send.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
quote() {
    printf '%s' "$1" | sed "s/'/''/g"
}
sqlite3 "$AGMSG_STORAGE_PATH/messages.db" "
INSERT INTO messages(team, from_agent, to_agent, body)
VALUES ('$(quote "$1")', '$(quote "$2")', '$(quote "$3")', '$(quote "$4")');"
EOF
chmod +x "$TMP/bin/send.sh"
cat >"$TMP/bin/fail-send.sh" <<'EOF'
#!/usr/bin/env sh
exit 42
EOF
chmod +x "$TMP/bin/fail-send.sh"

expect_failure env HOME="$HOME_DIR" HX_DB_PATH="$LEDGER_DB" \
    "$WORKER" --dry-run "$BAD_REPO"
assert_contains "$(cat "$TMP/rejected.err")" "AGENTS.md"

mkdir -p "$HOME_DIR/.agents/hx"
touch "$HOME_DIR/.agents/hx/kill-switch"
expect_failure env HOME="$HOME_DIR" HX_DB_PATH="$LEDGER_DB" \
    "$WORKER" --dry-run "$GOOD_REPO"
assert_contains "$(cat "$TMP/rejected.err")" "kill switch"
rm "$HOME_DIR/.agents/hx/kill-switch"

dry_run=$(HOME="$HOME_DIR" HX_DB_PATH="$LEDGER_DB" \
    "$WORKER" --dry-run "$GOOD_REPO" "process assigned task")
assert_contains "$dry_run" "check=AGENTS.md pass"
assert_contains "$dry_run" "check=kill-switch pass"
assert_contains "$dry_run" "--sandbox workspace-write"
assert_contains "$dry_run" "--ask-for-approval on-request"
assert_contains "$dry_run" "--ignore-user-config"
assert_contains "$dry_run" "--ephemeral"
assert_eq "$(query "SELECT count(*) FROM hx_sessions;")" 0

export HX_DB_PATH="$LEDGER_DB"
export AGMSG_STORAGE_PATH="$AGMSG_DIR"
export HX_AGMSG_TEAM="bridge-test"
export HX_AGMSG_FROM="orchestrator"
export HX_AGMSG_TO="worker"
export HX_AGMSG_SEND="$TMP/bin/send.sh"

ledger_id=$("$ADAPTER" assign a023 P1-F2-T4 \
    a023/f2-t4-worker-bridge "bridge tests pass" \
    .orchestration/tasks/a023-f2-t4-worker-wrapper-adapter.md)
assert_eq "$(query "SELECT count(*) FROM hx_tasks WHERE idempotency_key='a023';")" 1
assert_eq "$(query "SELECT count(*) FROM hx_task_messages WHERE task_id='$ledger_id' AND kind='task.assign';")" 1
assert_eq "$(query "SELECT state FROM hx_tasks WHERE task_id='$ledger_id';")" queued
assert_eq "$(message_count)" 1
assign_message=$(sqlite3 "$AGMSG_DB" "SELECT body FROM messages ORDER BY id DESC LIMIT 1;")
assert_contains "$assign_message" "AGMSG-TASK v1 task_id=a023"
assert_contains "$assign_message" "ledger_task_id=$ledger_id"
assert_contains "$assign_message" "task_file=.orchestration/tasks/a023-f2-t4-worker-wrapper-adapter.md"

same_id=$("$ADAPTER" assign a023 P1-F2-T4 \
    a023/f2-t4-worker-bridge "bridge tests pass" \
    .orchestration/tasks/a023-f2-t4-worker-wrapper-adapter.md)
assert_eq "$same_id" "$ledger_id"
assert_eq "$(query "SELECT count(*) FROM hx_tasks WHERE idempotency_key='a023';")" 1
assert_eq "$(query "SELECT count(*) FROM hx_task_messages WHERE task_id='$ledger_id' AND kind='task.assign';")" 1

cat >"$TMP/bin/codex" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$@" >"$HX_FAKE_CODEX_ARGS"
EOF
chmod +x "$TMP/bin/codex"
HX_FAKE_CODEX_ARGS="$TMP/codex.args" PATH="$TMP/bin:$PATH" \
    HOME="$HOME_DIR" "$WORKER" --task-id "$ledger_id" --owner test-worker \
    "$GOOD_REPO" "process assigned task"
assert_eq "$(query "SELECT state FROM hx_tasks WHERE task_id='$ledger_id';")" running
assert_eq "$(query "SELECT owner FROM hx_tasks WHERE task_id='$ledger_id';")" test-worker
assert_eq "$(query "SELECT count(*) FROM hx_sessions WHERE agent_type='codex' AND status='completed' AND ended_at IS NOT NULL;")" 1
assert_contains "$(cat "$TMP/codex.args")" "workspace-write"
assert_contains "$(cat "$TMP/codex.args")" "on-request"

"$ADAPTER" result a023 ready_for_review \
    report=.orchestration/reports/a023-report.md \
    validation=.orchestration/validation/a023-validation.md >/dev/null
assert_eq "$(query "SELECT state FROM hx_tasks WHERE task_id='$ledger_id';")" running
assert_contains "$(query "SELECT detail FROM hx_tasks WHERE task_id='$ledger_id';")" "review status=ready_for_review"
assert_contains "$(sqlite3 "$AGMSG_DB" "SELECT body FROM messages ORDER BY id DESC LIMIT 1;")" \
    "AGMSG-RESULT v1 task_id=a023 status=ready_for_review"

"$ADAPTER" accept a023 revise "add one regression assertion" >/dev/null
assert_eq "$(query "SELECT state FROM hx_tasks WHERE task_id='$ledger_id';")" running
assert_contains "$(sqlite3 "$AGMSG_DB" "SELECT body FROM messages ORDER BY id DESC LIMIT 1;")" \
    "AGMSG-ACCEPTANCE v1 task_id=a023 status=revise"

before=$(message_count)
expect_failure env HX_AGMSG_SEND="$TMP/bin/fail-send.sh" \
    "$ADAPTER" accept a023 accepted "all checks passed"
assert_eq "$(query "SELECT state FROM hx_tasks WHERE task_id='$ledger_id';")" "done"
assert_eq "$(message_count)" "$before"
"$ADAPTER" accept a023 accepted "all checks passed" >/dev/null
assert_eq "$(query "SELECT state FROM hx_tasks WHERE task_id='$ledger_id';")" "done"
assert_eq "$(query "SELECT count(*) FROM hx_task_messages WHERE task_id='$ledger_id' AND kind='task.result';")" 1

blocked_id=$("$ADAPTER" assign a023-error P1-F2-T4 \
    a023/f2-t4-worker-bridge "exercise blocked result" task.md)
"$TASK" "$LEDGER_DB" claim "$blocked_id" test-worker >/dev/null
"$TASK" "$LEDGER_DB" start "$blocked_id" >/dev/null
"$ADAPTER" error a023-error "operator kill switch active" >/dev/null
assert_eq "$(query "SELECT state FROM hx_tasks WHERE task_id='$blocked_id';")" blocked
assert_contains "$(sqlite3 "$AGMSG_DB" "SELECT body FROM messages ORDER BY id DESC LIMIT 1;")" \
    "AGMSG-RESULT v1 task_id=a023-error status=blocked"

before=$(message_count)
expect_failure "$ADAPTER" assign create-failure P1-F2-T4 "" \
    "must not send" task.md
assert_eq "$(message_count)" "$before"
assert_eq "$(query "SELECT count(*) FROM hx_tasks WHERE idempotency_key='create-failure';")" 0

echo "worker bridge tests passed"
