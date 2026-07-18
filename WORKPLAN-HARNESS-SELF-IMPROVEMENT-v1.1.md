# WORKPLAN-HARNESS-SELF-IMPROVEMENT v1.1
# Harness Engineering 自己改善システム — 作業計画書

## Status

- 状態: 決裁反映済み・F1 着手可
- 作成日: 2026-07-18
- 実行体制: Claude Code（orchestrator, Fable-5 effort=high）+ Codex（worker, gpt-5.6-sol effort=high）+ agmsg。Claude Code（本セッション系列）が、AGMSG-TASK / AGMSG-RESULT / AGMSG-ACCEPTANCE により Codex の herdr pane 常駐ワーカーを運用する。プロトコル詳細は SPEC 5.3 を参照。
- 前提文書: SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md（要件・構造）/ ADR-HARNESS-SELF-IMPROVEMENT-v1.0.md（決定）
- 表記: タスクは `P1-F<フェーズ>-T<タスク>`。未決の人間判断は残存決裁事項として明記する。各タスクに `Owner: orchestrator | worker` を必須付与。

### Decision Log

| # | 決裁日 | 決裁者 | 決裁 |
|---|---|---|---|
| 1 | 2026-07-18 | mryfmo | 本作業の成果物は既存 WORKPLAN の v1.1 改訂とする。 |
| 2 | 2026-07-18 | mryfmo | GitHub private `mryfmo/herness-self-improvement` を現名で使用し、main 保護・PR 必須・CI 必須とする。 |
| 3 | 2026-07-18 | mryfmo | mryfmo が部門管理者・プロジェクトオーナー・教訓判定者の全承認ロールを単独で兼任する。 |
| 4 | 2026-07-18 | mryfmo | ADR-0001〜0006 を新規採番し、H001〜H006 を旧呼称として併記する。 |
| 5 | 2026-07-18 | mryfmo | 本ディレクトリを `git init` して本体化し、4 文書は F1 で `docs/` へ移設する。 |

## Goal

SPEC の FR-01〜FR-13 / NFR-01〜NFR-08 を満たす自己改善ハーネス基盤を構築し、収集 → 検出 → 生成/改善 → 検証 → 提案 → 統制 → 配布 → 計測の自己改善サイクルが本番運用で 1 周以上完走する状態に到達する。

## Scope

SPEC 2 章に準拠。本計画は基盤構築と自己改善ループの稼働までを扱い、各プロジェクト固有スキルの量産は運用移行後の日常運用に委ねる。

## Assumptions

SPEC 3 章（A-1〜A-6）に準拠し、A-7 は以下の確定値で置き換える。追加:
- 対象リポジトリは GitHub private `mryfmo/herness-self-improvement`。main 保護 + PR 必須 + CI 必須を設定する。
- 単独運用とし、承認ロールはすべて mryfmo が兼任する。将来の複数人化は CODEOWNERS 導入で対応する。
- NFR-01 の人間承認とは、自動生成 PR を mryfmo がレビュー・マージする行為を指す。単独運用でも自己改変は自動マージせず fail-closed を維持する。
- 昇格閾値（利用回数 N・成功率 M%）とタイムアウト値の初期値: 本計画の既定値で開始し F9 で見直し

## Design

SPEC 5〜6 章および ADR-0001〜0006（旧呼称 ADR-H001〜H006）を参照（本計画には再掲しない）。

## Current State

- ハーネスリポジトリ: 未作成
- agmsg: 稼働中（メッセージング機能のみ。テレメトリ/台帳スキーマ未拡張）
- AIDD 由来ガバナンス部品（closed gates / data guards / evidence store）: 型付きコードとして存在、本リポジトリへの組込みは未実施
- 既存 SKILLS 資産: 各プロジェクトに散在（ADR 作成スキル等）。棚卸し未実施

## 依存関係・クリティカルパス

- フェーズ依存: F1 → F2 → {F3, F4（並行可。いずれも F2 のドライランデータが前提）} → F5 → F6 → F7 → F8 → F9。
- 前倒し可能: F8-T1 / F8-T2 / F8-T3 は F4 完了後であれば前倒しできる。
- クリティカルパス: 固定カレンダー期間を持つ F2-T7（観測 2 週）→ F3-T6（還流 2 週）→ F4-T9（生成 2 週）→ F6-T7（最適化 4 週）→ F9-T7（無人 1 週）。実装工数と独立に最短約 11 週を要する。

| マイルストーン | 到達条件 | 固定観測期間の目安 |
|---|---|---|
| M1 基盤完 | F1 受入 | なし |
| M2 観測データ蓄積 | F2 受入 | 2 週 |
| M3 還流ループ実証 | F3 受入 | 2 週 |
| M4 生成パイプライン実証 | F4 受入 | 2 週 |
| M5 全スキル標準化 | F5 受入 | なし |
| M6 最適化ループ実証 | F6 受入 | 4 週 |
| M7 3 層スコープ稼働 | F7 受入 | なし |
| M8 ガバナンス完成 | F8 受入 | なし |
| M9 運用移行 | F9 完了 | 1 週 |

## Implementation

各タスクの体裁: 作業内容 / 検証 / 完了条件。フェーズ内は原則タスク番号順に実施（並行可の箇所は明記）。

---

### Phase F1: 基盤整備（リポジトリ骨格・SQLite スキーマ・CI 土台）

