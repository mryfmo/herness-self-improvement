# SPEC-HARNESS-SELF-IMPROVEMENT v1.0
# Harness Engineering 自己改善システム — 仕様書

- Status: Draft（人間レビュー待ち）
- 作成日: 2026-07-18
- 対象読者: Claude Code（オーケストレーター、Fable-5 effort=high）/ Codex（ワーカー、gpt-5.6-sol effort=high）/ 部門関係者
- 関連: docs/reference/REPORT-HARNESS-SELF-IMPROVEMENT-v1.0.md（意思決定根拠）/ docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md（作業計画）/ docs/decisions/ADR-HARNESS-SELF-IMPROVEMENT-v1.0.md（ADR-H001〜H006）
- アーキテクチャ決定は本文に埋め込まず ADR を参照する（本書は要件と構造の記述に徹する）

---

## 1. Goal

一度構築して終わりではなく、稼働しながら自動的に自己改善が繰り返される Harness Engineering 基盤を、複数プロジェクト・複数ユーザー・複数業務にまたがる社内標準として構築する。具体的には、LLM Wiki・Agents Memory・Workflows・SKILLS・Hooks・Rules・SubAgents が相互連動する自己改善サイクルを、Claude Code（オーケストレーター）+ Codex（ワーカー）+ agmsg（エージェント間メッセージング）の実行環境上に実現する。

## 2. Scope

**含む**
- ハーネスリポジトリ（以下「本リポジトリ」）の構造・規約・CI
- 体験ログ層（SQLite）スキーマと収集 Hooks
- 知識還流パイプライン（Reflector / Curator）
- SKILLS 自動生成・自動組合せ・自動最適化の各機構
- 3 層スコープ（全社 / プロジェクト / 個人）と昇格パイプライン
- ガバナンス制御（スキャン・署名・deny-by-default・監査・kill switch）
- Claude Code ⇄ Codex ⇄ agmsg の連携プロトコル

**含まない（非スコープ）**
- モデルの重み更新・ファインチューニング（ADR-H002 で不採用）
- 外部メモリ SaaS（Mem0 / Zep 等）の導入（ADR-H002。将来の拡張余地としてインターフェースのみ規定）
- 第三者スキルマーケットプレイスからの取込（ADR-H006 で禁止）
- 各プロジェクト固有スキルの中身の作成（本基盤はその「器」と改善ループを提供する）

## 3. Assumptions

- A-1: Claude Code は Skills / Hooks / Subagents / Plugins / marketplace 機能を利用可能なバージョンで運用される。
- A-2: Codex CLI は Agent Skills 標準（SKILL.md）および AGENTS.md を解釈できるバージョンで運用される。
- A-3: agmsg は SQLite ベースの CLI であり、スキーマ拡張（新規テーブル追加）が可能である。単一ホスト運用を v1 前提とする。
- A-4: 全 artefact は Git 管理され、保護ブランチ + 必須 CI + レビュー承認が設定できる。
- A-5: AIDD Platform の closed gates / data guards / evidence store は型付きコードとして再利用可能である。
- A-6: 人間の承認者（部門管理者・プロジェクトオーナー）が PR 承認フローに参加できる。
- A-7: 対象リポジトリ・組織名・承認者名簿は TBD(HUMAN)。

## 4. 要件

### 4.1 機能要件（FR）

- FR-01: すべてのハーネス artefact（Wiki / SKILLS / Rules / Hooks 設定 / SubAgents / Workflows）は Git 管理され、変更は PR 経由でのみ反映されること。
- FR-02: Claude Code の Hooks により、セッション・プロンプト・ツール実行・スキル起動・完了/失敗イベントが SQLite 体験ログへ自動記録されること（欠損時もセッション本体は継続する best-effort、ただし記録失敗は監査ログに残す）。
- FR-03: Reflector / Curator サブエージェントが体験ログから教訓を抽出し、Wiki / SKILLS へのデルタ更新 PR を自動起票できること。一括再生成による更新を CI が拒否すること。
- FR-04: 繰り返しプロンプトパターンの検出器が、頻度・失敗率・所要時間に基づき候補を抽出し、SKILLS / Hooks / Rules / SubAgents の組合せドラフトを生成できること。
- FR-05: 生成されたスキルは隔離環境での検証と評価スイートに合格しない限り PR 起票されないこと（fail-closed）。
- FR-06: プロンプト内容に応じた既存 SKILLS の自動適用は、SKILL.md frontmatter（description / triggers）と Claude Code / Codex のネイティブ自動起動機構で実現し、スキル索引（SQLite FTS5）が探索を補助すること。
- FR-07: SKILLS 自動最適化は 3 トリガー（定期 GC / 失敗閾値超過 / 依存変化検知）で起動し、デルタ更新 PR として提案されること。
- FR-08: 全社 / プロジェクト / 個人の 3 層スコープが分離され、優先順位（プロジェクト > 個人 > 全社）と一方向昇格フロー（個人 → プロジェクト → 全社）が機能すること。
- FR-09: スキル取込・変更時に静的スキャン（動的コンテキスト実行検出・到達先許可リスト・悪性パターン照合）が CI で必須実行され、不合格はマージ不可であること。
- FR-10: Claude Code ⇄ Codex の作業授受は agmsg メッセージ + SQLite タスク台帳（状態機械）でのみ行われ、成果物は PR としてのみ提出されること。
- FR-11: kill switch フラグにより、自動生成・GC・還流の全バックグラウンドジョブを即時停止できること。
- FR-12: すべての自動変更（PR・マージ・却下・スキャン結果）が evidence store に監査記録されること。
- FR-13: CLAUDE.md と AGENTS.md は単一ソース（rules.src.md + スコープ設定）から生成され、手編集は CI が検出して拒否すること。

