#!/usr/bin/env sh

# @file ci/test_evidence_gates.sh
# @brief Verify the evidence store, hash freeze gate, and secret data guard.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
EVIDENCE="$ROOT/db/hx-evidence.sh"
HASH_FREEZE="$ROOT/ci/hash-freeze.py"
SECRET_SCAN="$ROOT/ci/secret-scan.py"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/hx-evidence-gates.XXXXXX")
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

[ -x "$EVIDENCE" ] || fail "missing executable db/hx-evidence.sh"
[ -x "$HASH_FREEZE" ] || fail "missing executable ci/hash-freeze.py"
[ -x "$SECRET_SCAN" ] || fail "missing executable ci/secret-scan.py"

DB="$TMP/evidence.db"
"$ROOT/db/migrate.sh" up "$DB"
record_id=$("$EVIDENCE" "$DB" record actor-a change.proposed ref-1 '{"basis":"REQ-12","ok":true}')
[ "$record_id" = 1 ] || fail "record id"
[ "$(sqlite3 "$DB" "SELECT actor || '|' || event || '|' || ref || '|' || detail FROM hx_audit;")" = 'actor-a|change.proposed|ref-1|{"basis":"REQ-12","ok":true}' ] || fail "record round trip"
"$EVIDENCE" "$DB" trace ref-1 | grep -q 'change.proposed' || fail "trace output"
"$EVIDENCE" "$DB" list | grep -q 'actor-a' || fail "list output"
expect_fail sqlite3 "$DB" "UPDATE hx_audit SET event='changed';"
expect_fail sqlite3 "$DB" "DELETE FROM hx_audit;"
expect_fail "$EVIDENCE" "$DB" record actor-a event ref-1 not-json
expect_fail "$EVIDENCE" "$TMP/missing.db" list
expect_fail "$EVIDENCE" "$HOME/.agents/a008-forbidden.db" list

LIVE_HOME="$TMP/home"
LIVE_DB="$LIVE_HOME/.agents/live.db"
mkdir -p "$LIVE_HOME/.agents"
"$ROOT/db/migrate.sh" up "$LIVE_DB"
expect_fail env HOME="$LIVE_HOME" "$EVIDENCE" "$LIVE_DB" list
expect_fail env HOME="$LIVE_HOME" HX_EVIDENCE_ALLOW_LIVE=0 "$EVIDENCE" "$LIVE_DB" list
live_id=$(env HOME="$LIVE_HOME" HX_EVIDENCE_ALLOW_LIVE=1 \
    "$EVIDENCE" "$LIVE_DB" record operator phase.dryrun.start phase-f2 '{"approved":true}')
[ "$live_id" = 1 ] || fail "live opt-in record id"
expect_fail env HOME="$LIVE_HOME" HX_EVIDENCE_ALLOW_LIVE=1 \
    "$EVIDENCE" "$LIVE_HOME/.agents/missing.db" list
sqlite3 "$LIVE_HOME/.agents/unmigrated.db" "SELECT 1;" >/dev/null
expect_fail env HOME="$LIVE_HOME" HX_EVIDENCE_ALLOW_LIVE=1 \
    "$EVIDENCE" "$LIVE_HOME/.agents/unmigrated.db" list
echo "PASS: evidence record, trace, validation, and append-only enforcement"

FROZEN="$TMP/frozen"
mkdir -p "$FROZEN/ci" "$FROZEN/db" "$FROZEN/githooks" "$FROZEN/.github/workflows"
printf '%s\n' 'githooks/' 'ci/' 'db/' '.github/workflows/' >"$FROZEN/ci/frozen-paths.txt"
printf 'gate-v1\n' >"$FROZEN/githooks/pre-push"
printf 'check-v1\n' >"$FROZEN/ci/check.py"
printf 'schema-v1\n' >"$FROZEN/db/schema.sql"
printf 'name: CI\n' >"$FROZEN/.github/workflows/ci.yml"
(
    cd "$FROZEN"
    "$HASH_FREEZE" freeze >/dev/null
    "$HASH_FREEZE" verify >/dev/null
    printf 'changed\n' >>githooks/pre-push
    expect_fail "$HASH_FREEZE" verify
    "$HASH_FREEZE" freeze >/dev/null
    "$HASH_FREEZE" verify >/dev/null
    printf 'new\n' >db/new.sql
    expect_fail "$HASH_FREEZE" verify
    "$HASH_FREEZE" freeze >/dev/null
    rm db/new.sql
    expect_fail "$HASH_FREEZE" verify
    "$HASH_FREEZE" freeze >/dev/null
    "$HASH_FREEZE" verify >/dev/null
)
echo "PASS: frozen modification, addition, deletion, and manifest refresh"

SECRET="$TMP/secret"
mkdir -p "$SECRET/ci"
printf '# exact secret values allowed for deterministic fixtures only\n' >"$SECRET/ci/secret-allowlist.txt"
prefix=ghp
dummy="${prefix}_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
printf 'credential=%s\n' "$dummy" >"$SECRET/sample.txt"
(
    cd "$SECRET"
    if "$SECRET_SCAN" >scan.out 2>&1; then
        fail "dummy secret was not detected"
    fi
    grep -q 'github_token' scan.out || fail "secret class missing"
    if grep -q "$dummy" scan.out; then
        fail "secret value leaked in finding"
    fi
    printf '%s\n' "$dummy" >>ci/secret-allowlist.txt
    "$SECRET_SCAN" >/dev/null
)
echo "PASS: dummy secret detection, non-disclosure, and exact allowlist"
