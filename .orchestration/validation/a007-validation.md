# a007 Validation

## Test-first evidence

実装前:

```sh
ci/test_sqlite_load.sh
```

```text
FAIL: missing executable db/load-test.sh
exit=1
```

判定: PASS。

## hx profile: 8 writers × 600 seconds

```text
profile=hx
writers=8
duration_sec=600
target_interval_ms=10
sqlite_cli_version=3.51.0
python_sqlite_version=3.53.1
journal_mode=wal
busy_timeout_ms=5000
synchronous=1
wal_autocheckpoint=1000
writer_0_writes=60000
writer_0_busy_retries=0
writer_1_writes=60000
writer_1_busy_retries=0
writer_2_writes=59999
writer_2_busy_retries=0
writer_3_writes=60000
writer_3_busy_retries=0
writer_4_writes=60000
writer_4_busy_retries=0
writer_5_writes=60000
writer_5_busy_retries=0
writer_6_writes=60000
writer_6_busy_retries=0
writer_7_writes=60000
writer_7_busy_retries=0
expected=479999
actual=479999
hx_prompts=240000
hx_tool_events=239999
agmsg_messages=0
missing=0
p50_ms=1.414
p95_ms=10.856
p99_ms=37.350
busy_retries=0
deadlocks=0
throughput_writes_per_sec=800.00
nfr03=PASS
```

追加確認:

```text
PRAGMA integrity_check=ok
database_bytes=55193600
result_log_sha256=039801ee4b7f2e2dded83f43b5b768b2d6d73892a9eef6d001276359404199d7
```

判定: PASS。

## mixed profile: 8 writers × 600 seconds

```text
profile=mixed
writers=8
duration_sec=600
target_interval_ms=10
sqlite_cli_version=3.51.0
python_sqlite_version=3.53.1
journal_mode=wal
busy_timeout_ms=5000
synchronous=1
wal_autocheckpoint=1000
writer_0_writes=60000
writer_0_busy_retries=0
writer_1_writes=60000
writer_1_busy_retries=0
writer_2_writes=60000
writer_2_busy_retries=0
writer_3_writes=60000
writer_3_busy_retries=0
writer_4_writes=60000
writer_4_busy_retries=0
writer_5_writes=60000
writer_5_busy_retries=0
writer_6_writes=60000
writer_6_busy_retries=0
writer_7_writes=60000
writer_7_busy_retries=0
expected=480000
actual=480000
hx_prompts=210000
hx_tool_events=210000
agmsg_messages=60000
missing=0
p50_ms=1.521
p95_ms=10.909
p99_ms=37.444
busy_retries=0
deadlocks=0
throughput_writes_per_sec=800.00
nfr03=PASS
```

追加確認:

```text
PRAGMA integrity_check=ok
database_bytes=56573952
result_log_sha256=a851bd23f8ebc553b1b92d2b8d4a4cefc74fcccf3c53d24877ed0be5dba0f9e9
```

判定: PASS。

## CI smoke output

main上の最終run:

```text
profile=hx
writers=8
duration_sec=2
target_interval_ms=10
journal_mode=wal
busy_timeout_ms=5000
expected=1599
actual=1599
missing=0
p50_ms=1.498
p95_ms=10.153
p99_ms=36.680
busy_retries=0
deadlocks=0
throughput_writes_per_sec=799.50
nfr03=PASS

profile=mixed
writers=8
duration_sec=20
target_interval_ms=10
journal_mode=wal
busy_timeout_ms=5000
expected=16000
actual=16000
hx_prompts=7000
hx_tool_events=7000
agmsg_messages=2000
missing=0
p50_ms=1.179
p95_ms=10.625
p99_ms=38.283
busy_retries=0
deadlocks=0
throughput_writes_per_sec=800.00
nfr03=PASS
```

判定: PASS。

## Busy retry recovery

8 writers ×10秒 hx run中に外部write lockを6秒保持:

```text
writer_0_busy_retries=1
writer_1_busy_retries=1
writer_2_busy_retries=1
writer_3_busy_retries=1
writer_4_busy_retries=1
writer_5_busy_retries=1
writer_6_busy_retries=1
writer_7_busy_retries=1
expected=8000
actual=8000
missing=0
busy_retries=8
deadlocks=0
nfr03=PASS
```

判定: PASS。busy/locked errorはretryされ、恒久失敗や欠損なし。

## Input and safety guards

- writers 0: rejected
- duration 0: rejected
- unknown profile: rejected
- existing database path: rejected
- home `.agents` database path: rejected before creation

判定: PASS。

## Existing suites

```text
rules generator: 5 tests OK
telemetry migration: PASS
task ledger: PASS
shell syntax: PASS
ShellCheck excluding established SC1007 CDPATH idiom: PASS
long-run log/document parity: PASS
```

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/6
state=MERGED
mergeCommit=7fff6ec64060df7499c25248c4c201dba43f7cb7
push ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29665507864/job/88135155709
pull-request ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29665514893/job/88135173090
CodeRabbit=SUCCESS; actionable feedbackなし
```

判定: PASS。

## Allowed and forbidden diff

PR #6 の変更はtaskが許可した次の4 filesのみ:

```text
.github/workflows/ci.yml
ci/test_sqlite_load.sh
db/load-test.sh
docs/reference/sqlite-load-test.md
```

実運用agmsg DB、指定外docs、protection、hooks、dependencies、他repositoryは変更なし。repository内にtest DB、WAL、SHM residueはない。

判定: PASS。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repositoryにCrit gate targetは未実装。PRの全4 files、commit trailer、CI、CodeRabbit walkthroughを`gh`で確認した。
