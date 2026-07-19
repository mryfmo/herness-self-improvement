---
owner: harness-operators
last-verified: 2026-07-19
freshness: 90d
---

# Agent teams integration

`vendor/customizable-agent-teams/` は、チーム設計を参照するための固定スナップ
ショットです。実行環境としては読み込みません。当方で使うのは役割分担の考え方
だけで、起動、連絡、状態管理、レビューは既存の Herdr、AGMSG、hx 台帳、CI に
接続します。

## 役割の対応

| 上流の役割 | 当方での扱い |
| --- | --- |
| Lead / Manager | `orchestrator` に集約。タスク契約、割当、受入判断を担当する |
| Strategist / Architect | 常設しない。設計判断が必要なタスクで orchestrator が明示的に補う |
| General / Hard / Frontend Worker | `worker`。台帳上のタスクを実装し、検証結果を返す |
| General Reviewer / Frontend Critic | `reviewer`。設定上の別名は `adversarial-verifier` |
| Research / Express Worker | 常設しない。必要になった時点で別タスクとして契約する |

`teams/team-config.yaml` は、この最小構成を宣言するための当方独自形式です。
YAML 全体を実装したものではなく、`version: 1`、`roles`、および各役割の
`name`、`alias`、`agent`、`model`、`effort`、`supervisor`、`parallel`
だけを受け付けます。Supervisor は同じファイルに定義済みの役割名か `none`
でなければなりません。

## 基盤の置き換え

| 上流の仕組み | 当方の仕組み |
| --- | --- |
| tmux のペイン | Herdr の managed agent pane |
| queue / state ファイル | AGMSG と `hx_tasks` / `hx_task_messages` |
| チーム起動スクリプト | `bin/hx-team.sh` と `bin/hx-worker.sh` |
| 上流 Make コマンド | 当方の PR、CI、台帳遷移 |
| 上流内のレビュー状態 | PR checks と orchestrator の受入判断 |

`bin/hx-team.sh spawn` は Herdr の `agent start` でペインを作り、その中で
`bin/hx-worker.sh` を起動します。`hx-worker.sh` は Codex 専用なので、現在の
Claude orchestrator は常駐プロセスとして扱い、このコマンドからは起動しません。
実起動には `HX_TEAM_TASK_ID` の内部 `hx-...` ID が必須です。起動時は設定した
model profile と effort を Codex CLI へ渡し、台帳 owner を `hx-team/<role>` に
します。`gpt56sol-high` profile は実行時に Codex の `gpt-5.6-sol` と high
reasoning へ変換します。

```sh
bin/hx-team.sh list
bin/hx-team.sh spawn --dry-run worker
HX_TEAM_TASK_ID=hx-example bin/hx-team.sh spawn worker
bin/hx-team.sh status
```

`status` は、`hx-<role>-<番号>` という Herdr agent 名と、同じ役割を owner に
持つ台帳タスクを一行に並べます。`HX_TEAM_CONFIG`、`HX_TEAM_HERDR`、
`HX_TEAM_WORKER`、`HX_DB_PATH` は隔離テスト用の差し替え口です。

現在の Codex 登録は一つの AGMSG identity を共有しています。別の役割が同じ受信
箱を先に読む事故を防ぐため、`hx-team.sh` は Codex 役割を一つずつ起動します。
また、worker には inbox 全体ではなく、指定された台帳 ID の履歴だけを処理する
よう指示します。役割別 identity が登録されるまでは、複数の Codex 役割を同時に
動かしません。
空き確認と Herdr 起動はリポジトリ単位の lock 内で行うため、同時に二つの
`spawn` を実行しても片方だけが起動します。

## 安全境界

- vendor 配下のスクリプト、設定、skills、Make ターゲットは実行しない
- vendor 配下をローカル skill の探索先へ追加しない
- 権限確認や sandbox を回避する起動オプションは統合層へ移さない
- Codex は `hx-worker.sh` の workspace-write sandbox と on-request approval で
  起動する
- 上流が前提とする追加ツールは、この統合のためにインストールしない

この境界により、上流スナップショットで見つかった危険な実行設定や、当方の skill
メタデータ基準を満たさない定義は、参照資料の外へ出ません。
