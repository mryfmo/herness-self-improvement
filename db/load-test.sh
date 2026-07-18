#!/usr/bin/env sh

# @file db/load-test.sh
# @brief Measure concurrent SQLite writes against an isolated harness database.
# @description
#   Creates a new caller-owned database, runs forked writers, and prints
#   key=value latency, retry, integrity, and NFR-03 results.
# @arg $1 db-path New SQLite database path outside the live .agents directory.
# @option --writers N Number of writer processes; defaults to 8.
# @option --duration SEC Positive run duration in seconds; defaults to 20.
# @option --profile hx | mixed Write only hx events or mix one mock agmsg writer.
# @example
#   db/load-test.sh scratch.db --writers 8 --duration 20 --profile mixed

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MIGRATE="$SCRIPT_DIR/migrate.sh"
WRITERS=8
DURATION=20
PROFILE=hx

usage() {
    echo "usage: db/load-test.sh <db-path> [--writers N] [--duration SEC] [--profile hx|mixed]" >&2
    exit 2
}

die() {
    echo "load-test: $*" >&2
    exit 1
}

positive_int() {
    case "$2" in
        ''|*[!0-9]*|0) die "$1 must be a positive integer" ;;
    esac
}

[ "$#" -ge 1 ] || usage
DB=$1
shift

while [ "$#" -gt 0 ]; do
    [ "$#" -ge 2 ] || usage
    case "$1" in
        --writers) WRITERS=$2 ;;
        --duration) DURATION=$2 ;;
        --profile) PROFILE=$2 ;;
        *) usage ;;
    esac
    shift 2
done

positive_int writers "$WRITERS"
positive_int duration "$DURATION"
case "$PROFILE" in
    hx|mixed) ;;
    *) die "profile must be hx or mixed" ;;
esac
[ "$PROFILE" = hx ] || [ "$WRITERS" -ge 2 ] || die "mixed profile requires at least 2 writers"
[ ! -e "$DB" ] || die "database path must not already exist"

