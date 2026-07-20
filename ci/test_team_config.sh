#!/usr/bin/env bash

# @file ci/test_team_config.sh
# @brief Verify team configuration parsing and the Herdr worker bridge.
# @description
#   Uses an isolated ledger and fake Herdr executable. No pane or worker is
#   started, and the live AGMSG database is never opened.

set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TEAM="$ROOT/bin/hx-team.sh"
CONFIG="$ROOT/teams/team-config.yaml"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) fail "expected output to contain '$2'" ;;
    esac
}

expect_failure() {
    if "$@" >"$TMP/rejected.out" 2>"$TMP/rejected.err"; then
        fail "command unexpectedly succeeded: $*"
    fi
}

[ -x "$TEAM" ] || fail "missing executable bin/hx-team.sh"
[ -f "$CONFIG" ] || fail "missing teams/team-config.yaml"

list=$("$TEAM" list)
assert_contains "$list" $'orchestrator\tclaude\tclaude-fable5high\thigh\tnone\t1'
assert_contains "$list" $'worker\tcodex\tgpt56sol-high\thigh\torchestrator\t1'
assert_contains "$list" $'reviewer\tcodex\tgpt56sol-high\thigh\torchestrator\t1'
assert_contains "$list" "adversarial-verifier"

dry_run=$("$TEAM" spawn --dry-run worker)
assert_contains "$dry_run" "herdr"
assert_contains "$dry_run" "agent start"
assert_contains "$dry_run" "hx-worker-1"
assert_contains "$dry_run" "bin/hx-worker.sh"
assert_contains "$dry_run" "--sandbox workspace-write"
assert_contains "$dry_run" "--model"
assert_contains "$dry_run" "model_reasoning_effort"

cp "$CONFIG" "$TMP/invalid.yaml"
sed -i.bak 's/agent: codex/agent: root/' "$TMP/invalid.yaml"
expect_failure env HX_TEAM_CONFIG="$TMP/invalid.yaml" "$TEAM" list
assert_contains "$(cat "$TMP/rejected.err")" "agent"

cp "$CONFIG" "$TMP/invalid.yaml"
sed -i.bak 's/supervisor: orchestrator/supervisor: missing/' "$TMP/invalid.yaml"
expect_failure env HX_TEAM_CONFIG="$TMP/invalid.yaml" "$TEAM" list
assert_contains "$(cat "$TMP/rejected.err")" "supervisor"

cp "$CONFIG" "$TMP/invalid.yaml"
sed -i.bak 's/parallel: 1/parallel: 0/' "$TMP/invalid.yaml"
expect_failure env HX_TEAM_CONFIG="$TMP/invalid.yaml" "$TEAM" list
assert_contains "$(cat "$TMP/rejected.err")" "parallel"

expect_failure "$TEAM" spawn --dry-run orchestrator
assert_contains "$(cat "$TMP/rejected.err")" "Codex"

cat >"$TMP/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = agent ] && [ "${2:-}" = list ]; then
    printf '%s\n' "$HX_FAKE_HERDR_LIST"
    exit 0
fi
printf '%s\n' "$*" >"$HX_FAKE_HERDR_ARGS"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --env)
            export "$2"
            shift 2
            ;;
        --)
            shift
            exec "$@"
            ;;
        *)
            shift
            ;;
    esac
done
EOF
chmod +x "$TMP/herdr"

cat >"$TMP/worker" <<'EOF'
#!/usr/bin/env bash
codex worker-payload
EOF
chmod +x "$TMP/worker"

cat >"$TMP/codex" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "$*" >"$HX_FAKE_CODEX_ARGS"
EOF
chmod +x "$TMP/codex"

EMPTY_HERDR_JSON='{"id":"test","result":{"agents":[]},"type":"agent_list"}'
HX_FAKE_HERDR_ARGS="$TMP/herdr.args" \
    HX_FAKE_CODEX_ARGS="$TMP/codex.args" \
    HX_FAKE_HERDR_LIST="$EMPTY_HERDR_JSON" \
    HX_TEAM_HERDR="$TMP/herdr" \
    HX_TEAM_WORKER="$TMP/worker" \
    HX_TEAM_TASK_ID="hx-test-worker" \
    PATH="$TMP:$PATH" \
    "$TEAM" spawn worker
assert_contains "$(cat "$TMP/herdr.args")" "agent start hx-worker-1"
assert_contains "$(cat "$TMP/herdr.args")" "$TMP/worker"
assert_contains "$(cat "$TMP/herdr.args")" "--model"
assert_contains "$(cat "$TMP/herdr.args")" "gpt56sol-high"
assert_contains "$(cat "$TMP/herdr.args")" "gpt-5.6-sol"
assert_contains "$(cat "$TMP/herdr.args")" "model_reasoning_effort"
assert_contains "$(cat "$TMP/codex.args")" "--model gpt-5.6-sol"
assert_contains "$(cat "$TMP/codex.args")" 'model_reasoning_effort="high"'
assert_contains "$(cat "$TMP/codex.args")" "worker-payload"

