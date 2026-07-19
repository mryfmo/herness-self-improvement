# a005 Validation

## Test-first evidence

runner 実装前:

```sh
ci/test_migrations.sh
```

```text
FAIL: missing executable db/migrate.sh
exit=1
```

判定: PASS。実装前に先行 test が対象欠如を検出した。

## Migration and behavior

```sh
sh -n db/migrate.sh ci/test_migrations.sh
ci/test_migrations.sh
```

```text
PASS: up/up, FTS5, foreign keys, append-only audit, WAL, busy_timeout
PASS: down/down
PASS: final up
PASS: schema documentation table names
```

判定: PASS。test-owned temporary database でのみ実行した。

## Schema objects and status

up 後の主要 tables:

```text
hx_audit
hx_patterns
hx_prompts
hx_prompts_fts
hx_schema_migrations
hx_sessions
hx_skill_runs
hx_skill_runs_fts
hx_tool_events
```

FTS shadow tables と、FTS 同期6件・audit 保護2件の計8 triggers も存在する。`status` は初期 `pending`、up 後 `applied`、down 後 `pending` を返した。

判定: PASS。

## Invariants

- prompts content の FTS5 検索: PASS
- skill name/outcome の FTS5 検索: PASS
- orphan session foreign key の拒否: PASS
- `hx_audit` UPDATE の拒否: PASS
- `hx_audit` DELETE の拒否: PASS
- journal mode `wal`: PASS
- connection busy timeout `5000`: PASS
- SQL error 時に継続しない `.bail on`: PASS（runner と test双方）

## Documentation

up migration から抽出した全 `hx_` table名と `hx_schema_migrations` が `docs/reference/telemetry-schema.md` に存在する。reference は `owner`、`last-verified`、`freshness` frontmatter、全 table/column、FTS indexes、同期・監査 triggers、connection policy を記載する。

判定: PASS。

## Existing CI

```text
.....
----------------------------------------------------------------------
Ran 5 tests

OK
```

既存 rules-generator tests と新規 migration test を続けて実行した。

判定: PASS。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/4
state=MERGED
mergeCommit=f69b4e49ec3293b4a0a5578d93efa6773b0c3fa7
push ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29627812215/job/88035534747
pull-request ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29627840260/job/88035615460
CodeRabbit walkthrough completed; actionable feedbackなし
```

判定: PASS。

## Allowed and forbidden diff

PR #4 の変更は task が許可した次の6 files のみ:

```text
.github/workflows/ci.yml
ci/test_migrations.sh
db/migrate.sh
db/migrations/0001_telemetry.down.sql
db/migrations/0001_telemetry.up.sql
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

repository に Crit gate target は未実装。PR の全6 files、commit trailer、CI、CodeRabbit walkthrough を `gh` で確認した。
