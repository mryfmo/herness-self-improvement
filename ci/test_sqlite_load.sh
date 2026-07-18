#!/usr/bin/env sh

# @file ci/test_sqlite_load.sh
# @brief Smoke-test both SQLite load profiles with eight writer processes.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LOAD="$ROOT/db/load-test.sh"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/hx-load-smoke.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

expect_fail() {
    if "$@" >/dev/null 2>&1; then
        fail "unexpected success: $*"
    fi
}

assert_result() {
    file=$1
    grep -q '^writers=8$' "$file" || fail "writers in $file"
    grep -q '^journal_mode=wal$' "$file" || fail "WAL in $file"
    grep -q '^busy_timeout_ms=5000$' "$file" || fail "busy timeout in $file"
    grep -q '^missing=0$' "$file" || fail "missing writes in $file"
    grep -q '^deadlocks=0$' "$file" || fail "deadlocks in $file"
    grep -q '^nfr03=PASS$' "$file" || fail "NFR-03 in $file"
}

[ -x "$LOAD" ] || fail "missing executable db/load-test.sh"

expect_fail "$LOAD" "$TMP/bad-writers.db" --writers 0 --duration 1 --profile hx
expect_fail "$LOAD" "$TMP/bad-duration.db" --writers 8 --duration 0 --profile hx
expect_fail "$LOAD" "$TMP/bad-profile.db" --writers 8 --duration 1 --profile bad
touch "$TMP/existing.db"
expect_fail "$LOAD" "$TMP/existing.db" --writers 8 --duration 1 --profile hx
expect_fail "$LOAD" "$HOME/.agents/load-test-forbidden.db" --writers 8 --duration 1 --profile hx

"$LOAD" "$TMP/hx.db" --writers 8 --duration 2 --profile hx >"$TMP/hx.out"
"$LOAD" "$TMP/mixed.db" --writers 8 --duration 20 --profile mixed >"$TMP/mixed.out"
assert_result "$TMP/hx.out"
assert_result "$TMP/mixed.out"
grep -q '^profile=hx$' "$TMP/hx.out" || fail "hx profile"
grep -q '^duration_sec=20$' "$TMP/mixed.out" || fail "20-second smoke"
grep -q '^profile=mixed$' "$TMP/mixed.out" || fail "mixed profile"
grep -Eq '^agmsg_messages=[1-9][0-9]*$' "$TMP/mixed.out" || fail "mixed agmsg writes"

cat "$TMP/hx.out"
cat "$TMP/mixed.out"