**P1-F1-T0 リポジトリブートストラップ** — Owner: orchestrator
- 作業: 本ディレクトリで `git init` → 初回コミット → `gh repo create mryfmo/herness-self-improvement --private` → push → main 保護 + PR 必須 + CI 必須（空 CI）設定を実施。4 文書を WORKPLAN → `docs/plans/`、SPEC → `docs/specs/`、REPORT → `docs/reference/`、ADR 束 → `docs/decisions/` へ移設し（ADR 分割は F1-T8）、文書間相互参照パスを更新する。
- 検証: 保護設定により main への直接 push が拒否されること。相互参照リンクが解決すること。
- 完了: 初回 PR がフロー経由でマージされ、以後全変更が PR 駆動になる。

**P1-F1-T1 ハーネスリポジトリ骨格作成** — Owner: worker
- 作業: SPEC 5.1 のディレクトリ構成（docs/ .claude/skills|agents|hooks|commands ci/）と README、保護ブランチ設定手順書を作成。
- 検証: `tree` 出力が SPEC 5.1 と一致。CI が空実行で green。
- 完了: main 保護 + PR 必須 + CI 必須が有効。

**P1-F1-T2 rules.src.md と CLAUDE.md/AGENTS.md 生成器** — Owner: worker
- 作業: 単一ソース rules.src.md から CLAUDE.md / AGENTS.md を生成するスクリプトと CI 検査（手編集検出・120 行超過警告）を実装（FR-13, NFR-06）。
- 検証: rules.src.md 変更 → 両ファイル再生成が一致。手編集コミットが CI で fail。
- 完了: 生成器がユニットテスト付きで main にマージ。

**P1-F1-T3 SQLite 体験ログスキーマ設計・実装** — Owner: worker
- 作業: sessions / prompts / tool_events / skill_runs / patterns / audit テーブルと FTS5 索引を agmsg DB の拡張スキーマ（別ネームスペース）として DDL 化。マイグレーションスクリプト作成。
- 検証: DDL 適用 → 全テーブル・索引存在。マイグレーションの up/down が冪等。
- 完了: スキーマ v1 が docs/reference/telemetry-schema.md と一致した状態でマージ。

**P1-F1-T4 タスク台帳スキーマ・状態機械実装** — Owner: worker
- 作業: tasks / messages テーブルと状態遷移（queued→claimed→running→done|failed|blocked、requeue、冪等キー）を CLI サブコマンドとして実装（SPEC 5.3）。
- 検証: 状態遷移の全パスをユニットテストで網羅。不正遷移が拒否される。
- 完了: `agmsg task` 系コマンドがヘルプ・テスト付きでマージ。

**P1-F1-T5 SQLite 並行負荷検証** — Owner: worker
- 作業: WAL + busy_timeout 設定で並行 8 プロセス書込み負荷試験ハーネスを作成し実測（NFR-03）。
- 検証: 10 分間の並行書込みでイベント欠損 0・デッドロック 0。p95 書込み < 100ms。
- 完了: 実測レポートを docs/reference/sqlite-load-test.md として記録。基準未達なら設定調整して再測、それでも未達は Open Question 化。

**P1-F1-T6 evidence store / closed gates / data guards 組込み** — Owner: worker
- 作業: AIDD 由来の 3 部品を本リポジトリの ci/ と Hooks から呼べる形で組込み（AIDD 側の SHA-256 ハッシュ凍結機構を含む）。
- 検証: サンプルイベントが evidence store に append-only 記録される。改竄検知テスト合格。
- 完了: 3 部品の呼出し口が文書化されマージ。

**P1-F1-T7 Wiki 骨格と frontmatter 規約** — Owner: worker
- 作業: docs/decisions|plans|specs|reference|lessons の骨格、frontmatter（owner / last-verified / freshness）テンプレート、CI リンク検査・frontmatter 検査を実装（F-WIKI）。
- 検証: リンク切れ・frontmatter 欠落を含むテスト PR が CI で fail。
- 完了: 検査が必須 CI に組込み済み。

**P1-F1-T8 ADR-0001〜0006（旧呼称 H001〜H006）の正式登録** — Owner: orchestrator
- 作業: 別紙 ADR 6 件を `docs/decisions/ADR-NNNN-<slug>.md` として ADR-0001〜0006 に新規採番し、各本文冒頭に旧呼称 H001〜H006 を併記して登録。
- 検証: リンク検査合格。WORKPLAN/SPEC からの参照が解決。
- 完了: 6 件が Accepted 状態でマージ（mryfmo 承認）。

**P1-F1-T9 Phase F1 受入** — Owner: orchestrator
- 作業: T0〜T8 の成果物横断レビュー、SPEC との差分一覧作成、mryfmo へ承認依頼。
- 検証: 下記 Tests 全合格。
- 完了: 下記 Done Criteria 充足を evidence store に記録。

**F1 Tests**: リポジトリ CI green / スキーマ・台帳の全ユニットテスト合格 / 負荷試験基準達成 / 生成器・検査系の fail ケース実証。
**F1 Done Criteria**: FR-01・FR-13・NFR-03・NFR-06 の土台が稼働。ADR 6 件 Accepted。リポジトリ設定・承認者・ADR 採番の決裁が反映済み。
**F1 Open Questions**: agmsg DB の同居 or 分離 DB（負荷試験結果で判断、TBD(HUMAN)）/ marketplace リポジトリの分離時期。

---

### Phase F2: 観測層（テレメトリ収集 Hooks）

