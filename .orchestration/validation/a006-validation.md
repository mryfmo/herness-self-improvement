# a006 Validation

## Test-first evidence

CLI 実装前:

```sh
ci/test_task_ledger.sh
```

```text
FAIL: missing executable db/hx-task.sh
exit=1
```

判定: PASS。実装前に先行 test が対象欠如を検出した。

## Task ledger suite

```sh
sh -n db/migrate.sh db/hx-task.sh ci/test_migrations.sh ci/test_task_ledger.sh
shellcheck -e SC1007 -s sh db/migrate.sh db/hx-task.sh ci/test_task_ledger.sh
ci/test_task_ledger.sh
```

```text
PASS: normal terminal paths and invalid transitions
PASS: idempotent create and SQL quoting
PASS: timed requeue and attempts ceiling
PASS: required payload validation
PASS: ledger up/up/down/down/up
```

SC1007 は repository 既存の `CDPATH= cd` 慣用句に対する warning のため除外し、その他の ShellCheck findings は0件。

判定: PASS。

## State and adversarial coverage

- queued→claimed→running→done: PASS
- queued→claimed→running→failed: PASS
- queued→claimed→running→blocked: PASS
- running→queued timeout requeue: PASS
- claimed→queued timeout requeue: PASS
- attempts 3 > max_attempts 2 で failed 固定: PASS
- queued→running の CLI/direct SQL 拒否: PASS
- done→claimed の拒否: PASS
- invalid message kind の CHECK 拒否: PASS
- timeout 未経過 requeue の拒否: PASS
- quoted idempotency/branch/criteria の安全な round-trip: PASS

## Idempotency and required payload

同じ idempotency key の create は同一 task_id、`hx_tasks` 1 row、`task.assign` 1 rowを返した。workplan_ref、branch、done_criteria、owner、progress payload の空値と、非整数 max-attempts/timeout はすべて拒否した。

判定: PASS。

## CLI list example

```sh
db/hx-task.sh /tmp/hx-ledger-test.db list
```

```text
task_id                              state    owner         workplan_ref  branch      attempts  max_attempts
hx-8d732bc75926f3dd91c2ae5e290932e4  running  codex-worker  P1-F1-T4      f1-t4/demo  0         2
```

同じ隔離DBの migration ledger:

```text
0001_telemetry
0002_ledger
```

検証後に database、WAL、SHM を削除した。

## Existing CI and migration compatibility

```text
.....
Ran 5 tests
OK
PASS: up/up, FTS5, foreign keys, append-only audit, WAL, busy_timeout
PASS: down/down
PASS: final up
PASS: schema documentation table names
```

判定: PASS。既存 telemetry migration と rules generator に regression なし。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/5
state=MERGED
mergeCommit=603d784440bbf6d60874d2d352fe0a1e12476e66
push ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29661193857/job/88124017647
pull-request ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29661204253/job/88124046053
CodeRabbit walkthrough completed; actionable feedbackなし
```

判定: PASS。

## Allowed and forbidden diff

PR #5 の変更は task が許可した次の7 files のみ:

```text
.github/workflows/ci.yml
ci/test_task_ledger.sh
db/hx-task.sh
db/migrate.sh
db/migrations/0002_ledger.down.sql
db/migrations/0002_ledger.up.sql
docs/reference/telemetry-schema.md
```

実運用 agmsg DB、指定外 docs、protection、hooks、dependencies、他 repository は変更なし。repository 内に test DB、WAL、SHM residue はない。

判定: PASS。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repository に Crit gate target は未実装。PR の全7 files、commit trailer、CI、CodeRabbit walkthrough を `gh` で確認した。
