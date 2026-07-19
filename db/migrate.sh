#!/usr/bin/env sh

# @file db/migrate.sh
# @brief Apply, revert, or inspect the harness telemetry schema in a selected SQLite database.
# @description
#   Status reports every migration found as migrations/*.up.sql and exits nonzero
#   when at least one migration is pending.
# @arg $1 action One of up, down, or status.
# @arg $2 db-path SQLite database path.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
MIGRATIONS="$SCRIPT_DIR/migrations"

usage() {
    echo "usage: db/migrate.sh up|down|status <db-path>" >&2
    exit 2
}

[ "$#" -eq 2 ] || usage
ACTION=$1
DB=$2

[ -d "$MIGRATIONS" ] || {
    echo "migration directory is not readable" >&2
    exit 1
}
for migration in "$MIGRATIONS"/*.up.sql; do
    [ -r "$migration" ] && [ -r "${migration%.up.sql}.down.sql" ] || {
        echo "migration pair is not readable: $migration" >&2
        exit 1
    }
done
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
            for migration in "$MIGRATIONS"/*.up.sql; do
                version=${migration##*/}
                version=${version%.up.sql}
                cat "$migration"
                echo "INSERT OR IGNORE INTO hx_schema_migrations VALUES ('$version', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));"
            done
            echo "COMMIT;"
        } | sqlite3 -cmd ".bail on" -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$DB"
        ;;
    down)
        set --
        for migration in "$MIGRATIONS"/*.down.sql; do
            set -- "$migration" "$@"
        done
        {
            echo "BEGIN IMMEDIATE;"
            for migration do
                version=${migration##*/}
                version=${version%.down.sql}
                cat "$migration"
                echo "DELETE FROM hx_schema_migrations WHERE version='$version';"
            done
            echo "COMMIT;"
        } | sqlite3 -cmd ".bail on" -cmd ".timeout 5000" -cmd "PRAGMA foreign_keys=ON;" "$DB"
        ;;
    status)
        pending=0
        for migration in "$MIGRATIONS"/*.up.sql; do
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
