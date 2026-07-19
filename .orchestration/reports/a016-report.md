# a016 監査所見の実装修正レポート

## Status

ready_for_review

## Result

- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/14
- Source commit: `5fb24b02d777d10f4bb7abccc11b3a4b3c9e5083`
- Squash merge: `53db170c5f4470a9fd146621995a08455a78978b`
- Branch: `a016/migration-freeze-fixes`（merge 後に local / remote とも削除）
- Frozen manifest SHA-256: `27cda89fc74801c7d4cdeaf3ef776f5015f3a7ecd80d8a8f51ff5497d120221d`

## Implementation

- A014-17: `db/migrate.sh status` が `migrations/*.up.sql` を列挙し、各 migration の applied / pending を表示するようにした。1件でも pending なら終了値 1 を返す。将来 migration が追加されても status 側の固定リスト更新は不要である。
- A014-17: migration と task ledger のテスト期待値を 0001 / 0002 の2行へ更新した。
- A014-17: 0002 の migration entry と ledger tables だけを削除した scratch DB で、`0001_telemetry applied`、`0002_ledger pending`、終了値 1 を確認する回帰テストを追加した。
- A014-04: `docs/decisions/` と `docs/specs/discipline-v1.0.md` を frozen paths へ追加し、manifest を24件から35件へ更新した。
- A014-03: hash-freeze を変更権限の機械的強制とは呼ばず、manifest 更新を伴う明示的 diff の強制可視化と説明した。権限の実体は NFR-01 の人間承認であり、checkout 外の trust root はユーザー決裁 D1 待ちと記録した。
- `.github/workflows/ci.yml` は既存手順で全要件を検証できるため変更していない。

## Test-first evidence

テストだけを先に変更した時点では、現行実装が次のとおり失敗した。

```text
ci/test_migrations.sh
FAIL: up status

ci/test_task_ledger.sh
FAIL: migration status
```

実装後は両テストと 0002 欠落ケースが成功した。

## PR flow

- GitHub 操作は `gh` から開始し、外部 Web は取得していない。
- commit は `fix(migrations): report all migration status`、本文 trailer は `Agent: worker`。
- PR 本文に全変更、検証、禁止範囲を記載し、末尾に `Agent: worker` footer を付けた。
- push CI、pull-request CI、merge 後 main CI はすべて成功した。
- CodeRabbit status は success。review と inline comment はいずれも 0 件だった。
- PR #14 を squash mergeした。main と origin/main は `53db170c5f4470a9fd146621995a08455a78978b` で一致する。

## Scope

PR #14 は task が許可した6ファイルだけを変更した。4文書、ADR群、三軸規律本文、workflow、protection/hooks、dependencies、実運用 agmsg DB は変更していない。既存 dirty worktree、先行 artifacts、並行 task files は変更・stage していない。