**P1-F2-T1 収集 Hooks 実装（SessionStart/UserPromptSubmit）** — Owner: worker
- 作業: セッション開始・プロンプト投入イベントを非同期で体験ログへ記録する Hook スクリプト実装（FR-02, NFR-05）。個人情報・秘密情報のマスキング規則を適用。
- 検証: 実セッションで records 生成。マスキングのユニットテスト合格。レイテンシ実測 < 100ms。
- 完了: Hook が settings に登録されマージ。

**P1-F2-T2 収集 Hooks 実装（PostToolUse/Stop/SubagentStop）** — Owner: worker
- 作業: ツール実行結果・セッション終了・サブエージェント完了の記録。失敗イベントに終了コード・stderr 要約を付与。
- 検証: 成功/失敗の両パスで期待レコード。記録失敗時にセッションが継続し audit に残る（best-effort 検証）。
- 完了: 全対象イベントの記録がマージ。

**P1-F2-T3 skill_runs 記録（スキル起動・成否・訂正検知）** — Owner: worker
- 作業: スキル起動の検知、直後のユーザー訂正（やり直し指示・手動修正）のヒューリスティック検知を実装し skill_runs へ記録。
- 検証: 起動 → 成功 / 起動 → 訂正の再現シナリオで正しく分類。誤検知率をサンプル 30 件で確認し docs に記録。
- 完了: 分類規則が docs/reference/telemetry-schema.md に追記されマージ。

**P1-F2-T4 Codex 側テレメトリ（起動ラッパー）** — Owner: worker
- 作業: Codex 起動ラッパーに (a) AGENTS.md 検証、(b) サンドボックス設定、(c) kill switch 確認、(d) 実行ログの台帳・体験ログへの反映を実装（F-BRIDGE）。
- 検証: ラッパー経由起動で 4 機能が動作。kill switch ON 時に起動拒否。
- 完了: ラッパーが worker 実行の唯一経路として文書化されマージ。

**P1-F2-T5 メトリクス定義と日次集計ジョブ** — Owner: worker
- 作業: スキル別成功率・訂正率・所要時間、失敗集中箇所、繰り返しプロンプト頻度の集計ビューと日次ジョブを実装。
- 検証: 合成データで集計値が手計算と一致。
- 完了: docs/reference/metrics.md に指標定義が確定しマージ。

**P1-F2-T6 監査記録の配線（FR-12 前半）** — Owner: worker
- 作業: F2 で発生する全自動イベントを evidence store へ二重記録。
- 検証: 体験ログと evidence store の件数照合が一致。
- 完了: 照合スクリプトが CI ナイトリーに登録。

**P1-F2-T7 2 週間の観測ドライラン** — Owner: orchestrator
- 作業: 実業務セッションで収集のみ稼働（自動改変なし）。データ品質・マスキング漏れ・欠損をレビュー。
- 検証: 欠損率 < 1%、マスキング漏れ 0 件（mryfmo による自己監査 30 件）。
- 完了: ドライランレポートを docs/lessons/ へ記録。

**P1-F2-T8 Phase F2 受入** — Owner: orchestrator
- 作業/検証/完了: F1 受入と同様の横断レビュー・mryfmo 承認・記録。

**F2 Tests**: 全 Hooks のイベント別ユニット/結合テスト / レイテンシ実測 / best-effort 動作 / 照合一致。
**F2 Done Criteria**: FR-02 完全稼働。実データ 2 週間分が蓄積し、メトリクスが日次で出力される。
**F2 Open Questions**: 訂正検知ヒューリスティックの精度目標値 / 保持期間・匿名化ポリシー TBD(HUMAN)。

---

### Phase F3: 知識還流層（Reflector / Curator / Wiki）

**P1-F3-T1 reflector サブエージェント定義** — Owner: worker
- 作業: 失敗・訂正・長時間セッションから教訓（事象 / 原因 / 対処 / 適用条件の 4 項目構造）を抽出する SubAgent を .claude/agents/ に定義。
- 検証: ドライラン蓄積データ 20 セッションで教訓抽出。mryfmo のレビューで有用判定 ≥ 70%。
- 完了: 定義とプロンプトがマージ。抽出結果はまだ PR 化しない。

**P1-F3-T2 curator サブエージェント定義（デルタ更新器）** — Owner: worker
- 作業: 教訓を docs/lessons へのデルタ（追記・既存行更新・重複統合・陳腐化削除のいずれか 1 種別/変更）として構成する SubAgent を定義（ADR-0003、旧呼称 ADR-H003）。一括リライト検出（diff 比率 > 40% で mryfmo 承認へ格上げ）を CI 側に実装。
- 検証: 4 種別それぞれのデルタ生成をテストケースで確認。一括リライト PR が CI で格上げされる。
- 完了: 定義 + CI 検査がマージ。

**P1-F3-T3 還流 PR パイプライン** — Owner: worker
- 作業: reflector → curator → ブランチ作成 → PR 起票（根拠セッション ID・教訓本文を自動記載）→ evidence 記録の一連を夜間ジョブ化。起票上限（既定 5 件/夜）実装。
- 検証: E2E で PR が起票され本文要素が揃う。上限超過時に翌夜へ繰越。
- 完了: kill switch 配下でジョブが登録されマージ。

**P1-F3-T4 lessons → reference/specs 昇格提案** — Owner: worker
- 作業: 同一テーマの教訓が閾値（既定 3 件）を超えた場合に恒久ページへの昇格ドラフトを curator が作成するロジックを追加。
- 検証: 合成教訓データで昇格提案 PR が生成される。
- 完了: 昇格規則が docs/reference/curation-rules.md に記載されマージ。

