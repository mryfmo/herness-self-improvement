# Task a005: P1-F1-T3 SQLite 体験ログスキーマ設計・実装

- task_id: a005
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-18
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 根拠: WORKPLAN v1.1 P1-F1-T3(NFR-03 の土台)/ SPEC 5.1・ADR-0002(旧 H002)
- 前提: a004 受入済み。全変更は PR 経由。依存追加禁止(sqlite3 CLI + POSIX sh / python3 stdlib)。

## Objective

sessions / prompts / tool_events / skill_runs / patterns / audit の 6 テーブルと FTS5 索引を、agmsg DB の拡張スキーマ(別ネームスペース)として DDL 化し、冪等なマイグレーションスクリプトとテスト、schema 文書を PR でマージする。

## 設計制約

- テーブル名は接頭辞 `hx_`(harness extension)で agmsg 既存テーブルと衝突回避。DB ファイル自体は注入可能(パス引数)とし、agmsg 同居/分離の判断(残存決裁 #4、F1-T5 の負荷試験後)に依存しない実装にする。
- 配置:
  - `db/migrations/0001_telemetry.up.sql` / `0001_telemetry.down.sql`
  - `db/migrate.sh`(`db/migrate.sh up|down|status <db-path>`。適用済み判定用の `hx_schema_migrations` テーブルで冪等化)
  - `ci/test_migrations.sh` — 一時 DB に up→up(冪等)→down→down(冪等)→up を実行し、各段でテーブル・索引の存在/不存在を検証
  - `docs/reference/telemetry-schema.md` — 全テーブル・列・索引の説明。frontmatter(owner / last-verified / freshness)付き
- スキーマ最小要件(SPEC 5.1 準拠、列は必要最小限 + 拡張用 `meta` JSON 列可):
  - `hx_sessions`(session_id PK, agent_type, project, started_at, ended_at, status)
  - `hx_prompts`(id PK, session_id FK, ts, role, content, masked INTEGER)
  - `hx_tool_events`(id PK, session_id FK, ts, tool, status, duration_ms, exit_code, error_summary)
  - `hx_skill_runs`(id PK, session_id FK, ts, skill_name, scope, outcome, corrected INTEGER)
  - `hx_patterns`(id PK, detected_at, cluster_key, template, freq, fail_rate, avg_duration_ms, score, artefact_kind, state, reason)
  - `hx_audit`(id PK, ts, actor, event, ref, detail)— append-only(UPDATE/DELETE を防ぐ trigger)
  - FTS5: `hx_prompts.content` と `hx_skill_runs.skill_name`+`outcome` を対象とした仮想テーブル(外部コンテンツ方式可)
- WAL / busy_timeout は接続時 PRAGMA として migrate.sh とテストで設定(恒久設定は F1-T5 で実測後確定)。
- CI(`.github/workflows/ci.yml`)に `ci/test_migrations.sh` 実行を追加(ubuntu の sqlite3 で可)。
- 文書とスキーマの整合: `ci/test_migrations.sh` 内で「DDL に現れる hx\_ テーブル名がすべて telemetry-schema.md に記載されている」ことを grep 検査。

## Allowed files

上記配置ファイルと `.github/workflows/ci.yml`(ステップ追加)、PR ブランチ操作。`.orchestration/` は a005 の 5 artifact のみ。

## Forbidden actions

- 実運用 agmsg DB(~/.agents/ 配下)への書込み・スキーマ適用(テストは一時 DB のみ)
- docs/ 4 文書変更、保護/フック変更、依存追加、force-push、main 直接 push、他リポジトリ操作

## Validation

```sh
ci/test_migrations.sh          # 全段 PASS の出力を記録
sqlite3 /tmp/hx-test.db < db/migrations/0001_telemetry.up.sql 相当を migrate.sh 経由で適用し .tables を記録
gh pr checks <PR番号>
```

## Expected artifacts

- report / validation / sandbox / learning / autoskill: `.orchestration/{reports,validation,sandboxes,learning,autoskill/runs}/a005-*.md`

## Done signal

`AGMSG-RESULT v1 task_id=a005 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