expect_failure env \
    HX_FAKE_HERDR_LIST="$EMPTY_HERDR_JSON" \
    HX_TEAM_HERDR="$TMP/herdr" \
    HX_TEAM_WORKER="$TMP/worker" \
    "$TEAM" spawn worker
assert_contains "$(cat "$TMP/rejected.err")" "HX_TEAM_TASK_ID"

HERDR_JSON='{"id":"test","result":{"agents":[{"agent":"codex","agent_status":"working","cwd":"'"$ROOT"'","name":"hx-worker-1","pane_id":"w1:p1"}],"type":"agent_list"}}'
DB="$TMP/ledger.db"
"$ROOT/db/migrate.sh" up "$DB"
task_id=$("$ROOT/db/hx-task.sh" "$DB" create team-status P1-F5-T2 test/team status)
"$ROOT/db/hx-task.sh" "$DB" claim "$task_id" hx-team/worker >/dev/null
"$ROOT/db/hx-task.sh" "$DB" start "$task_id" >/dev/null

status=$(
    HX_FAKE_HERDR_LIST="$HERDR_JSON" \
        HX_TEAM_HERDR="$TMP/herdr" \
        HX_DB_PATH="$DB" \
        "$TEAM" status
)
assert_contains "$status" $'worker\therdr=working\tledger=running'
assert_contains "$status" $'reviewer\therdr=missing\tledger=none'

OVERLAP_JSON='{"id":"test","result":{"agents":[{"agent":"codex","agent_status":"working","cwd":"'"$ROOT"'","name":"hx-worker-fast-1","pane_id":"w1:p2"}],"type":"agent_list"}}'
status=$(
    HX_FAKE_HERDR_LIST="$OVERLAP_JSON" \
        HX_TEAM_HERDR="$TMP/herdr" \
        HX_DB_PATH="$DB" \
        "$TEAM" status
)
assert_contains "$status" $'worker\therdr=missing\tledger=running'

expect_failure env \
    HX_FAKE_HERDR_LIST="$HERDR_JSON" \
    HX_TEAM_HERDR="$TMP/herdr" \
    HX_TEAM_WORKER="$TMP/worker" \
    HX_TEAM_TASK_ID="hx-second-worker" \
    "$TEAM" spawn reviewer
assert_contains "$(cat "$TMP/rejected.err")" "shared AGMSG identity is serial"

NULLABLE_JSON='{"id":"test","result":{"agents":[{"agent":null,"agent_status":"unknown","cwd":null,"name":null,"pane_id":"w1:p3"}],"type":"agent_list"}}'
status=$(
    HX_FAKE_HERDR_LIST="$NULLABLE_JSON" \
        HX_TEAM_HERDR="$TMP/herdr" \
        HX_DB_PATH="$DB" \
        "$TEAM" status
)
assert_contains "$status" $'worker\therdr=missing\tledger=running'

cat >"$TMP/herdr-race" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = agent ] && [ "${2:-}" = list ]; then
    if [ -f "$HX_FAKE_HERDR_STATE" ]; then
        printf '%s\n' "$HX_FAKE_HERDR_ACTIVE"
    else
        printf '%s\n' '{"id":"test","result":{"agents":[]},"type":"agent_list"}'
    fi
    exit 0
fi
touch "$HX_FAKE_HERDR_STATE"
EOF
chmod +x "$TMP/herdr-race"

run_race_spawn() {
    HX_FAKE_HERDR_STATE="$TMP/herdr.state" \
        HX_FAKE_HERDR_ACTIVE="$HERDR_JSON" \
        HX_TEAM_HERDR="$TMP/herdr-race" \
        HX_TEAM_WORKER="$TMP/worker" \
        HX_TEAM_TASK_ID="$1" \
        PATH="$TMP:$PATH" \
        "$TEAM" spawn "$2"
}

set +e
run_race_spawn hx-race-worker worker >"$TMP/race-worker.out" 2>"$TMP/race-worker.err" &
race_worker_pid=$!
run_race_spawn hx-race-reviewer reviewer >"$TMP/race-reviewer.out" 2>"$TMP/race-reviewer.err" &
race_reviewer_pid=$!
wait "$race_worker_pid"
race_worker_status=$?
wait "$race_reviewer_pid"
race_reviewer_status=$?
set -e
[ "$((race_worker_status + race_reviewer_status))" -ne 0 ] \
    || fail "concurrent spawns both succeeded"
[ "$race_worker_status" -eq 0 ] || [ "$race_reviewer_status" -eq 0 ] \
    || fail "concurrent spawns both failed"

if grep -En -e '--dangerous[l]y-' \
    "$ROOT/bin/hx-team.sh" \
    "$ROOT/teams/team-config.yaml" \
    "$ROOT/docs/reference/agent-teams-integration.md"; then
    fail "permission-bypass option found in the integration layer"
fi

echo "team config tests passed"
