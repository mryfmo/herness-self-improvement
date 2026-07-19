# Task a012: ADR-0007 自己改善ループのグラフ化と接地原則(ユーザー提案 2026-07-19)

- task_id: a012
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 3
- 前提: a011 受入済み。全変更は PR 経由。外部 Web 取得禁止(GitHub 操作は許可)。

## Objective

`docs/decisions/ADR-0007-loop-graph-anchoring.md` を新規作成し、docs/decisions/README.md の索引に追加して PR でマージする。**Status は Proposed**(Accepted への昇格は mryfmo 決裁待ち。その旨を Status 行に明記)。

## ADR-0007 の内容(orchestrator 指定 — 事実の創作禁止、以下を整形して記載)

- frontmatter: owner mryfmo / last-verified 2026-07-19 / freshness 180d
- **Status**: Proposed(mryfmo 決裁待ち)
- **Context**: 単一の自己改善ループは 4 つの構造的失敗を持つ — (1) Goodhart 法則(指標の目的からの乖離)、(2) 参照値への上方盲目、(3) 独立に作られたループ間の衝突、(4) 測定自体の劣化(監視者の不在)。成熟した自己改善は「ループのグラフ」(ペアリング・階層・調停・監査)であり、さらにグラフだけでは相互確認の循環に陥るため「アンカー」(反論不能な接地測定・凍結ノード・機構の外から与えられる価値判断)を要する。出典: ユーザー提供エッセイ(2026-07、Peter Steinberger のポスト https://x.com/steipete/status/2078277297791189132 に言及。関連 https://x.com/IntuitMachine/status/2068808668393451770)。古典的系譜: Goodhart の法則、Argyris の double-loop learning、サイバネティクス(参照値を誰が持つかという制御階層)。
- **Decision**(6 原則):
  1. **指標ペア必須**: 最適化ループの駆動指標は単独禁止。対抗指標とペアで定義する(例: スキル成功率 ⇔ 訂正率、起票数 ⇔ 誤起票率)。F2-T5 の docs/reference/metrics.md は全指標をペアで定義すること。
  2. **参照値のオーナーと改訂ループ**: 全閾値・目標値(昇格 N/M%、diff 40%、起票上限 5 等)にオーナー(mryfmo)と改訂周期を付与し、改訂自体を統治されたループ(F9-T4 を初回とし、以後周期見直し)とする。
  3. **ループ速度の分離と調停**: 速いループ(夜間 GC・還流)と遅いループ(閾値改訂・ADR 改訂)を分離。ループ間衝突(curator 追記 vs GC 削除、昇格汎化 vs プロジェクト特化)は上位の調停(orchestrator 提案 → mryfmo 決裁)で解決し、当事者ループ内では解決しない。
  4. **アンカー分類と循環禁止**: 測定を「接地」(実行されたテスト/eval、人間のマージ・却下・訂正、実データ件数)と「派生」(集計統計、LLM 評価・ルーブリック)に分類する。**派生指標のみで駆動する最適化・昇格・削除の決定を禁止** — 派生指標は必ず 1 つ以上の接地指標とペアでのみ入力になれる。特に SkillCoach 型ルーブリック(LLM 評価)は単独で F-OPT の入力にしない。
  5. **凍結ノードの明示**: 最適化ループが変更してはならない規則(評価スイート定義、スキャン規則、凍結マニフェスト、本 ADR 群)を凍結対象として列挙し、既存 hash-freeze(a008)+ NFR-01 で強制する。
  6. **接地監査**: 月次監査(F8-T7)に「循環検査」を含める — 各最適化ループについて、直近周期の決定が接地指標に依拠したかを検証し、派生のみで回った決定を違反として報告する。
- **Consequences**: (+) Goodhart・循環的自己確認・ループ衝突への構造的防御。設計済みの evidence/凍結/監査と整合し実装が薄い。(−) 指標設計コスト増(全指標にペア要求)。ルーブリック単独の高速最適化は不可(意図的な制約)。
- **根拠**: 上記出典。既存 ADR-0003(デルタ更新)・ADR-0004(fail-closed)・ADR-0006(凍結・監査)との整合。F4-T9 が既に採択率 ⇔ 誤起票率のペアを規定しており本原則の先行例。

## 併せて

- docs/decisions/README.md に ADR-0007 行を追加(Status: Proposed)。
- learning artifact に「F2-T5(metrics.md)は指標ペア構造で定義」「F5-T6/F6 のルーブリック接続は接地ペア必須」を後続タスクへの伝達事項として記録。

## Allowed files

`docs/decisions/ADR-0007-loop-graph-anchoring.md`、`docs/decisions/README.md`(1 行追加)、PR ブランチ操作、`.orchestration/` の a012 5 artifact。

## Forbidden actions

- 4 文書(束含む)・既存 ADR-0001〜0006 の変更、外部 Web 取得、保護/フック変更、依存追加、force-push、main 直接 push

## Validation

```sh
python3 ci/check-docs.py
gh pr checks <PR番号>
```

## Done signal

`AGMSG-RESULT v1 task_id=a012 status=ready_for_review report=.orchestration/reports/a012-report.md validation=.orchestration/validation/a012-validation.md sandbox=.orchestration/sandboxes/a012-sandbox.md learning=.orchestration/learning/a012-learning.md autoskill=.orchestration/autoskill/runs/a012-autoskill.md`