### 4.2 非機能要件（NFR）

- NFR-01（安全）: 自己改善パイプライン自身（本仕様の実装コード・CI 定義・Hooks 設定）の変更は常に人間承認必須。自動マージ対象外。
- NFR-02（安全）: Codex ワーカーは常にサンドボックス + 最小権限（ネットワーク許可リスト、書込み先はワークツリー限定）で起動。
- NFR-03（信頼性）: SQLite は WAL モード + busy_timeout 設定。並行 8 エージェント書込みでイベント欠損ゼロ（F1 で実測）。
- NFR-04（信頼性）: タスク台帳はワーカー無応答タイムアウトで requeue。全操作は冪等キー必須。
- NFR-05（性能）: 体験ログ書込みが対話レイテンシに与える影響 < 100ms/イベント（Hooks は非同期化可）。
- NFR-06（保守性）: CLAUDE.md / AGENTS.md は各 120 行以内の「マップ」に保つ（詳細は Wiki へリンク）。CI が行数超過を警告。
- NFR-07（監査性）: 任意のスキル/Wiki ページについて、由来（どのセッション・どの教訓から生成/更新されたか）を evidence store から追跡可能。
- NFR-08（可搬性）: SKILLS は Agent Skills 標準に準拠し、Claude Code / Codex の双方で無改変動作。

## 5. アーキテクチャ

決定根拠は ADR-H001〜H006 を参照。本節は構造の記述のみ。

### 5.1 コンポーネント構成

```
┌─────────────────────────── Git（単一の真実源）────────────────────────────┐
│ harness リポジトリ                                                        │
│  ├ CLAUDE.md / AGENTS.md      ← rules.src.md から生成（マップ、≤120行）    │
│  ├ docs/ (LLM Wiki)            ← decisions/ plans/ specs/ reference/       │
│  ├ .claude/skills/<name>/      ← SKILL.md + scripts/ + eval/               │
│  ├ .claude/agents/             ← SubAgents 定義（reflector, curator, gc…） │
│  ├ .claude/hooks/ + settings   ← テレメトリ収集・deny-by-default           │
│  ├ .claude/commands|plugins/   ← Workflows（スキル合成の定型フロー）        │
│  └ ci/                         ← link-check, skill-lint, scan, eval, 生成物検証│
│ marketplace リポジトリ（全社スコープの Plugin 配布）                        │
└──────────────────────────────────────────────────────────────────────────┘
        ▲ PR のみ                     │ clone / checkout
        │                             ▼
┌────────────────────┐  agmsg   ┌────────────────────┐
│ Claude Code         │◀───────▶│ Codex CLI           │
│ (orchestrator)      │  SQLite  │ (worker, sandbox)   │
│  Hooks → telemetry  │  台帳    │  AGENTS.md 準拠     │
└─────────┬──────────┘          └────────────────────┘
          │ write（Hooks 経由）
          ▼
┌──────────────────────────────────────────────┐
│ SQLite（agmsg 拡張 = 体験ログ層 + タスク台帳）  │
│  sessions / prompts / tool_events / skill_runs │
│  patterns（マイニング結果）/ tasks / messages   │
│  FTS5 索引（skill index / wiki index）          │
└─────────┬────────────────────────────────────┘
          │ read（夜間 / 閾値トリガー）
          ▼
┌──────────────────────────────────────────────┐
│ 自己改善ジョブ群（SubAgents、kill switch 配下）  │
│  pattern-miner → skill-drafter → verifier      │
│  reflector → curator（デルタ PR）               │
│  harness-gc（重複排除・陳腐化削除・整合検査）    │
└─────────┬────────────────────────────────────┘
          ▼ PR（人間/CI ゲート） → Git へ還流（ループ閉成）

横断: evidence store（全イベント監査）/ closed gates / data guards（AIDD 再利用）
```

### 5.2 データフロー（自己改善サイクル 1 周）

