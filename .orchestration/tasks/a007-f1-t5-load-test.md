# Task a007: P1-F1-T5 SQLite 並行負荷検証

- task_id: a007
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-18
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 根拠: WORKPLAN v1.1 P1-F1-T5(NFR-03)/ 残存決裁 #4(agmsg DB 同居 or 分離)の判断材料
- 前提: a006 受入済み。全変更は PR 経由。依存追加禁止。

## Objective

WAL + busy_timeout 設定で並行 8 プロセス書込みの負荷試験ハーネスを作成し、10 分間の実測で NFR-03(イベント欠損 0・デッドロック 0・p95 書込み < 100ms)を判定、結果を docs/reference/sqlite-load-test.md に記録して PR マージする。

## 設計制約

- ハーネス: `db/load-test.sh <db-path> [--writers N] [--duration SEC] [--profile hx|mixed]`
  - `hx` プロファイル: 各 writer が hx_tool_events / hx_prompts へ連番付きイベントを書込み。
  - `mixed` プロファイル: 同一 DB に agmsg 相当の messages 書込み(同等スキーマの模擬テーブルで可)を 1 writer 分混在させ、同居シナリオの干渉を測る(残存決裁 #4 の判断材料)。
  - 各 writer は自プロセスの書込み件数と、書込みごとの所要時間(ms)を記録。busy/locked エラーはリトライし、リトライ回数を集計。
  - 終了後に集計: 期待件数 vs 実件数(欠損判定)、p50/p95/p99、busy リトライ総数、デッドロック(SQLITE_BUSY 恒久失敗)件数。
- 実測(worker のローカル実行):
  1. `hx` 8 writers × 600 秒
  2. `mixed` 8 writers × 600 秒
  - どちらも scratch DB(リポジトリ外の一時パス)で実行。実運用 agmsg DB は使用禁止。
- CI にはスモーク(8 writers × 20 秒)を追加(10 分試験は CI に載せない)。
- `docs/reference/sqlite-load-test.md`: frontmatter 付きで、環境(マシン・SQLite バージョン)、設定(PRAGMA)、2 プロファイルの結果表、NFR-03 判定、残存決裁 #4 への示唆(同居可否の推奨と根拠)を記載。
- 基準未達の場合: 設定調整(busy_timeout、synchronous、wal_autocheckpoint 等)を 1 回まで試み、再測。それでも未達なら「未達 + 調整内容 + Open Question 化」を文書に明記して PR は出す(fail-closed に停止はしない。判定は orchestrator が行う)。

## Allowed files

`db/load-test.sh`、`ci/`(スモーク追加)、`.github/workflows/ci.yml`(ステップ追加)、`docs/reference/sqlite-load-test.md`、PR ブランチ操作、`.orchestration/` の a007 5 artifact。

## Forbidden actions

- 実運用 agmsg DB(~/.agents/ 配下)の使用、docs/ 4 文書変更、保護/フック変更、依存追加、force-push、main 直接 push、他リポジトリ操作

## Validation

```sh
db/load-test.sh の 2 プロファイル実測ログ(件数一致・p95・リトライ数)を validation に全記録
ci スモークの出力
gh pr checks <PR番号>
```

## Expected artifacts

- report / validation / sandbox / learning / autoskill: `.orchestration/{reports,validation,sandboxes,learning,autoskill/runs}/a007-*.md`

## Done signal

`AGMSG-RESULT v1 task_id=a007 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
