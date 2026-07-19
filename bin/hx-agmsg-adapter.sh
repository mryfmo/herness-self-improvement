#!/usr/bin/env bash

# @file bin/hx-agmsg-adapter.sh
# @brief Map AGMSG task handoffs to the SQLite task ledger.
# @description
#   Mutates the hx_ task ledger before delivering each protocol message with
#   the existing agmsg send.sh. HX_DB_PATH overrides the colocated AGMSG DB.
# @option --team <name> AGMSG team; defaults to HX_AGMSG_TEAM.
# @option --from <agent> Sending agent; defaults to HX_AGMSG_FROM.
# @option --to <agent> Receiving agent; defaults to HX_AGMSG_TO.
# @env HX_AGMSG_SEND Test-only path to an AGMSG send.sh-compatible mock.
# @arg $1 command One of assign, result, accept, or error.

set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
AGMSG_SCRIPTS="$HOME/.agents/skills/agmsg/scripts"
SEND=${HX_AGMSG_SEND:-"$AGMSG_SCRIPTS/send.sh"}
TASK="$ROOT/db/hx-task.sh"

usage() {
    cat <<'EOF'
usage: bin/hx-agmsg-adapter.sh [--team NAME] [--from AGENT] [--to AGENT] COMMAND ...

commands:
  assign <task-id> <workplan-ref> <branch> <done-criteria> <task-file>
  result <task-id> <status> <artifact-path> [artifact-path ...]
  accept <task-id> <accepted|revise> <reason>
  error <task-id> <reason>
EOF
}

die() {
    echo "hx-agmsg-adapter: $*" >&2
    exit 1
}

require_nonempty() {
    [ -n "$2" ] || die "$1 must not be empty"
}

require_route() {
    require_nonempty "$1" "$2"
    case "$2" in
        *[!A-Za-z0-9_.@/+:-]*)
            die "$1 contains unsupported characters"
            ;;
    esac
}

sql_quote() {
    printf '%s' "$1" | sed "s/'/''/g"
}

ledger_id() {
    local key
    key=$(sql_quote "$1")
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" "$DB" \
        "SELECT task_id FROM hx_tasks WHERE idempotency_key='$key';"
}

ledger_state() {
    local id
    id=$(sql_quote "$1")
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" "$DB" \
        "SELECT state FROM hx_tasks WHERE task_id='$id';"
}

require_ledger_id() {
    local id
    id=$(ledger_id "$1")
    [ -n "$id" ] || die "unknown task-id: $1"
    printf '%s\n' "$id"
}

send_message() {
    "$SEND" "$TEAM" "$FROM" "$TO" "$1" >/dev/null
}

TEAM=${HX_AGMSG_TEAM:-}
FROM=${HX_AGMSG_FROM:-}
TO=${HX_AGMSG_TO:-}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --team|--from|--to)
            [ "$#" -ge 2 ] || die "$1 requires a value"
            case "$1" in
                --team) TEAM=$2 ;;
                --from) FROM=$2 ;;
                --to) TO=$2 ;;
            esac
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --*)
            die "unknown option: $1"
            ;;
        *)
            break
            ;;
    esac
done

[ "$#" -ge 1 ] || {
    usage >&2
    exit 2
}
[ -x "$SEND" ] || die "agmsg send.sh is not executable: $SEND"
[ -x "$TASK" ] || die "task ledger CLI is not executable: $TASK"
require_route team "$TEAM"
require_route from "$FROM"
require_route to "$TO"

if [ -n "${HX_DB_PATH:-}" ]; then
    DB=$HX_DB_PATH
else
    # shellcheck source=/dev/null
    source "$AGMSG_SCRIPTS/lib/storage.sh"
    DB=$(agmsg_db_path)
fi
COMMAND=$1
shift

case "$COMMAND" in
    assign)
        [ "$#" -eq 5 ] || die "assign requires 5 arguments"
        external_id=$1
        workplan=$2
        branch=$3
        criteria=$4
        task_file=$5
        require_route task-id "$external_id"
        require_nonempty task-file "$task_file"

        # The ledger write must succeed before the task can leave this process.
        internal_id=$("$TASK" "$DB" create \
            "$external_id" "$workplan" "$branch" "$criteria")
        message="AGMSG-TASK v1 task_id=$external_id repo=$ROOT task_file=$task_file allowed_files=see-task-file forbidden_actions=see-task-file expected_artifacts=see-task-file done_signal=AGMSG-RESULT workplan_ref=$workplan branch=$branch done_criteria=$criteria ledger_task_id=$internal_id"
        send_message "$message"
        printf '%s\n' "$internal_id"
        ;;
    result)
        [ "$#" -ge 3 ] || die "result requires task-id, status, and artifact paths"
        external_id=$1
        status=$2
        shift 2
        require_route task-id "$external_id"
        case "$status" in
            ready_for_review|blocked) ;;
            *) die "result status must be ready_for_review or blocked" ;;
        esac
        internal_id=$(require_ledger_id "$external_id")
        artifacts="$*"
        "$TASK" "$DB" progress "$internal_id" \
            "review status=$status artifacts=$artifacts" >/dev/null
        send_message "AGMSG-RESULT v1 task_id=$external_id status=$status $artifacts"
        printf '%s\n' "$internal_id"
        ;;
    accept)
        [ "$#" -eq 3 ] || die "accept requires task-id, accepted|revise, and reason"
        external_id=$1
        decision=$2
        reason=$3
        require_route task-id "$external_id"
        require_nonempty reason "$reason"
        internal_id=$(require_ledger_id "$external_id")
        case "$decision" in
            accepted)
                state=$(ledger_state "$internal_id")
                case "$state" in
                    running)
                        "$TASK" "$DB" "done" "$internal_id" \
                            "acceptance status=accepted reason=$reason" >/dev/null
                        ;;
                    done) ;;
                    *) die "$external_id cannot be accepted from state $state" ;;
                esac
                ;;
            revise)
                "$TASK" "$DB" progress "$internal_id" \
                    "acceptance status=revise reason=$reason" >/dev/null
                ;;
            *)
                die "accept status must be accepted or revise"
                ;;
        esac
        send_message "AGMSG-ACCEPTANCE v1 task_id=$external_id status=$decision reason=$reason"
        printf '%s\n' "$internal_id"
        ;;
    error)
        [ "$#" -eq 2 ] || die "error requires task-id and reason"
        external_id=$1
        reason=$2
        require_route task-id "$external_id"
        require_nonempty reason "$reason"
        internal_id=$(require_ledger_id "$external_id")
        state=$(ledger_state "$internal_id")
        case "$state" in
            running) "$TASK" "$DB" block "$internal_id" "$reason" >/dev/null ;;
            blocked) ;;
            *) die "$external_id cannot be blocked from state $state" ;;
        esac
        send_message "AGMSG-RESULT v1 task_id=$external_id status=blocked reason=$reason"
        printf '%s\n' "$internal_id"
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
