#!/usr/bin/env sh

# @file .claude/hooks/hx-telemetry.sh
# @brief Record Claude lifecycle events without blocking the interaction.
# @description
#   The public subcommands copy stdin to a temporary file and launch the SQLite
#   writer in the background. Failures are logged and never fail the hook call.

set -u

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
PARSER="$ROOT/ci/hx_hook_fields.py"
STORAGE="$HOME/.agents/skills/agmsg/scripts/lib/storage.sh"
FAILURE_LOG=${HX_FAILURE_LOG:-"$HOME/.agents/hx/telemetry-failures.log"}

usage() {
    echo "usage: .claude/hooks/hx-telemetry.sh session-start|prompt-submit|post-tool-use|stop|subagent-stop" >&2
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

# @description Parse tool and stop events into SQL-safe hex and integer fields.
# @arg $1 event One of post-tool-use, stop, or subagent-stop.
parse_extended_fields() {
    python3 -c '
import json
import sys

sys.path.insert(0, sys.argv[2])
from secret_patterns import mask_text

event = sys.argv[1]
data = json.load(sys.stdin)
if not isinstance(data, dict):
    raise ValueError("event")

def text(key, *, required=False):
    value = data.get(key, "")
    if not isinstance(value, str) or (required and not value):
        raise ValueError(key)
    return value

def pick(*keys):
    response = data.get("tool_response")
    sources = (response, data) if isinstance(response, dict) else (data,)
    for source in sources:
        for key in keys:
            if key in source:
                return source[key]
    return None

def integer(value, *, nonnegative=False):
    if value is None or value == "":
        return "NULL"
    if isinstance(value, bool):
        raise ValueError("integer")
    number = int(value)
    if nonnegative and number < 0:
        raise ValueError("duration_ms")
    return str(number)

session_id = text("session_id", required=True)
project = text("cwd")
tool = ""
status = ""
duration = "NULL"
exit_code = "NULL"
error_summary = ""

if event == "post-tool-use":
    tool = text("tool_name", required=True)
    duration = integer(pick("duration_ms", "durationMs"), nonnegative=True)
    exit_value = pick("exit_code", "exitCode")
    exit_code = integer(exit_value)
    raw_status = pick("status")
    if isinstance(raw_status, str) and raw_status.lower() in {"error", "failed", "failure"}:
        failed = True
    elif isinstance(raw_status, str) and raw_status.lower() in {"ok", "success", "succeeded", "completed"}:
        failed = False
    else:
        success = pick("success")
        is_error = pick("is_error", "isError")
        failed = success is False or is_error is True
        if exit_code != "NULL":
            failed = failed or int(exit_code) != 0
    status = "failure" if failed else "success"
    stderr = pick("stderr", "error")
    if stderr is not None and not isinstance(stderr, str):
        raise ValueError("stderr")
    error_summary = mask_text(stderr or "")[0][:200]
elif event == "stop":
    status = "completed"
elif event == "subagent-stop":
    tool = "subagent"
    status = "success"
else:
    raise ValueError("event")

values = (session_id, project, tool, status, error_summary)
encoded = [value.encode().hex() for value in values]
print("|".join([*encoded[:4], duration, exit_code, encoded[4]]))
' "$1" "$ROOT/ci"
}

write_event() {
    event=$1
    input=$2
    db=$(resolve_db) || {
        record_failure "$event"
        rm -f "$input"
        return
    }
    case "$event" in
        session-start|prompt-submit)
            fields=$(python3 "$PARSER" "$event" <"$input")
            ;;
        *)
            fields=$(parse_extended_fields "$event" <"$input")
            ;;
    esac || {
        record_failure "$event"
        rm -f "$input"
        return
    }
    rm -f "$input"

    old_ifs=$IFS
    IFS='|'
    case "$event" in
        session-start|prompt-submit)
            read -r session_hex project_hex content_hex masked <<EOF
$fields
EOF
            ;;
        *)
            read -r session_hex project_hex tool_hex status_hex duration exit_code error_hex <<EOF
$fields
EOF
            ;;
    esac
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
        post-tool-use|subagent-stop)
            sql="
INSERT OR IGNORE INTO hx_sessions
    (session_id, agent_type, project, started_at, status)
VALUES
    (CAST(X'$session_hex' AS TEXT), 'claude-code',
     CAST(X'$project_hex' AS TEXT), strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'running');
INSERT INTO hx_tool_events
    (session_id, ts, tool, status, duration_ms, exit_code, error_summary)
VALUES
    (CAST(X'$session_hex' AS TEXT), strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
     CAST(X'$tool_hex' AS TEXT), CAST(X'$status_hex' AS TEXT),
     $duration, $exit_code, NULLIF(CAST(X'$error_hex' AS TEXT), ''));
"
            ;;
        stop)
            sql="
INSERT INTO hx_sessions
    (session_id, agent_type, project, started_at, ended_at, status)
VALUES
    (CAST(X'$session_hex' AS TEXT), 'claude-code',
     CAST(X'$project_hex' AS TEXT), strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
     strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), 'completed')
ON CONFLICT(session_id) DO UPDATE SET
    ended_at = excluded.ended_at,
    status = excluded.status;
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
    session-start|prompt-submit|post-tool-use|stop|subagent-stop)
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
