#!/usr/bin/env sh

# @file db/hx-task.sh
# @brief Create and transition tasks in an injected SQLite ledger.
# @description
#   All writes use the hx_ schema and a caller-supplied database path.
#   Run with --help for the subcommand contract.
# @arg $1 db-path SQLite database containing migration 0002.
# @arg $2 subcommand Task ledger operation.

set -eu

usage() {
    cat <<'EOF'
usage: db/hx-task.sh <db-path> <subcommand> [arguments]

subcommands:
  create <idempotency-key> <workplan-ref> <branch> <done-criteria> [max-attempts]
  claim <task-id> <owner>
  start <task-id>
  progress <task-id> <payload>
  done <task-id> <payload>
  fail <task-id> <payload>
  block <task-id> <payload>
  requeue <task-id> [timeout-minutes]  default: 15
  show <task-id>
  list
EOF
}

die() {
    echo "hx-task: $*" >&2
    exit 1
}

require_nonempty() {
    [ -n "$2" ] || die "$1 must not be empty"
}

require_uint() {
    case "$2" in
        ''|*[!0-9]*) die "$1 must be a non-negative integer" ;;
    esac
}

sql_quote() {
    printf '%s' "$1" | sed "s/'/''/g"
}

sql() {
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$DB" "$1"
}

display() {
    sqlite3 -header -column -cmd ".bail on" -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$DB" "$1"
}

transition() {
    task=$(sql_quote "$1")
    from=$2
    to=$3
    kind=$4
    payload=$(sql_quote "$5")
    changed=$(sql "
BEGIN IMMEDIATE;
UPDATE hx_tasks
SET state='$to',
    updated_at=strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    detail='$payload'
WHERE task_id='$task' AND state='$from';
INSERT INTO hx_task_messages(task_id, ts, kind, payload)
SELECT task_id, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), '$kind', '$payload'
FROM hx_tasks
WHERE task_id='$task' AND changes()=1;
SELECT changes();
COMMIT;")
    [ "$changed" = 1 ] || die "$1 is not in state $from"
    printf '%s|%s\n' "$1" "$to"
}

if [ "$#" -eq 1 ] && [ "$1" = --help ]; then
    usage
    exit 0
fi
[ "$#" -ge 2 ] || {
    usage >&2
    exit 2
}

DB=$1
COMMAND=$2
shift 2

case "$COMMAND" in
    --help|help)
        [ "$#" -eq 0 ] || die "help takes no arguments"
        usage
        ;;
    create)
        [ "$#" -eq 4 ] || [ "$#" -eq 5 ] || die "create requires 4 or 5 arguments"
        key=$1
        workplan=$2
        branch=$3
        criteria=$4
        max_attempts=${5:-2}
        require_nonempty idempotency-key "$key"
        require_nonempty workplan-ref "$workplan"
        require_nonempty branch "$branch"
        require_nonempty done-criteria "$criteria"
        require_uint max-attempts "$max_attempts"
        key_sql=$(sql_quote "$key")
        workplan_sql=$(sql_quote "$workplan")
        branch_sql=$(sql_quote "$branch")
        criteria_sql=$(sql_quote "$criteria")
        sql "