**P1-F3-T5 鮮度 GC（TTL 切れ検出・再検証タスク起票）** — Owner: worker
- 作業: frontmatter freshness を走査し、期限切れページの再検証タスクを台帳へ起票する harness-gc の第 1 機能を実装。
- 検証: TTL 切れテストページで台帳タスクが生成される。
- 完了: 夜間ジョブに組込みマージ。

**P1-F3-T6 還流ループ 2 週間試験運用** — Owner: orchestrator
- 作業: 実データで還流 PR を運用し、mryfmo 承認でマージ。採択率・修正率を計測。
- 検証: 起票 PR のうち採択（そのまま/軽微修正でマージ）≥ 60%。重大な誤還流（事実誤り）0 件。
- 完了: 試験運用レポートを docs/lessons/ へ記録。未達時は T1/T2 のプロンプト改訂後に 1 週間再試験。

**P1-F3-T7 CLAUDE.md/AGENTS.md への反映経路** — Owner: worker
- 作業: 恒久化された規範のうち「常時制約」該当分を rules.src.md へ反映する提案経路（curator → rules PR、常に mryfmo 承認）を実装。
- 検証: サンプル規範で rules PR が生成され、生成器経由で両ファイルが更新される。
- 完了: 経路が文書化されマージ。

**P1-F3-T8 データフロー整合検査** — Owner: worker
- 作業: 「セッション → 教訓 → デルタ → PR → evidence」の追跡クエリ（NFR-07）を実装。
- 検証: 任意の還流 PR から根拠セッションまで 1 クエリで到達。
- 完了: 追跡手順が docs/reference/audit-trace.md に記載されマージ。

**P1-F3-T9 Phase F3 受入** — Owner: orchestrator
- 作業/検証/完了: 横断レビュー・Tests 全合格・mryfmo 承認・evidence 記録。

**F3 Tests**: デルタ 4 種別テスト / 一括リライト検出 / E2E 起票 / 追跡クエリ / 採択率実測。
**F3 Done Criteria**: FR-03 稼働。Wiki が実データ由来の教訓で成長し、由来追跡が可能。
**F3 Open Questions**: 採択率目標の恒久値（TBD(HUMAN)）/ lessons の粒度規約の追加要否。

---

### Phase F4: SKILLS 自動生成パイプライン（評価器を含む）

**P1-F4-T1 pattern-miner 実装** — Owner: worker
- 作業: prompts/tool_events を対象に、埋め込みクラスタリング + 正規化テンプレート抽出で繰り返しパターンを検出し、頻度 × 失敗率 × 所要時間でスコアリングして patterns へ書込むジョブを実装（F-GEN 入力）。
- 検証: 合成データ（既知パターン 10 種を混入）で再現率 ≥ 8/10。実データで上位 20 件を人間レビューし妥当性確認。
- 完了: ジョブが夜間登録されマージ。レビュー結果を docs/lessons/ へ記録。

**P1-F4-T2 artefact 種別判定器** — Owner: worker
- 作業: パターンごとに SKILL / Hook / Rules 追記 / SubAgent / Workflow の種別を判定する規則（F-GEN 処理(2)）を実装。判定根拠を patterns に記録。
- 検証: 種別別テストケース各 3 件で期待判定。曖昧ケースは「保留」に落ちる。
- 完了: 判定規則が docs/reference/generation-rules.md に記載されマージ。

**P1-F4-T3 skill-drafter 実装** — Owner: worker
- 作業: skill-creator 規約準拠の SKILL.md + scripts + eval/（ケース ≥ 3、合否判定スクリプト付き）を生成するドラフタを実装。既存スキル索引照合で重複回避。動的コンテキスト実行を含む出力の生成を禁止（ADR-0006、旧呼称 ADR-H006）。
- 検証: サンプルパターン 5 件からドラフト生成。skill-lint（F4-T6）合格。動的コンテキスト混入テストで生成拒否。
- 完了: ドラフタがマージ。

**P1-F4-T4 隔離検証器（verifier）実装** — Owner: worker
- 作業: 隔離ワークツリー + サンドボックスでサロゲートタスクを「スキルあり/なし」両条件で実行し、成功率・所要時間の差分を測定する検証器を実装（EvoSkills 型）。
- 検証: 既知の良スキル/悪スキルのサンプルで合否が正しく分かれる。
- 完了: 検証器と合否基準（差分有意性の既定則）が文書化されマージ。

**P1-F4-T5 評価スイート基盤（skill eval harness）** — Owner: worker
- 作業: 全スキル共通の eval 実行器（eval/ ケースの一括実行・回帰検知・結果の skill_runs 連携）を実装。SkillCoach 型ルーブリック（選択適切性・手順遵守・出力妥当性）を組込む。
- 検証: 既存スキル 3 件に eval を付与し実行。意図的な劣化改変で回帰検知が働く。
- 完了: `ci/skill-eval` が PR 必須チェックに登録されマージ。

**P1-F4-T6 skill-lint / セキュリティスキャン** — Owner: worker
- 作業: frontmatter 必須項目・命名規約・scope 検査、動的コンテキスト実行検出、scripts の到達先許可リスト照合、悪性パターン照合（MalSkillBench 系シグネチャ）、秘密情報検出を CI 化（FR-09、ADR-0006、旧呼称 ADR-H006）。
- 検証: 悪性サンプル（テスト専用に無害化したもの）10 件が全件 fail。正常スキルが pass。
- 完了: 必須 CI 登録・検出規則の文書化を完了しマージ。

