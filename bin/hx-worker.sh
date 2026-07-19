#!/usr/bin/env bash

# @file bin/hx-worker.sh
# @brief Launch one Codex worker inside a repository-scoped writable sandbox.
# @description
#   Checks repository instructions and the operator kill switch, optionally
#   claims a ledger task, and records the Codex session from start to exit.
# @option --dry-run Print checks and the command without mutating the ledger.
# @option --task-id <id> Internal hx_tasks task ID to claim and start.
# @option --owner <name> Ledger owner; defaults to HX_WORKER_OWNER or codex-worker.
# @arg $1 repo Repository worktree containing AGENTS.md.
# @arg $2 prompt Optional Codex prompt.

set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TASK="$ROOT/db/hx-task.sh"
AGMSG_STORAGE="$HOME/.agents/skills/agmsg/scripts/lib/storage.sh"
DRY_RUN=0
TASK_ID=
OWNER=${HX_WORKER_OWNER:-codex-worker}
SESSION_STARTED=0
FINAL_STATUS=failed

usage() {
    cat <<'EOF'
usage: bin/hx-worker.sh [--dry-run] [--task-id HX-ID] [--owner NAME] REPO [PROMPT]
EOF
}

die() {
    echo "hx-worker: $*" >&2
    exit 1
}

sql_quote() {
    printf '%s' "$1" | sed "s/'/''/g"
}

# shellcheck disable=SC2329
finish_session() {
    [ "$SESSION_STARTED" -eq 1 ] || return
    local session status
    session=$(sql_quote "$SESSION_ID")
    status=$(sql_quote "$FINAL_STATUS")
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" "$DB" "
UPDATE hx_sessions
SET ended_at=strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), status='$status'
WHERE session_id='$session';"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --task-id|--owner)
            [ "$#" -ge 2 ] || die "$1 requires a value"
            case "$1" in
                --task-id) TASK_ID=$2 ;;
                --owner) OWNER=$2 ;;
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

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || {
    usage >&2
    exit 2
}
REPO=$1
PROMPT=${2:-Check your agmsg inbox and process the assigned task.}

[ -d "$REPO" ] || die "repository does not exist: $REPO"
REPO=$(CDPATH='' cd -- "$REPO" && pwd)
[ -f "$REPO/AGENTS.md" ] || die "AGENTS.md is required in target repository: $REPO"
echo "check=AGENTS.md pass"

KILL_SWITCH="$HOME/.agents/hx/kill-switch"
# ponytail: Keep this file-only switch until F8-T3 adds the DB-backed control.
[ ! -e "$KILL_SWITCH" ] || die "kill switch is active: $KILL_SWITCH"
echo "check=kill-switch pass"

COMMAND=(
    codex
    --sandbox workspace-write
    --ask-for-approval on-request
    --cd "$REPO"
    exec
    --ignore-user-config
    --ephemeral
    "$PROMPT"
)

if [ "$DRY_RUN" -eq 1 ]; then
    [ -z "$TASK_ID" ] || echo "ledger=would-claim-and-start task_id=$TASK_ID owner=$OWNER"
    printf 'command='
    printf '%q ' "${COMMAND[@]}"
    printf '\n'
    exit 0
fi

if [ -n "${HX_DB_PATH:-}" ]; then
    DB=$HX_DB_PATH
else
    [ -r "$AGMSG_STORAGE" ] || die "agmsg storage resolver is not readable: $AGMSG_STORAGE"
    # shellcheck source=/dev/null
    source "$AGMSG_STORAGE"
    DB=$(agmsg_db_path)
fi
[ -f "$DB" ] || die "ledger database does not exist: $DB"

if [ -n "$TASK_ID" ]; then
    "$TASK" "$DB" claim "$TASK_ID" "$OWNER" >/dev/null
    "$TASK" "$DB" start "$TASK_ID" >/dev/null
fi

SESSION_ID="codex-$(date -u +%Y%m%dT%H%M%S)-$$"
session=$(sql_quote "$SESSION_ID")
project=$(sql_quote "$REPO")
sqlite3 -cmd ".bail on" -cmd ".timeout 5000" "$DB" "
INSERT INTO hx_sessions(session_id, agent_type, project, started_at, status)
VALUES ('$session', 'codex', '$project', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'running');"
SESSION_STARTED=1
trap finish_session EXIT

set +e
"${COMMAND[@]}"
result=$?
set -e
if [ "$result" -eq 0 ]; then
    FINAL_STATUS=completed
fi
exit "$result"