1. 収集: 利用者が Claude Code で作業 → Hooks（SessionStart / UserPromptSubmit / PostToolUse / Stop / SubagentStop）が体験ログへ記録。
2. 検出: pattern-miner（夜間）が繰り返しパターン・失敗集中箇所・所要時間の外れ値を抽出し patterns テーブルへ。
3. 生成/改善: skill-drafter が新規スキルドラフトを、reflector/curator が既存 Wiki・SKILLS へのデルタを作成。
4. 検証: verifier が隔離ワークツリーでサロゲートタスクを実行し、eval/ の評価スイートで合否判定。
5. 提案: 合格分のみ PR 起票（Owner・影響スコープ・根拠セッション ID を本文に自動記載）。
6. 統制: CI（link-check / skill-lint / scan / 生成物検証）→ 承認レベル判定 → 人間承認 → マージ。
7. 配布: 全社スコープは marketplace 更新、プロジェクトスコープはリポジトリ内で即時有効。
8. 計測: 次周期の skill_runs 統計が改善効果を示し、劣化時は curator がロールバック PR を提案。

### 5.3 連携プロトコル（agmsg / タスク台帳）

- メッセージ種別（v1）: `task.assign` `task.claim` `task.progress` `task.result` `task.error` `ctrl.pause` `ctrl.resume` `ctrl.kill`
- タスク台帳状態機械: `queued → claimed → running → (done | failed | blocked)`、`failed` は再試行上限（既定 2 回、冪等キー必須）まで requeue。
- ペイロード規約: 作業指示は常に「WORKPLAN のタスク ID（P1-Fx-Ty）+ 対象ブランチ + 完了条件の引用」を含む。自由文のみの指示は禁止。
- 成果物提出: Codex は直接 push せず、ブランチ + PR URL を `task.result` で返す。
- タイムアウト: `claimed` 後 15 分無 `progress` で requeue（値は TBD(HUMAN) 調整可）。

### 5.4 スコープモデル

| 層 | 置き場所 | 配布 | 変更承認 |
|---|---|---|---|
| 全社（業務標準） | marketplace リポジトリ（Plugin） | marketplace 経由で全員へ | 部門管理者 + CI |
| プロジェクト | 各リポジトリ .claude/ | リポジトリ clone に同梱 | プロジェクトオーナー + CI |
| 個人 | ~/.claude/ | 本人のみ | 本人（ただし scan は必須） |

- 優先順位: プロジェクト > 個人 > 全社（同名衝突時。frontmatter `scope` と命名接頭辞で衝突自体を回避）。
- 昇格: skill_runs 統計が閾値（利用回数 ≥ N かつ成功率 ≥ M%、TBD(HUMAN)）を超えた個人/プロジェクトスキルについて、curator が汎化ドラフトを作成し上位スコープへ PR。降格・廃止も同フロー。

## 6. 機能仕様

### 6.1 F-GEN: SKILLS/Hooks/Rules/SubAgents 自動生成

- 入力: patterns テーブル（クラスタ化された繰り返しプロンプト群 + 関連セッション軌跡）、skill-creator 規約、既存スキル索引（重複回避）。
- 処理: (1) 候補スコアリング（頻度 × 失敗率 × 平均所要時間）、(2) artefact 種別判定 — 手続き知識 → SKILL、決定的強制が必要 → Hook、常時規範 → Rules への追記、隔離実行が適切 → SubAgent、複合定型 → Workflow、(3) ドラフト生成（SKILL.md + 必要 scripts + eval/ ケース ≥ 3）、(4) 隔離検証（EvoSkills 型: サロゲートタスクをスキルあり/なしで実行し差分測定）。
- 出力: 検証合格ドラフトの PR（根拠パターン ID・検証ログ添付）。不合格は patterns に理由付きで記録し再試行は次周期。
- トリガー: 夜間バッチ + 手動 `/harness:propose`。
- 制約: 同一周期の起票上限（既定 5 件）。動的コンテキスト（`!` 実行）を含むドラフトは生成禁止。

### 6.2 F-ROUTE: 既存 SKILLS の自動組合せ適用

- 入力: 利用者プロンプト、スキル索引（FTS5: name / description / triggers / scope）。
- 処理: 一次選択はエージェントネイティブの description マッチに委ね、索引は (a) セッション開始時の利用可能スキル一覧提示、(b) 明示検索 `/harness:skills <query>`、(c) ミスマッチ検出（起動されたが手順逸脱したケースの記録）に用いる。合成は Workflow（コマンド/Plugin）として宣言的に定義し、実行時の暗黙合成に依存しない。
- 出力: skill_runs レコード（起動スキル・成否・訂正有無）。
- 品質保証: SkillCoach 型ルーブリック（選択の適切さ・手順遵守・出力妥当性）を eval に含め、F-OPT の入力にする。