**P1-F4-T7 生成 PR フロー統合** — Owner: worker
- 作業: miner → 判定 → drafter → verifier → eval → PR 起票（根拠パターン・検証ログ添付、上限 5 件/周期）を kill switch 配下の夜間ジョブとして接続（FR-04/FR-05）。
- 検証: E2E で「不合格ドラフトは PR 化されない」「合格ドラフトのみ PR 化」を実証。
- 完了: ジョブ登録・運用手順書マージ。

**P1-F4-T8 Hooks/Rules/SubAgent/Workflow ドラフト生成** — Owner: worker
- 作業: SKILL 以外の 4 種別のドラフタ（Hook 設定 + スクリプト雛形、rules.src.md 追記案、SubAgent 定義、Workflow コマンド）を実装。Hooks/Rules は常に mryfmo 承認必須に固定。
- 検証: 種別別サンプルでドラフト生成 → 各 lint 合格。
- 完了: 4 種別が生成 PR フローに接続されマージ。

**P1-F4-T9 生成パイプライン試験運用（2 週間）** — Owner: orchestrator
- 作業: 実データで運用し、起票品質を計測。
- 検証: 起票 PR の人間採択率 ≥ 50%（研究報告の生成成功率 ~68.6% を踏まえた初期目標）。誤起票（明らかな重複・無意味）率 < 20%。
- 完了: レポート記録。未達時はスコアリング/ドラフタ改訂後 1 週間再試験。

**P1-F4-T10 Phase F4 受入** — Owner: orchestrator
- 作業/検証/完了: 横断レビュー・Tests 全合格・mryfmo 承認・evidence 記録。

**F4 Tests**: miner 再現率 / 種別判定 / 生成拒否（動的コンテキスト）/ verifier 合否分離 / eval 回帰検知 / スキャン検出 / E2E fail-closed 実証。
**F4 Done Criteria**: FR-04・FR-05・FR-09 稼働。評価スイートが全スキルの必須ゲートになっている（F6 の前提）。
**F4 Open Questions**: 採択率の恒久目標（TBD(HUMAN)）/ サロゲートタスクの自動抽出精度向上策。

---

### Phase F5: 自動組合せ・ルーティング

**P1-F5-T1 SKILL.md frontmatter 標準 v1 確定** — Owner: orchestrator
- 作業: description / triggers / scope / owner / freshness / 依存の必須化仕様を確定し既存スキル棚卸し対象を列挙。
- 検証: 標準が Agent Skills 標準と非衝突であること（Codex 側でも無視されず動作）。
- 完了: docs/reference/skill-frontmatter.md マージ（mryfmo 承認）。

**P1-F5-T2 既存スキル棚卸し・移行** — Owner: worker
- 作業: 散在する既存スキルを収集し、標準 frontmatter 付与 + eval 付与（最低 1 ケース）+ scan 通過の上で本リポジトリ/所属スコープへ移行。
- 検証: 移行スキル全件が skill-lint / skill-eval 合格。
- 完了: 棚卸し台帳（件数・移行先）を docs/reference/ へ記録しマージ。

**P1-F5-T3 スキル索引（FTS5）と `/harness:skills` 検索** — Owner: worker
- 作業: 3 層スコープ横断のスキル索引ビルダーと明示検索コマンドを実装（F-ROUTE）。
- 検証: 名称・説明・trigger の各キーで期待スキルが上位 3 位内に返る（テストクエリ 15 件）。
- 完了: 索引ビルダーが夜間ジョブ登録されマージ。

**P1-F5-T4 セッション開始時のスキル提示** — Owner: worker
- 作業: SessionStart Hook で当該リポジトリ/ユーザーに有効なスキル一覧（スコープ別）を要約提示。
- 検証: 3 層スコープのテスト構成で正しい集合が提示される。
- 完了: マージ。

**P1-F5-T5 Workflow（宣言的合成）規約と雛形** — Owner: worker
- 作業: 複数スキルの定型合成をコマンド/Plugin として宣言する規約と雛形 2 本（例: 「調査 → 計画 → 委任」フロー）を実装。実行時の暗黙合成に依存しない方針を規約化。
- 検証: 雛形 2 本が E2E で完走。
- 完了: 規約が docs/reference/workflow-conventions.md にマージ。

**P1-F5-T6 ミスマッチ検出（起動されたが逸脱）** — Owner: worker
- 作業: skill_runs にルーブリック評価（SkillCoach 型）の簡易版を接続し、選択ミス・手順逸脱を記録して F6 の入力にする。
- 検証: 逸脱シナリオ 5 件で検出。誤検知をサンプル確認。
- 完了: マージ。

**P1-F5-T7 Codex 側スキル可搬性検証** — Owner: worker
- 作業: 代表スキル 5 件を Codex CLI で起動し、無改変動作（NFR-08）を確認。非互換があれば frontmatter 標準へフィードバック。
- 検証: 5 件中 5 件が Codex で意図どおり動作、または非互換が Open Question 化。
- 完了: 互換性レポートマージ。

**P1-F5-T8 Phase F5 受入** — Owner: orchestrator
- 作業/検証/完了: 横断レビュー・Tests 全合格・mryfmo 承認・evidence 記録。

**F5 Tests**: 索引精度 / スコープ提示 / Workflow E2E / 逸脱検出 / Codex 可搬性。
**F5 Done Criteria**: FR-06 稼働。全スキルが標準 frontmatter + eval + scan 通過状態。
**F5 Open Questions**: trigger 記述のベストプラクティス集約（運用データ待ち）。