BEGIN IMMEDIATE;
INSERT INTO hx_tasks(
    task_id, idempotency_key, workplan_ref, branch, done_criteria,
    max_attempts, updated_at
)
VALUES (
    'hx-' || lower(hex(randomblob(16))),
    '$key_sql',
    '$workplan_sql',
    '$branch_sql',
    '$criteria_sql',
    $max_attempts,
    strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
)
ON CONFLICT(idempotency_key) DO NOTHING;
INSERT INTO hx_task_messages(task_id, ts, kind, payload)
SELECT task_id, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'task.assign', done_criteria
FROM hx_tasks
WHERE idempotency_key='$key_sql' AND changes()=1;
SELECT task_id FROM hx_tasks WHERE idempotency_key='$key_sql';
COMMIT;"
        ;;
    claim)
        [ "$#" -eq 2 ] || die "claim requires task-id and owner"
        require_nonempty task-id "$1"
        require_nonempty owner "$2"
        task=$(sql_quote "$1")
        owner=$(sql_quote "$2")
        changed=$(sql "
BEGIN IMMEDIATE;
UPDATE hx_tasks
SET state='claimed',
    owner='$owner',
    claimed_at=strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    updated_at=strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
WHERE task_id='$task' AND state='queued';
INSERT INTO hx_task_messages(task_id, ts, kind, payload)
SELECT task_id, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'task.claim', '$owner'
FROM hx_tasks
WHERE task_id='$task' AND changes()=1;
SELECT changes();
COMMIT;")
        [ "$changed" = 1 ] || die "$1 is not queued"
        printf '%s|claimed\n' "$1"
        ;;
    start)
        [ "$#" -eq 1 ] || die "start requires task-id"
        require_nonempty task-id "$1"
        transition "$1" claimed running task.progress started
        ;;
    progress)
        [ "$#" -eq 2 ] || die "progress requires task-id and payload"
        require_nonempty task-id "$1"
        require_nonempty payload "$2"
        task=$(sql_quote "$1")
        payload=$(sql_quote "$2")
        changed=$(sql "
BEGIN IMMEDIATE;
UPDATE hx_tasks
SET updated_at=strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), detail='$payload'
WHERE task_id='$task' AND state='running';
INSERT INTO hx_task_messages(task_id, ts, kind, payload)
SELECT task_id, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'task.progress', '$payload'
FROM hx_tasks
WHERE task_id='$task' AND changes()=1;
SELECT changes();
COMMIT;")
        [ "$changed" = 1 ] || die "$1 is not running"
        printf '%s|running\n' "$1"
        ;;
    done|fail|block)
        [ "$#" -eq 2 ] || die "$COMMAND requires task-id and payload"
        require_nonempty task-id "$1"
        require_nonempty payload "$2"
        case "$COMMAND" in
            done) target='done'; kind=task.result ;;
            fail) target=failed; kind=task.error ;;
            block) target=blocked; kind=task.error ;;
        esac
        transition "$1" running "$target" "$kind" "$2"
        ;;
    requeue)
        [ "$#" -eq 1 ] || [ "$#" -eq 2 ] || die "requeue requires task-id and optional timeout-minutes"
        require_nonempty task-id "$1"
        timeout=${2:-15}
        require_uint timeout-minutes "$timeout"
        task=$(sql_quote "$1")
        changed=$(sql "
BEGIN IMMEDIATE;
UPDATE hx_tasks
SET state=CASE WHEN attempts + 1 > max_attempts THEN 'failed' ELSE 'queued' END,
    attempts=attempts + 1,
    owner=CASE WHEN attempts + 1 > max_attempts THEN owner ELSE NULL END,
    claimed_at=CASE WHEN attempts + 1 > max_attempts THEN claimed_at ELSE NULL END,
    updated_at=strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
    detail='timeout after $timeout minutes'
WHERE task_id='$task'
  AND state IN ('claimed', 'running')
  AND julianday('now') - julianday(updated_at) >= $timeout / 1440.0;
INSERT INTO hx_task_messages(task_id, ts, kind, payload)
SELECT task_id, strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'task.error', detail
FROM hx_tasks
WHERE task_id='$task' AND changes()=1;
SELECT changes();
COMMIT;")
        [ "$changed" = 1 ] || die "$1 is not timed out or requeueable"
        state=$(sql "SELECT state FROM hx_tasks WHERE task_id='$task';")
        printf '%s|%s\n' "$1" "$state"
        ;;
    show)
        [ "$#" -eq 1 ] || die "show requires task-id"
        require_nonempty task-id "$1"
        task=$(sql_quote "$1")
        display "SELECT task_id, idempotency_key, state, owner, workplan_ref, branch, done_criteria, attempts, max_attempts, claimed_at, updated_at, detail FROM hx_tasks WHERE task_id='$task';"
        ;;
    list)
        [ "$#" -eq 0 ] || die "list takes no arguments"
        display "SELECT task_id, state, owner, workplan_ref, branch, attempts, max_attempts, updated_at FROM hx_tasks ORDER BY updated_at DESC, task_id;"
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
