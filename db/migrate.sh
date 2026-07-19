#!/usr/bin/env sh

# @file db/migrate.sh
# @brief Apply, revert, or inspect the harness telemetry schema in a selected SQLite database.
# @description
#   Status reports every migration found as migrations/*.up.sql and exits nonzero
#   when at least one migration is pending.
# @arg $1 action One of up, down, or status.
# @arg $2 db-path SQLite database path.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
UP="$SCRIPT_DIR/migrations/0001_telemetry.up.sql"
DOWN="$SCRIPT_DIR/migrations/0001_telemetry.down.sql"
LEDGER_UP="$SCRIPT_DIR/migrations/0002_ledger.up.sql"
LEDGER_DOWN="$SCRIPT_DIR/migrations/0002_ledger.down.sql"

usage() {
    echo "usage: db/migrate.sh up|down|status <db-path>" >&2
    exit 2
}

[ "$#" -eq 2 ] || usage
ACTION=$1
DB=$2

[ -r "$UP" ] && [ -r "$DOWN" ] && [ -r "$LEDGER_UP" ] && [ -r "$LEDGER_DOWN" ] || {
    echo "migration files are not readable" >&2
    exit 1
}
case "$ACTION" in
    up|down|status) ;;
    *) usage ;;
esac

sqlite3 "$DB" >/dev/null <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA busy_timeout=5000;
CREATE TABLE IF NOT EXISTS hx_schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TEXT NOT NULL
);
SQL

case "$ACTION" in
    up)
        {
            echo "BEGIN IMMEDIATE;"
            cat "$UP"
            cat "$LEDGER_UP"
            echo "INSERT OR IGNORE INTO hx_schema_migrations VALUES ('0001_telemetry', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));"
            echo "INSERT OR IGNORE INTO hx_schema_migrations VALUES ('0002_ledger', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));"
            echo "COMMIT;"
        } | sqlite3 -cmd ".bail on" -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$DB"
        ;;
    down)
        {
            echo "BEGIN IMMEDIATE;"
            cat "$LEDGER_DOWN"
            cat "$DOWN"
            echo "DELETE FROM hx_schema_migrations WHERE version IN ('0002_ledger', '0001_telemetry');"
            echo "COMMIT;"
        } | sqlite3 -cmd ".bail on" -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$DB"
        ;;
    status)
        pending=0
        for migration in "$SCRIPT_DIR"/migrations/*.up.sql; do
            version=${migration##*/}
            version=${version%.up.sql}
            applied=$(sqlite3 -cmd ".timeout 5000" "$DB" \
                "SELECT count(*) FROM hx_schema_migrations WHERE version = '$version';")
            if [ "$applied" = 1 ]; then
                echo "$version applied"
            else
                echo "$version pending"
                pending=1
            fi
        done
        exit "$pending"
        ;;
esac