---

### Phase F6: 自動最適化ループ（harness-gc 本体）

**P1-F6-T1 最適化トリガー 3 系統実装** — Owner: worker
- 作業: (a) 夜間定期、(b) スキル別失敗率の移動平均 + 閾値超過、(c) 依存ツール/API バージョン変化検知、の 3 トリガーを実装し台帳タスク化（F-OPT）。
- 検証: 各トリガーの発火テスト（合成データ）。
- 完了: kill switch 配下で登録されマージ。

**P1-F6-T2 スキル向け reflector/curator 拡張** — Owner: worker
- 作業: F3 の還流器を SKILL.md 対象に拡張（失敗ログ・訂正・逸脱から改善デルタを構成）。デルタ種別は F3 と同一の 4 種。
- 検証: 劣化スキルのサンプルで改善デルタが生成され、eval 合格まで到達。
- 完了: マージ。

**P1-F6-T3 回帰評価ゲート統合** — Owner: worker
- 作業: 最適化 PR に対し「当該スキル eval 全件 + 隣接スキル（同 Workflow 内・依存関係）のスモーク」を必須実行する CI 統合。
- 検証: 意図的な回帰を含む PR が block される。
- 完了: 必須 CI 登録マージ。

**P1-F6-T4 重複排除・矛盾検出（層内/層間）** — Owner: worker
- 作業: 索引を用いた類似スキル検出（層内・3 層間）と Wiki との矛盾検出を harness-gc に実装。統合提案 PR を生成。
- 検証: 既知の重複ペア/矛盾サンプルで検出・提案が生成される。
- 完了: マージ。

**P1-F6-T5 陳腐化削除と自動ロールバック提案** — Owner: worker
- 作業: 長期未使用（既定 90 日）・成功率劣化スキルの廃止提案、および直近マージ後に指標悪化した変更のロールバック PR 提案を実装。
- 検証: 合成時系列で廃止/ロールバック提案が正しく発火。
- 完了: マージ。

**P1-F6-T6 A/B 評価（改変前後の実測）** — Owner: worker
- 作業: 最適化 PR マージ前に旧新 2 版を eval + サロゲートで比較し、改善幅を PR 本文へ自動記載する機構を実装（ACE 報告値の自社再現性を常時実測する仕組み）。
- 検証: 改善/劣化サンプルで判定が分かれ、本文に数値が記載される。
- 完了: マージ。

**P1-F6-T7 最適化ループ 4 週間試験運用** — Owner: orchestrator
- 作業: 実運用でループを回し、スキル別成功率・訂正率の週次トレンドを計測。
- 検証: 対象スキル群の成功率が非劣化（低下したスキルはロールバック提案が発火していること）。誤った削除提案 0 件。
- 完了: レポート記録（改善幅の実測値を REPORT の残存リスク (b) への回答として記載）。

**P1-F6-T8 diff 比率ガード恒久化** — Owner: worker
- 作業: 一括リライト検出（>40% で mryfmo 承認へ格上げ）の対象を SKILLS 全域へ拡大し、閾値を設定ファイル化。
- 検証: 閾値変更が設定のみで反映される。
- 完了: マージ。

**P1-F6-T9 Phase F6 受入** — Owner: orchestrator
- 作業/検証/完了: 横断レビュー・Tests 全合格・mryfmo 承認・evidence 記録。

**F6 Tests**: トリガー発火 / 回帰 block / 重複・矛盾検出 / 廃止・ロールバック発火 / A/B 数値記載 / 4 週間非劣化実測。
**F6 Done Criteria**: FR-07 稼働。「評価器なしの最適化は存在しない」状態（全最適化 PR が eval ゲート経由）。
**F6 Open Questions**: 失敗率閾値・未使用日数の恒久値 TBD(HUMAN)。

---

### Phase F7: スコープ統合・昇格パイプライン

**P1-F7-T1 marketplace リポジトリ構築** — Owner: worker
- 作業: 全社スコープ Plugin の marketplace リポジトリを構築し、Claude Code 設定で社内 marketplace のみを許可・外部を無効化（FR-08, ADR-0006、旧呼称 ADR-H006）。
- 検証: 社内 Plugin の install/update が機能。外部 marketplace 追加が設定で拒否される。
- 完了: 配布手順書マージ（mryfmo 承認）。

**P1-F7-T2 スコープ優先順位の実装検証** — Owner: worker
- 作業: 同名/同 trigger スキルを 3 層に配置した衝突試験を作成し、優先順位（プロジェクト > 個人 > 全社）と命名接頭辞規約の遵守を検証。
- 検証: 衝突試験で期待スキルが選択される。規約違反が lint で fail。
- 完了: 試験が CI に登録されマージ。

**P1-F7-T3 昇格候補検出** — Owner: worker
- 作業: skill_runs 統計から昇格閾値（利用回数 ≥ N、成功率 ≥ M%。初期値 N=10, M=80 で開始、恒久値 TBD(HUMAN)）超過スキルを検出。
- 検証: 合成統計で候補が正しく列挙。
- 完了: 夜間ジョブ登録マージ。

**P1-F7-T4 汎化ドラフトと昇格 PR** — Owner: worker
- 作業: curator が個人/プロジェクト固有要素（パス・固有名詞）を汎化した上位スコープ向けドラフトを作成し、昇格 PR（scan + eval + mryfmo 承認必須）を起票。
- 検証: サンプルスキルの昇格 E2E 完走。固有情報の残存 0 件（scan で検査）。
- 完了: マージ。

