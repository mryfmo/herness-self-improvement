---
owner: mryfmo
last-verified: 2026-07-19
freshness: 90d
---

# SQLite concurrent load test

## Decision

NFR-03 passes for both profiles. At 8 writers and approximately 800 writes/second, both runs had zero missing writes, zero permanent `SQLITE_BUSY` failures, and p95 below 100 ms.

Use one colocated SQLite database for the initial deployment. The mixed profile changed p95 from 10.856 ms to 10.909 ms (+0.053 ms, +0.49%) with unchanged throughput and no retries. Revisit separation if production hardware, write rate, payload size, or isolation requirements differ materially from this test.

## Environment

| Item | Value |
|---|---|
| Date | 2026-07-19 |
| Machine | MacBook Air `Mac14,2` |
| CPU | Apple M2, 8 logical cores, arm64 |
| Memory | 16 GiB |
| OS | macOS 26.5.2, build 25F84 |
| SQLite CLI | 3.51.0 |
| Python SQLite | 3.53.1 |
| Harness | `db/load-test.sh` |

Both runs used a new scratch database outside the repository and outside `.agents`. The live agmsg database was not used.

## Method

Each run used 8 operating-system writer processes for 600 seconds. Writers targeted a 10 ms interval, or about 100 writes/second each. Every writer recorded each acknowledged write latency and retry count in its own temporary TSV.

- `hx`: all 8 writers alternated between `hx_prompts` and `hx_tool_events`.
- `mixed`: 7 writers alternated between the hx tables while 1 writer wrote `task.progress` rows to an agmsg-equivalent mock messages table in the same database.

Expected count is the sum of acknowledged writer records. Actual count is independently queried from the database after all writers exit. A busy/locked error is retried at most 10 times; exhaustion is counted as a permanent failure (`deadlocks` in harness output).

## SQLite settings

| Setting | Value |
|---|---|
| `journal_mode` | `wal` |
| `busy_timeout` | 5,000 ms |
| `synchronous` | `NORMAL` (`1`) |
| `wal_autocheckpoint` | 1,000 pages |
| Foreign keys | enabled on writer connections |

No tuning retry was needed.

## Results

| Profile | Expected | Actual | Missing | p50 ms | p95 ms | p99 ms | Busy retries | Permanent failures | Writes/sec | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| hx | 479,999 | 479,999 | 0 | 1.414 | 10.856 | 37.350 | 0 | 0 | 800.00 | PASS |
| mixed | 480,000 | 480,000 | 0 | 1.521 | 10.909 | 37.444 | 0 | 0 | 800.00 | PASS |

The hx run wrote 240,000 prompts and 239,999 tool events. The mixed run wrote 210,000 prompts, 210,000 tool events, and 60,000 mock agmsg messages. `PRAGMA integrity_check` returned `ok` for both databases.

## NFR-03 judgment

| Criterion | Threshold | hx | mixed |
|---|---|---|---|
| Event loss | 0 | 0 | 0 |
| Permanent busy/deadlock failure | 0 | 0 | 0 |
| p95 write latency | < 100 ms | 10.856 ms | 10.909 ms |

Overall result: **PASS**.

This supports colocation for the measured single-host workload. It does not establish behavior above 8 writers, above 800 writes/second, with larger payloads, on network filesystems, or under sustained readers/checkpoint pressure; those conditions require a new measurement before changing the deployment envelope.