### 6.3 F-OPT: SKILLS 自動最適化

- 入力: skill_runs 統計、ユーザー訂正イベント、依存変化（ツール/API バージョン）、Wiki との矛盾検出結果。
- 処理: reflector が失敗・訂正から教訓を抽出 → curator がデルタ（行追加 / 行更新 / 重複統合 / 陳腐化削除）を構成 → verifier が回帰評価（当該スキルの eval/ 全ケース + 影響隣接スキルのスモーク）。一括リライトは CI が diff 比率（既定: 変更行 > 40% で要人間承認に格上げ）で検出。
- 出力: デルタ更新 PR（改善根拠の統計を本文に自動記載）/ 劣化検知時はロールバック PR。
- トリガー: (a) 夜間 harness-gc、(b) スキル別失敗率が移動平均 + 閾値超過、(c) 依存変化検知。
- 完了指標: スキル別成功率・訂正率・平均所要時間の周次トレンド。

### 6.4 F-WIKI: LLM Wiki 維持・還流

- 構造: docs/decisions（ADR）、docs/plans（計画書）、docs/specs、docs/reference、docs/lessons（教訓、curator の主な還流先）。全ページ frontmatter に owner / last-verified / freshness(TTL) 必須。
- 処理: curator がセッション教訓を lessons へデルタ追記 → 蓄積が閾値を超えた教訓群を reference/specs へ昇格提案。harness-gc が TTL 切れページを検出し再検証タスクを起票。CI が相互リンク・frontmatter を検査。
- CLAUDE.md / AGENTS.md: rules.src.md から生成。Wiki への「地図」のみ記載し、規範詳細は docs/ 参照とする。

### 6.5 F-GOV: ガバナンス制御

1. 取込制限: スキル/Plugin の導入元は marketplace と本リポジトリのみ。settings で外部 marketplace を無効化。
2. 静的スキャン（CI 必須）: SKILL.md 内の動的コンテキスト実行検出（検出＝即不合格）、scripts の到達先ドメイン許可リスト照合、MalSkillBench / ToxicSkills 系悪性パターン照合、秘密情報検出。
3. 署名・出所: マージ時に artefact ハッシュ + 由来（生成ジョブ ID / セッション ID）を evidence store へ記録。SHA-256 ハッシュ凍結は AIDD の機構を再利用。
4. 実行時強制: PreToolUse deny-by-default（許可リスト外コマンド・リポジトリ外書込み・未許可ネットワークをブロック）。ハーネス artefact への直接書込みは PR フロー外で全ブロック。
5. 自己改変防護: 自己改善パイプライン自身のコード・CI・Hooks 設定の変更 PR は自動マージ不可・人間承認必須（NFR-01）。
6. kill switch: `ctrl.kill`（agmsg）または DB フラグで全バックグラウンドジョブ即時停止。SessionStart Hook が停止状態を表示。
7. 監査: 全自動変更イベントを evidence store に append-only 記録。月次で監査レポートを自動生成。

### 6.6 F-BRIDGE: Claude Code ⇄ Codex 連携

- 役割: Claude Code = 計画分解・委任・レビュー・PR 管理。Codex = 台帳タスクの実装・検証実行。
- 授受: 5.3 のプロトコルに準拠。Codex 起動時ラッパーが (a) AGENTS.md 存在検証、(b) サンドボックス設定、(c) kill switch 確認を行う（Codex 側に Hooks 相当がないための代替決定点）。
- 帰属: 全コミット・PR に `Agent: orchestrator|worker` トレーラーを必須化（CI 検査）。

## 7. インターフェース将来拡張（v1 では実装しない）

- 外部メモリ基盤アダプタ: 体験ログ読出し口を `memory_export` ビューとして定義し、将来 Graphiti 等へ供給可能にする（ADR-H002 の再評価条件を満たした場合のみ）。
- マルチホスト化: SQLite → リモート台帳への移行パス（台帳アクセスを CLI 経由に限定してあるため差替え可能）。

## 8. ADR 一覧（別紙）

- ADR-H001: Git を単一の真実源とし、変更を PR 駆動に限定する
- ADR-H002: メモリを二層構造（SQLite 体験層 + Git 恒久層）とし、外部メモリ SaaS と重み更新型自己改善を不採用とする
- ADR-H003: 知識還流・スキル最適化に ACE 型（Reflector/Curator、デルタ更新、grow-and-refine）を採用する
- ADR-H004: 自動生成・自動最適化を fail-closed の 6 段 PR パイプラインに限定する（無人デプロイ禁止）
- ADR-H005: 3 層スコープ（全社 marketplace / プロジェクト / 個人）と一方向昇格パイプラインを採用する
- ADR-H006: スキル供給網ガバナンス（社内レジストリ限定・スキャン必須・動的コンテキスト禁止・自己改変の人間承認）
