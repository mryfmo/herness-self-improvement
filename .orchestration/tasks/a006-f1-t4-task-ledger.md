# Task a006: P1-F1-T4 タスク台帳スキーマ・状態機械実装

- task_id: a006
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-18
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 根拠: WORKPLAN v1.1 P1-F1-T4 / SPEC 5.3(状態機械・冪等キー・requeue)
- 前提: a005 受入済み(hx\_ スキーマ / db/migrate.sh が存在)。全変更は PR 経由。依存追加禁止。

## Objective

tasks / messages テーブルと状態遷移(queued→claimed→running→done|failed|blocked、requeue、冪等キー)を CLI サブコマンドとして実装し、全遷移パスのユニットテスト付きで PR マージする。

## 設計制約

- スキーマは a005 と同じ流儀: `db/migrations/0002_ledger.up.sql` / `.down.sql`(`hx_tasks`, `hx_task_messages`)。migrate.sh がそのまま適用できること。
  - `hx_tasks`(task_id PK, idempotency_key UNIQUE NOT NULL, state CHECK(queued|claimed|running|done|failed|blocked), owner, workplan_ref, branch, done_criteria, attempts INTEGER DEFAULT 0, max_attempts INTEGER DEFAULT 2, claimed_at, updated_at, detail)
  - `hx_task_messages`(id PK, task_id FK, ts, kind CHECK(task.assign|task.claim|task.progress|task.result|task.error|ctrl.pause|ctrl.resume|ctrl.kill), payload)
  - 状態遷移は SQL trigger または CLI 層で強制(不正遷移は拒否)。requeue = claimed/running でタイムアウト経過時に queued へ戻し attempts+1、attempts > max_attempts で failed 固定。
- CLI: `db/hx-task.sh <db-path> <subcommand>`(POSIX sh + sqlite3)。サブコマンド: `create|claim|start|progress|done|fail|block|requeue|show|list`。`create` は idempotency_key 重複時に既存 task_id を返し二重登録しない(冪等)。`--help` あり。
- SPEC 5.3 準拠: 作業指示ペイロードに WORKPLAN タスク ID(workplan_ref)+ ブランチ + 完了条件を必須とし、CLI が空を拒否。タイムアウト既定 15 分(引数で可変)。
- テスト: `ci/test_task_ledger.sh` — 一時 DB で (a) 正常全パス、(b) 不正遷移拒否(例: queued→running、done→claimed)、(c) 冪等 create、(d) requeue と attempts 上限、(e) 必須ペイロード欠落拒否。CI に追加。
- `docs/reference/telemetry-schema.md` に台帳 2 テーブルを追記(frontmatter の last-verified 更新可。これは 4 文書に含まれないため編集可)。

## Allowed files

`db/`、`ci/test_task_ledger.sh`、`.github/workflows/ci.yml`(ステップ追加)、`docs/reference/telemetry-schema.md`(台帳節追記)、PR ブランチ操作、`.orchestration/` の a006 5 artifact。

## Forbidden actions

- 実運用 agmsg DB への適用、docs/ 4 文書変更、保護/フック変更、依存追加、force-push、main 直接 push、他リポジトリ操作

## Validation

```sh
ci/test_task_ledger.sh      # (a)〜(e) の出力を記録
db/hx-task.sh /tmp/hx-ledger-test.db list の出力例を記録
gh pr checks <PR番号>
```

## Expected artifacts

- report / validation / sandbox / learning / autoskill: `.orchestration/{reports,validation,sandboxes,learning,autoskill/runs}/a006-*.md`

## Done signal

`AGMSG-RESULT v1 task_id=a006 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