DB_DIR=$(dirname -- "$DB")
[ -d "$DB_DIR" ] || die "database parent directory does not exist"
DB_DIR=$(CDPATH= cd -- "$DB_DIR" && pwd -P)
DB="$DB_DIR/$(basename -- "$DB")"
if [ -d "$HOME/.agents" ]; then
    AGENTS_DIR=$(CDPATH= cd -- "$HOME/.agents" && pwd -P)
    case "$DB" in
        "$AGENTS_DIR"|"$AGENTS_DIR"/*) die "refusing to use a live .agents database path" ;;
    esac
fi

TMP=$(mktemp -d "${TMPDIR:-/tmp}/hx-load.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

"$MIGRATE" up "$DB"
SQLITE_CLI_VERSION=$(sqlite3 --version | awk '{print $1}')

python3 - "$DB" "$WRITERS" "$DURATION" "$PROFILE" "$TMP" "$SQLITE_CLI_VERSION" <<'PY'
import math
import multiprocessing as mp
import os
from pathlib import Path
import sqlite3
import sys
import time

db, writers_text, duration_text, profile, tmp, cli_version = sys.argv[1:]
writers = int(writers_text)
duration = int(duration_text)
run_id = f"{time.time_ns()}-{os.getpid()}"
interval = 0.01
# ponytail: Fixed pacing defines this test envelope; add a flag only when another rate is required.
max_busy_retries = 10
busy_timeout_ms = 5000


def connect():
    connection = sqlite3.connect(db, timeout=5, isolation_level=None)
    connection.execute("PRAGMA foreign_keys=ON")
    connection.execute(f"PRAGMA busy_timeout={busy_timeout_ms}")
    connection.execute("PRAGMA synchronous=NORMAL")
    return connection


def timestamp():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def write_event(connection, writer_id, sequence):
    if profile == "mixed" and writer_id == 0:
        connection.execute(
            """
            INSERT INTO agmsg_messages_mock(run_id, writer_id, sequence, ts, kind, payload)
            VALUES (?, ?, ?, ?, 'task.progress', ?)
            """,
            (run_id, writer_id, sequence, timestamp(), f"writer={writer_id} seq={sequence}"),
        )
    elif sequence % 2:
        connection.execute(
            """
            INSERT INTO hx_prompts(session_id, ts, role, content)
            VALUES (?, ?, 'user', ?)
            """,
            (
                f"load-{run_id}-{writer_id}",
                timestamp(),
                f"{run_id} writer={writer_id} seq={sequence}",
            ),
        )
    else:
        connection.execute(
            """
            INSERT INTO hx_tool_events(session_id, ts, tool, status, duration_ms)
            VALUES (?, ?, 'load-test', 'success', 0)
            """,
            (f"load-{run_id}-{writer_id}", timestamp()),
        )


def writer(writer_id, start_at, end_at):
    connection = connect()
    log_path = Path(tmp) / f"writer-{writer_id}.tsv"
    while time.monotonic() < start_at:
        time.sleep(0.001)
    next_write = start_at
    sequence = 0
    with log_path.open("w", encoding="utf-8") as log:
        while time.monotonic() < end_at:
            sequence += 1
            started = time.monotonic_ns()
            retries = 0
            success = 0
            while True:
                try:
                    write_event(connection, writer_id, sequence)
                    success = 1
                    break
                except sqlite3.OperationalError as error:
                    if not any(token in str(error).lower() for token in ("busy", "locked")):
                        raise
                    if retries >= max_busy_retries:
                        break
                    retries += 1
                    time.sleep(min(0.001 * (2 ** min(retries, 6)), 0.05))
            elapsed_ms = (time.monotonic_ns() - started) / 1_000_000
            log.write(f"{elapsed_ms:.3f}\t{retries}\t{success}\n")
            next_write += interval
            delay = next_write - time.monotonic()
            if delay > 0:
                time.sleep(delay)
    connection.close()


connection = connect()
connection.execute(
    """
    CREATE TABLE IF NOT EXISTS agmsg_messages_mock (
        id INTEGER PRIMARY KEY,
        run_id TEXT NOT NULL,
        writer_id INTEGER NOT NULL,
        sequence INTEGER NOT NULL,
        ts TEXT NOT NULL,
        kind TEXT NOT NULL,
        payload TEXT NOT NULL,
        UNIQUE(run_id, writer_id, sequence)
    )
    """
)
hx_writer_ids = range(writers) if profile == "hx" else range(1, writers)
connection.executemany(
    """
    INSERT INTO hx_sessions(session_id, agent_type, project, started_at, status)
    VALUES (?, 'load-test', 'P1-F1-T5', ?, 'running')
    """,
    [(f"load-{run_id}-{writer_id}", timestamp()) for writer_id in hx_writer_ids],
)
journal_mode = connection.execute("PRAGMA journal_mode").fetchone()[0]
synchronous = connection.execute("PRAGMA synchronous").fetchone()[0]
wal_autocheckpoint = connection.execute("PRAGMA wal_autocheckpoint").fetchone()[0]
connection.close()

start_at = time.monotonic() + 0.25
end_at = start_at + duration
context = mp.get_context("fork")
processes = [
    context.Process(target=writer, args=(writer_id, start_at, end_at))
    for writer_id in range(writers)
]
for process in processes:
    process.start()
for process in processes:
    process.join()
if any(process.exitcode != 0 for process in processes):
    raise SystemExit("writer process failed")

latencies = []
writer_counts = []
writer_retries = []
deadlocks = 0
for writer_id in range(writers):
    count = 0
    retries = 0
    with (Path(tmp) / f"writer-{writer_id}.tsv").open(encoding="utf-8") as log:
        for line in log:
            elapsed_text, retry_text, success_text = line.rstrip().split("\t")
            retry_count = int(retry_text)
            retries += retry_count
            if success_text == "1":
                count += 1
                latencies.append(float(elapsed_text))
            else:
                deadlocks += 1
    writer_counts.append(count)
    writer_retries.append(retries)


def percentile(values, percent):
    ordered = sorted(values)
    return ordered[max(0, math.ceil(len(ordered) * percent / 100) - 1)]


connection = connect()
session_ids = [f"load-{run_id}-{writer_id}" for writer_id in hx_writer_ids]
placeholders = ",".join("?" for _ in session_ids)
if session_ids:
    prompts = connection.execute(
        f"SELECT count(*) FROM hx_prompts WHERE session_id IN ({placeholders})",
        session_ids,
    ).fetchone()[0]
    tools = connection.execute(
        f"SELECT count(*) FROM hx_tool_events WHERE session_id IN ({placeholders})",
        session_ids,
    ).fetchone()[0]
else:
    prompts = tools = 0
agmsg_messages = connection.execute(
    "SELECT count(*) FROM agmsg_messages_mock WHERE run_id=?", (run_id,)
).fetchone()[0]
connection.close()

expected = sum(writer_counts)
actual = prompts + tools + agmsg_messages
missing = expected - actual
p50 = percentile(latencies, 50)
p95 = percentile(latencies, 95)
p99 = percentile(latencies, 99)
nfr03 = missing == 0 and deadlocks == 0 and p95 < 100

print(f"profile={profile}")
print(f"writers={writers}")
print(f"duration_sec={duration}")
print(f"target_interval_ms={interval * 1000:.0f}")
print(f"sqlite_cli_version={cli_version}")
print(f"python_sqlite_version={sqlite3.sqlite_version}")
print(f"journal_mode={journal_mode}")
print(f"busy_timeout_ms={busy_timeout_ms}")
print(f"synchronous={synchronous}")
print(f"wal_autocheckpoint={wal_autocheckpoint}")
for writer_id, (count, retries) in enumerate(zip(writer_counts, writer_retries)):
    print(f"writer_{writer_id}_writes={count}")
    print(f"writer_{writer_id}_busy_retries={retries}")
print(f"expected={expected}")
print(f"actual={actual}")
print(f"hx_prompts={prompts}")
print(f"hx_tool_events={tools}")
print(f"agmsg_messages={agmsg_messages}")
print(f"missing={missing}")
print(f"p50_ms={p50:.3f}")
print(f"p95_ms={p95:.3f}")
print(f"p99_ms={p99:.3f}")
print(f"busy_retries={sum(writer_retries)}")
print(f"deadlocks={deadlocks}")
print(f"throughput_writes_per_sec={expected / duration:.2f}")
print(f"nfr03={'PASS' if nfr03 else 'FAIL'}")
raise SystemExit(0 if nfr03 else 1)
PY
