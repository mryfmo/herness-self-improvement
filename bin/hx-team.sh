#!/usr/bin/env bash

# @file bin/hx-team.sh
# @brief List, launch, and reconcile the repository's configured agent roles.
# @description
#   Reads the dependency-free teams/team-config.yaml subset, launches Codex
#   roles in Herdr through hx-worker.sh, and compares Herdr state with hx_tasks.
# @option --dry-run Validate and print a spawn command without starting Herdr.
# @arg $1 command One of list, spawn, or status.

set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG=${HX_TEAM_CONFIG:-"$ROOT/teams/team-config.yaml"}
HERDR=${HX_TEAM_HERDR:-herdr}
WORKER=${HX_TEAM_WORKER:-"$ROOT/bin/hx-worker.sh"}
AGMSG_STORAGE="$HOME/.agents/skills/agmsg/scripts/lib/storage.sh"

usage() {
    cat <<'EOF'
usage:
  bin/hx-team.sh list
  bin/hx-team.sh spawn [--dry-run] <role>
  bin/hx-team.sh status
EOF
}

die() {
    echo "hx-team: $*" >&2
    exit 1
}

config_records() {
    awk '
        function reject(message) {
            print "hx-team: config line " NR ": " message > "/dev/stderr"
            aborted = 1
            exit 2
        }
        function clear_role() {
            name = alias = agent = model = effort = supervisor = parallel = ""
            delete field_seen
        }
        function valid_value(value) {
            return value ~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/
        }
        function valid_role(value) {
            return value ~ /^[a-z][a-z0-9-]*$/
        }
        function flush_role() {
            if (name == "") return
            if (agent !~ /^(claude|codex)$/) reject("agent must be claude or codex")
            if (model == "" || !valid_value(model)) reject("model is missing or invalid")
            if (effort !~ /^(low|medium|high)$/) reject("effort must be low, medium, or high")
            if (supervisor == "" || !valid_role(supervisor)) reject("supervisor is missing or invalid")
            if (parallel !~ /^[1-9][0-9]*$/) reject("parallel must be a positive integer")
            printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                name, agent, model, effort, supervisor, parallel, alias
            role_count++
            clear_role()
        }
        BEGIN {
            version_seen = roles_seen = role_count = 0
            clear_role()
        }
        /^[[:space:]]*($|#)/ { next }
        /^version: 1$/ {
            if (version_seen++) reject("duplicate version")
            next
        }
        /^roles:$/ {
            if (roles_seen++) reject("duplicate roles key")
            next
        }
        /^  - name: / {
            flush_role()
            name = substr($0, 11)
            if (!valid_role(name)) reject("role name is invalid")
            field_seen["name"] = 1
            next
        }
        /^    (alias|agent|model|effort|supervisor|parallel): / {
            if (name == "") reject("role field appears before name")
            line = substr($0, 5)
            split_at = index(line, ": ")
            key = substr(line, 1, split_at - 1)
            value = substr(line, split_at + 2)
            if (field_seen[key]++) reject("duplicate role field " key)
            if (value == "") reject(key " is invalid")
            if (key == "alias" && !valid_role(value)) reject("alias is invalid")
            if (key != "alias" && !valid_value(value)) reject(key " is invalid")
            if (key == "alias") alias = value
            if (key == "agent") agent = value
            if (key == "model") model = value
            if (key == "effort") effort = value
            if (key == "supervisor") supervisor = value
            if (key == "parallel") parallel = value
            next
        }
        { reject("unsupported YAML syntax") }
        END {
            if (aborted) exit 2
            if (version_seen != 1) reject("version must be 1")
            if (roles_seen != 1) reject("roles key is required")
            flush_role()
            if (role_count == 0) reject("at least one role is required")
        }
    ' "$CONFIG"
}

load_records() {
    [ -f "$CONFIG" ] || die "config not found: $CONFIG"
    RECORDS=$(config_records)
    printf '%s\n' "$RECORDS" | awk -F '\t' '
        seen[$1]++ { print "hx-team: duplicate role " $1 > "/dev/stderr"; failed = 1 }
        { supervisor[NR] = $5 }
        END {
            for (row in supervisor) {
                if (supervisor[row] != "none" && !seen[supervisor[row]]) {
                    print "hx-team: unknown supervisor " supervisor[row] > "/dev/stderr"
                    failed = 1
                }
            }
            exit failed
        }
    ' || exit 1
}

role_record() {
    printf '%s\n' "$RECORDS" | awk -F '\t' -v role="$1" '$1 == role { print; found = 1 } END { exit !found }'
}

print_command() {
    printf 'command='
    printf '%q ' "$@"
    printf '\n'
}

release_spawn_lock() {
    [ -z "${LOCK_DIR:-}" ] || rmdir "$LOCK_DIR" 2>/dev/null || true
}

acquire_spawn_lock() {
    local key
    key=$(printf '%s' "$ROOT" | cksum | awk '{ print $1 }')
    LOCK_DIR="${TMPDIR:-/tmp}/hx-team-$key.lock"
    mkdir "$LOCK_DIR" 2>/dev/null || die "another team spawn is in progress"
    trap release_spawn_lock EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
}

cmd_list() {
    printf 'role\tagent\tmodel\teffort\tsupervisor\tparallel\talias\n'
    printf '%s\n' "$RECORDS"
}

next_slot() {
    local role=$1
    local limit=$2
    local agents
    agents=$("$HERDR" agent list) || die "herdr agent list failed"
    python3 -c '
import json, os, re, sys
agents = json.load(sys.stdin).get("result", {}).get("agents", [])
role, limit, root = sys.argv[1], int(sys.argv[2]), os.path.realpath(sys.argv[3])
pattern = re.compile(r"^hx-" + re.escape(role) + r"-([1-9][0-9]*)$")
names = {
    item.get("name") or ""
    for item in agents
    if os.path.realpath(item.get("cwd") or "") == root
}
if any(re.fullmatch(r"hx-[a-z][a-z0-9-]*-[1-9][0-9]*", name) for name in names):
    raise SystemExit(3)
for slot in range(1, limit + 1):
    if not any(pattern.fullmatch(name) and int(pattern.fullmatch(name).group(1)) == slot for name in names):
        print(slot)
        raise SystemExit
raise SystemExit(2)
' "$role" "$limit" "$ROOT" <<<"$agents" \
        || die "another Codex team role is active; the shared AGMSG identity is serial"
}

cmd_spawn() {
    local dry_run=0
    if [ "${1:-}" = --dry-run ]; then
        dry_run=1
        shift
    fi
    [ "$#" -eq 1 ] || {
        usage >&2
        exit 2
    }

    local role=$1 record name agent model runtime_model effort _supervisor parallel _alias slot prompt
    record=$(role_record "$role") || die "unknown role: $role"
    IFS=$'\t' read -r name agent model effort _supervisor parallel _alias <<<"$record"
    [ "$agent" = codex ] || die "role $role uses $agent; hx-worker.sh launches Codex roles only"
    if [ "$dry_run" -eq 0 ] && [ -z "${HX_TEAM_TASK_ID:-}" ]; then
        die "HX_TEAM_TASK_ID is required for a real spawn"
    fi

    runtime_model=$model
    [ "$model" != gpt56sol-high ] || runtime_model=gpt-5.6-sol
    slot=1
    if [ "$dry_run" -eq 0 ]; then
        acquire_spawn_lock
        slot=$(next_slot "$role" "$parallel")
    fi
    name="hx-$role-$slot"
    prompt="Use agmsg history and process only ledger task ${HX_TEAM_TASK_ID:-HX-ID} as role $role."

    local -a worker_args
    worker_args=(--owner "hx-team/$role")
    [ -z "${HX_TEAM_TASK_ID:-}" ] || worker_args+=(--task-id "$HX_TEAM_TASK_ID")
    worker_args+=("$ROOT" "$prompt")

    if [ "$dry_run" -eq 1 ]; then
        "$WORKER" --dry-run "${worker_args[@]}"
    fi

    local codex wrapper
    codex=$(command -v codex) || die "codex is not installed"
    # shellcheck disable=SC2016 # Variables expand in the Herdr child.
    wrapper='
codex() {
    "$HX_TEAM_CODEX" --model "$HX_TEAM_MODEL" -c "model_reasoning_effort=\"$HX_TEAM_EFFORT\"" "$@"
}
source "$0"
'
    local -a launch
    launch=("$HERDR" agent start "$name" --cwd "$ROOT" --no-focus \
        --env "HX_TEAM_ROLE=$role" \
        --env "HX_TEAM_PROFILE=$model" \
        --env "HX_TEAM_MODEL=$runtime_model" \
        --env "HX_TEAM_EFFORT=$effort" \
        --env "HX_TEAM_CODEX=$codex" \
        -- bash -c "$wrapper" "$WORKER" "${worker_args[@]}")
    if [ "$dry_run" -eq 1 ]; then
        print_command "${launch[@]}"
        return
    fi
    "${launch[@]}"
}

resolve_db() {
    if [ -n "${HX_DB_PATH:-}" ]; then
        DB=$HX_DB_PATH
        return
    fi
    [ -r "$AGMSG_STORAGE" ] || die "agmsg storage resolver is not readable: $AGMSG_STORAGE"
    # shellcheck source=/dev/null
    source "$AGMSG_STORAGE"
    DB=$(agmsg_db_path)
}

herdr_role_status() {
    local agents=$1
    local role=$2
    python3 -c '
import json, os, re, sys
agents = json.load(sys.stdin).get("result", {}).get("agents", [])
root, role = os.path.realpath(sys.argv[1]), sys.argv[2]
pattern = re.compile(r"^hx-" + re.escape(role) + r"-[1-9][0-9]*$")
states = {
    item.get("agent_status", "unknown")
    for item in agents
    if pattern.fullmatch(item.get("name") or "")
    and os.path.realpath(item.get("cwd") or "") == root
}
print(",".join(sorted(states)) if states else "missing")
' "$ROOT" "$role" <<<"$agents"
}

ledger_role_status() {
    local role=$1
    local owner=${role//\'/\'\'}
    local states
    states=$(sqlite3 -cmd ".bail on" -cmd ".timeout 5000" "$DB" "
SELECT group_concat(state, ',')
FROM (
    SELECT DISTINCT state
    FROM hx_tasks
    WHERE owner='hx-team/$owner'
    ORDER BY state
);")
    printf '%s\n' "${states:-none}"
}

cmd_status() {
    local agents
    agents=$("$HERDR" agent list) || die "herdr agent list failed"
    resolve_db
    [ -f "$DB" ] || die "ledger database does not exist: $DB"
    printf 'role\therdr\tledger\n'
    local herdr_status ledger_status
    while IFS=$'\t' read -r role _agent _model _effort _supervisor _parallel _alias; do
        herdr_status=$(herdr_role_status "$agents" "$role") \
            || die "invalid herdr agent list response"
        ledger_status=$(ledger_role_status "$role") \
            || die "ledger status query failed for role $role"
        printf '%s\therdr=%s\tledger=%s\n' \
            "$role" \
            "$herdr_status" \
            "$ledger_status"
    done <<<"$RECORDS"
}

load_records
command=${1:-}
shift || true
case "$command" in
    list)
        [ "$#" -eq 0 ] || die "list takes no arguments"
        cmd_list
        ;;
    spawn)
        cmd_spawn "$@"
        ;;
    status)
        [ "$#" -eq 0 ] || die "status takes no arguments"
        cmd_status
        ;;
    -h|--help)
        usage
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