**P1-F7-T5 降格・廃止フロー** — Owner: worker
- 作業: 全社スキルの利用低迷・プロジェクト固有化の検出と降格/廃止提案フローを実装。
- 検証: 合成データで提案が発火。
- 完了: マージ。

**P1-F7-T6 個人スコープの scan 必須化** — Owner: worker
- 作業: ~/.claude/ 配下スキルにも取込時 scan を課すローカルフック/CLI を配布（FR-09 の個人層適用）。
- 検証: 悪性サンプルが個人層でも block される。
- 完了: 配布手順マージ。

**P1-F7-T7 パイロット 2 プロジェクト展開** — Owner: orchestrator
- 作業: 本基盤を実プロジェクト 2 件（選定 TBD(HUMAN)。mryfmo の既存プロジェクトから F7 着手前に選定）へ導入し、スコープ運用を通し試験。
- 検証: 両プロジェクトで自己改善サイクルが 1 周完走。昇格 1 件以上成立。
- 完了: 展開レポート記録。

**P1-F7-T8 Phase F7 受入** — Owner: orchestrator
- 作業/検証/完了: 横断レビュー・Tests 全合格・mryfmo 承認・evidence 記録。

**F7 Tests**: 衝突試験 / 昇格 E2E / 固有情報残存検査 / 個人層 scan / パイロット完走。
**F7 Done Criteria**: FR-08 稼働。3 層が分離しつつ昇格・降格で接続された状態。
**F7 Open Questions**: 昇格閾値の恒久値 / パイロット選定 TBD(HUMAN)。

---

### Phase F8: ガバナンス強化・フェイルセーフ完成

**P1-F8-T1 PreToolUse deny-by-default 完成** — Owner: worker
- 作業: 許可リスト外コマンド・リポジトリ外書込み・未許可ネットワークのブロック、およびハーネス artefact への PR フロー外書込み全ブロックを実装（F-GOV 4）。
- 検証: ブロック対象 12 シナリオ全 block、許可対象 12 シナリオ全 pass（誤遮断なし）。
- 完了: 必須 Hooks として登録マージ（mryfmo 承認）。

**P1-F8-T2 自己改変防護（NFR-01）** — Owner: worker
- 作業: 自己改善パイプラインのコード・CI 定義・Hooks 設定に対する変更 PR を自動検出し、自動マージ不可 + mryfmo 承認必須ラベルを強制。
- 検証: 該当パス変更 PR が例外なく格上げされる（バイパス試験含む）。
- 完了: マージ。

**P1-F8-T3 kill switch 完成** — Owner: worker
- 作業: `ctrl.kill` / DB フラグによる全ジョブ即時停止、SessionStart での停止状態表示、再開手順を実装（FR-11）。
- 検証: 停止発動 → 全ジョブ 60 秒以内停止。停止中の PR 起票 0 件。再開後の整合性維持。
- 完了: 発動・再開 runbook マージ。

**P1-F8-T4 署名・出所記録** — Owner: worker
- 作業: マージ時 artefact ハッシュ + 由来（ジョブ/セッション ID）の evidence 記録と、実行時のハッシュ照合（改変検知）を実装（F-GOV 3、AIDD の SHA-256 凍結再利用）。
- 検証: 手改変した artefact の実行が検知・警告される。
- 完了: マージ。

**P1-F8-T5 注入攻撃レッドチーム試験** — Owner: worker
- 作業: PoisonedSkills / MalSkillBench の公開手法を参照した社内試験セット（無害化済み）を作成し、scan + Hooks + サンドボックスの多層防御を評価。
- 検証: 明示的注入の実行率 0%。難読化系は検知または実行時ブロックで被害到達 0 件（データ持出し・リポジトリ外書込みの成立なし）。
- 完了: 試験セットを回帰資産として ci/ に登録、結果レポートマージ。

**P1-F8-T6 CI 経由注入対策** — Owner: worker
- 作業: CI 上のエージェント実行（claude-code-action 等を使う場合）の権限監査、workflow 設定 lint（危険設定の検出）、Secrets 最小化を実装。
- 検証: 危険設定サンプルが lint で fail。
- 完了: マージ。

**P1-F8-T7 監査レポート自動生成（FR-12 完成）** — Owner: worker
- 作業: 月次の自動変更・スキャン結果・却下事由・kill switch 発動履歴のレポート生成を実装。
- 検証: サンプル月データでレポートが完全生成。
- 完了: マージ。

**P1-F8-T8 インシデント runbook** — Owner: orchestrator
- 作業: 悪性スキル検出時・誤マージ時・暴走時の対応手順（kill switch → 隔離 → ロールバック → 事後分析 → lessons 還流）を docs/reference/ に整備。
- 検証: 机上演習 1 回を実施し手順の欠落を修正。
- 完了: runbook マージ（mryfmo 承認）。

**P1-F8-T9 障害注入試験（フェイルセーフ）** — Owner: worker
- 作業: SQLite ロック・ワーカー無応答・PR API 障害・ディスク枯渇の 4 障害を注入し、requeue・冪等・best-effort の各挙動を検証（NFR-04）。
- 検証: 4 障害すべてでデータ破損 0・二重実行 0・復旧後の自動再開成立。
- 完了: 試験レポートマージ。

**P1-F8-T10 Phase F8 受入** — Owner: orchestrator
- 作業/検証/完了: 横断レビュー・Tests 全合格・mryfmo 承認・evidence 記録。

