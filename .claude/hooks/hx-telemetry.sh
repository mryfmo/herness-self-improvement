#!/usr/bin/env sh

# @file .claude/hooks/hx-telemetry.sh
# @brief Record Claude session and prompt events without blocking the interaction.
# @description
#   The public subcommands copy stdin to a temporary file and launch the SQLite
#   writer in the background. Failures are logged and never fail the hook call.

set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PARSER="$ROOT/ci/hx_hook_fields.py"
STORAGE="$HOME/.agents/skills/agmsg/scripts/lib/storage.sh"
FAILURE_LOG=${HX_FAILURE_LOG:-"$HOME/.agents/hx/telemetry-failures.log"}

usage() {
    echo "usage: .claude/hooks/hx-telemetry.sh session-start|prompt-submit" >&2
    exit 2
}

resolve_db() {
    if [ -n "${HX_DB_PATH:-}" ]; then
        printf '%s\n' "$HX_DB_PATH"
        return
    fi
    [ -r "$STORAGE" ] || return 1
    bash -c '. "$1"; agmsg_db_path' sh "$STORAGE"
}

record_failure() {
    mkdir -p "$(dirname -- "$FAILURE_LOG")" 2>/dev/null || return
    printf '%s event=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$1" >>"$FAILURE_LOG"
}

write_event() {
    event=$1
    input=$2
    db=$(resolve_db) || {
        record_failure "$event"
        rm -f "$input"
        return
    }
    fields=$(python3 "$PARSER" "$event" <"$input") || {
        record_failure "$event"
        rm -f "$input"
        return
    }
    rm -f "$input"

    old_ifs=$IFS
    IFS='|'
    read -r session_hex project_hex content_hex masked <<EOF
$fields
EOF
    IFS=$old_ifs

    case "$event" in
        session-start)
            sql="
INSERT OR IGNORE INTO hx_sessions
    (session_id, agent_type, project, started_at, status)
VALUES
    (CAST(X'$session_hex' AS TEXT), 'claude-code',
     CAST(X'$project_hex' AS TEXT), strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'running');
"
            ;;
        prompt-submit)
            sql="
INSERT OR IGNORE INTO hx_sessions
    (session_id, agent_type, project, started_at, status)
VALUES
    (CAST(X'$session_hex' AS TEXT), 'claude-code',
     CAST(X'$project_hex' AS TEXT), strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'running');
INSERT INTO hx_prompts (session_id, ts, role, content, masked)
VALUES
    (CAST(X'$session_hex' AS TEXT), strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
     'user', CAST(X'$content_hex' AS TEXT), $masked);
"
            ;;
    esac

    if ! sqlite3 -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$db" "$sql"; then
        record_failure "$event"
        return
    fi

    if [ -s "$FAILURE_LOG" ]; then
        failures=$(wc -l <"$FAILURE_LOG" | tr -d ' ')
        sqlite3 -cmd ".timeout 5000" "$db" "
INSERT INTO hx_audit (ts, actor, event, ref, detail)
VALUES
    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'hx-telemetry',
     'telemetry.failures.recovered', CAST(X'$session_hex' AS TEXT),
     '{\"failures\":$failures}');
" >/dev/null 2>&1 && : >"$FAILURE_LOG"
    fi
}

[ "$#" -ge 1 ] || usage
case "$1" in
    __write)
        [ "$#" -eq 3 ] || exit 0
        write_event "$2" "$3"
        exit 0
        ;;
    session-start|prompt-submit)
        [ "$#" -eq 1 ] || usage
        event=$1
        ;;
    *)
        usage
        ;;
esac

input=$(mktemp "${TMPDIR:-/tmp}/hx-hook.XXXXXX") || {
    record_failure "$event"
    exit 0
}
cat >"$input" || {
    rm -f "$input"
    record_failure "$event"
    exit 0
}
"$0" __write "$event" "$input" </dev/null >/dev/null 2>&1 &
exit 0
