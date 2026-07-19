# a005 P1-F1-T3 Telemetry Schema Report

## Status

ready_for_review

## Result

- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/4
- Squash merge: `f69b4e49ec3293b4a0a5578d93efa6773b0c3fa7`
- Branch: `f1-t3/telemetry-schema`（merge 後に削除）

## Implementation choice

SQLite 3 と POSIX shell のみを使った。migration runner は呼び出し側から database path を必須で受け取り、実運用 agmsg DB を暗黙に参照しない。`hx_` namespace と注入された path により、telemetry を agmsg DB に同居させるか分離するかという F1-T5 後の判断を保留したまま schema を検証できる。

migration は `.bail on`、明示 transaction、`hx_schema_migrations` ledger、`IF NOT EXISTS` / `IF EXISTS` で、SQL error 時の部分 commit を防ぎつつ up/down を冪等化した。追加 dependency はない。

## Completed procedure

1. 先行 test を作り、`db/migrate.sh` 不在で失敗することを確認した。
2. `hx_sessions`、`hx_prompts`、`hx_tool_events`、`hx_skill_runs`、`hx_patterns`、`hx_audit` と migration ledger を作成した。
3. prompts content と skill-run name/outcome の external-content FTS5 tables、insert/update/delete 同期 triggers を作成した。
4. audit UPDATE/DELETE を `RAISE(ABORT)` で拒否する append-only triggers を作成した。
5. runner に `up|down|status <db-path>`、WAL、5000 ms busy timeout、foreign-key enforcement を実装した。
6. system temporary database だけを使う test で up/up/down/down/up、FTS5、FK、append-only、connection settings、文書 table-name parity を検証した。
7. frontmatter と全 table/column/index/trigger 説明を持つ schema reference を追加し、CI から migration test を実行した。
8. `6e88bbf feat(db): add telemetry schema migrations`（`Agent: worker`）を feature branch へ push し、PR #4 の push/PR CI が green 後に squash mergeした。

## Judgment

P1-F1-T3 の schema、検索、監査不変条件、接続設定、冪等 migration を依存なしで満たした。実運用 agmsg DB への schema 適用、禁止された docs/protection/hooks、他 repository、force-push、main 直接 pushはいずれも行っていない。
