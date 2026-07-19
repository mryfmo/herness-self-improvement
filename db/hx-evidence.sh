#!/usr/bin/env sh

# @file db/hx-evidence.sh
# @brief Record and query append-only evidence in the hx_audit table.
# @arg $1 db-path Existing migrated SQLite database.
# @arg $2 command One of record, list, or trace.
# @env HX_EVIDENCE_ALLOW_LIVE Set to 1 to allow a database under ~/.agents.

set -eu

usage() {
    cat >&2 <<'EOF'
usage: db/hx-evidence.sh <db-path> record <actor> <event> <ref> <detail-json>
       db/hx-evidence.sh <db-path> list
       db/hx-evidence.sh <db-path> trace <ref>
EOF
    exit 2
}

die() {
    echo "hx-evidence: $*" >&2
    exit 1
}

sql_quote() {
    printf '%s' "$1" | sed "s/'/''/g"
}

[ "$#" -ge 2 ] || usage
DB=$1
COMMAND=$2
shift 2

DB_DIR=$(dirname -- "$DB")
[ -d "$DB_DIR" ] || die "database parent directory does not exist"
DB_DIR=$(CDPATH='' cd -- "$DB_DIR" && pwd -P)
DB="$DB_DIR/$(basename -- "$DB")"
if [ -d "$HOME/.agents" ]; then
    AGENTS_DIR=$(CDPATH='' cd -- "$HOME/.agents" && pwd -P)
    case "$DB" in
        "$AGENTS_DIR"|"$AGENTS_DIR"/*)
            [ "${HX_EVIDENCE_ALLOW_LIVE:-}" = 1 ] ||
                die "refusing to use a live .agents database path"
            ;;
    esac
fi
[ -f "$DB" ] || die "database does not exist"

sql() {
    sqlite3 -cmd ".bail on" -cmd ".timeout 5000" "$DB" "$1"
}

display() {
    sqlite3 -header -column -cmd ".bail on" -cmd ".timeout 5000" "$DB" "$1"
}

[ "$(sql "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='hx_audit';")" = 1 ] ||
    die "hx_audit is not installed"

case "$COMMAND" in
    record)
        [ "$#" -eq 4 ] || usage
        actor=$1
        event=$2
        ref=$3
        detail=$4
        [ -n "$actor" ] || die "actor must not be empty"
        [ -n "$event" ] || die "event must not be empty"
        [ -n "$ref" ] || die "ref must not be empty"
        actor=$(sql_quote "$actor")
        event=$(sql_quote "$event")
        ref=$(sql_quote "$ref")
        detail=$(sql_quote "$detail")
        [ "$(sql "SELECT json_valid('$detail');")" = 1 ] || die "detail-json must be valid JSON"
        sql "
INSERT INTO hx_audit(ts, actor, event, ref, detail)
VALUES (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'), '$actor', '$event', '$ref', '$detail');
SELECT last_insert_rowid();"
        ;;
    list)
        [ "$#" -eq 0 ] || usage
        display "SELECT id, ts, actor, event, ref, detail FROM hx_audit ORDER BY id;"
        ;;
    trace)
        [ "$#" -eq 1 ] || usage
        [ -n "$1" ] || die "ref must not be empty"
        ref=$(sql_quote "$1")
        display "SELECT id, ts, actor, event, ref, detail FROM hx_audit WHERE ref='$ref' ORDER BY id;"
        ;;
    *)
        usage
        ;;
esac