**F8 Tests**: deny 24 シナリオ / 自己改変格上げ / kill switch 実測 / 改変検知 / レッドチーム / 障害注入 4 種。
**F8 Done Criteria**: FR-09〜FR-12・NFR-01/02/04 完成。SPEC 6.5 の 7 制御が全稼働。
**F8 Open Questions**: レッドチーム試験の定期実施周期 TBD(HUMAN)。

---

### Phase F9: 総合受入・運用移行

**P1-F9-T1 E2E シナリオ総合試験** — Owner: orchestrator
- 作業: 「新規繰り返し業務の発生 → パターン検出 → スキル自動生成 PR → mryfmo 承認 → 利用 → 訂正発生 → 自動最適化 PR → 昇格」の全周シナリオを実データで完走させる。
- 検証: 全段が evidence で追跡可能・fail-closed 逸脱 0。
- 完了: 完走記録マージ。

**P1-F9-T2 性能・容量最終計測** — Owner: worker
- 作業: NFR-03/05 の最終実測、DB 容量成長率と保持ポリシー適用の確認。
- 検証: 全 NFR 基準達成（未達は Open Question 化し暫定運用条件を明記）。
- 完了: 計測レポートマージ。

**P1-F9-T3 運用ドキュメント一式** — Owner: worker
- 作業: 管理者ガイド・利用者ガイド・承認者ガイド・runbook 索引を docs/ に整備し、CLAUDE.md/AGENTS.md のマップを最終化。
- 検証: クリーン環境（新規マシン相当）で mryfmo がドキュメントのみを頼りにセットアップ〜スキル提案まで到達するセルフオンボーディング試験を実施。
- 完了: マージ。

**P1-F9-T4 閾値・既定値の本値確定** — Owner: orchestrator
- 作業: 本計画中の既定値（起票上限 5、diff 40%、昇格 N=10/M=80、タイムアウト 15 分、未使用 90 日ほか）を試験運用実測に基づき提案し、mryfmo の決裁を得る。
- 検証: 全残存決裁事項に決裁記録が存在。
- 完了: 設定ファイル反映マージ。

**P1-F9-T5 残課題・v2 ロードマップ** — Owner: orchestrator
- 作業: Open Questions の棚卸し、外部メモリ拡張（ADR-0002、旧呼称 ADR-H002 の再評価条件）・マルチホスト化の判断材料整理。
- 検証: 全 Open Question が「解決 / v2 送り / 受容」のいずれかに分類済み。
- 完了: docs/plans/roadmap-v2.md マージ。

**P1-F9-T6 総合受入判定** — Owner: orchestrator
- 作業: FR-01〜13 / NFR-01〜08 の充足マトリクスを作成し、mryfmo の最終承認を得る。
- 検証: 全項目が証跡付きで判定済み。
- 完了: 受入判定書を evidence store へ記録（mryfmo 承認）。

**P1-F9-T7 運用移行・引継ぎ** — Owner: orchestrator
- 作業: 日常運用（mryfmo による承認運用・監査レビュー・レッドチーム周期）の体制を確定し引継ぎ。
- 検証: 移行後 1 週間、人手介入なしで夜間ジョブ群が正常完走。
- 完了: 引継ぎ完了を記録し本計画をクローズ。

**F9 Tests**: E2E 全周 / NFR 最終実測 / セルフオンボーディング / 無人 1 週間安定稼働。
**F9 Done Criteria**: Goal 達成（自己改善サイクルが本番で 1 周以上完走し、運用体制へ移行済み）。
**F9 Open Questions**: なし（T5 で全件分類済みであること自体が完了条件）。

---

## Open Questions / 決裁事項一覧

### 決裁済み

| # | 項目 | 決裁内容 |
|---|---|---|
| 1 | 対象リポジトリ名・ホスティング・保護ブランチ設定 | GitHub private `mryfmo/herness-self-improvement`、main 保護 + PR 必須 + CI 必須。 |
| 2 | 承認者名簿 | mryfmo が部門管理者・プロジェクトオーナーを単独兼任。 |
| 3 | ADR 採番 | ADR-0001〜0006 を新規採番し、H001〜H006 を旧呼称として併記。 |
| 6 | 教訓有用判定の判定者 | mryfmo。 |
| 9（承認者） | 昇格 PR の上位スコープ承認者 | mryfmo。 |

### 残存決裁事項

| # | 項目 | 初出 | 決裁期限の目安 | 状態 |
|---|---|---|---|---|
| 4 | agmsg DB 同居 or 分離（負荷試験結果次第） | F1 OQ | F1 末 | TBD(HUMAN) |
| 5 | テレメトリ保持期間・匿名化ポリシー・監査サンプル数 | F2 | F2 末 | TBD(HUMAN) |
| 7 | 生成 PR 採択率・還流採択率の恒久目標 | F3/F4 OQ | F9-T4 | TBD(HUMAN) |
| 8 | 失敗率閾値・未使用日数・昇格閾値（N, M%）などの恒久値 | F6/F7 OQ | F9-T4 | TBD(HUMAN) |
| 10 | レッドチーム定期周期 | F8 OQ | F9-T4 | TBD(HUMAN) |
| 11 | タスクタイムアウト等プロトコル既定値の本値 | SPEC 5.3 | F9-T4 | TBD(HUMAN) |
| パイロット選定 | パイロット 2 プロジェクト | F7-T7 | F7 着手前 | TBD(HUMAN) |
