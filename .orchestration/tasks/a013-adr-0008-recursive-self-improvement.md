# Task a013: ADR-0008 再帰的自己改善の階層と限界(ユーザー提案 2026-07-19)

- task_id: a013
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 3
- 前提: a012 受入済み(ADR-0007 が存在)。全変更は PR 経由。外部 Web 取得禁止(GitHub 操作許可)。

## Objective

`docs/decisions/ADR-0008-recursive-self-improvement-strata.md` を新規作成し、docs/decisions/README.md 索引に追加して PR でマージする。**Status は Proposed**(mryfmo 決裁待ちを明記)。

## ADR-0008 の内容(orchestrator 指定 — 事実の創作禁止、以下を整形して記載)

- frontmatter: owner mryfmo / last-verified 2026-07-19 / freshness 180d
- **Status**: Proposed(mryfmo 決裁待ち)
- **Context**: 本システムには改善機構が自分自身を改善する二次ループが既に存在する(WORKPLAN F3-T6: 採択率未達時の reflector/curator プロンプト改訂、F6: 最適化機構の出力の統計的再評価)。しかし再帰の階層と限界が未定義。無制限の再帰的自己改善は (a) 改善器の誤りの複製増幅、(b) 自己参照的検証、(c) ゲート侵食(ループが自身の承認条件を緩める)の固有リスクを持つ。関連: REPORT 参照の Agentic Harness Engineering(arXiv:2604.25850)、自己進化エージェント survey(arXiv:2508.07407)、ADR-0002(重み更新不採用)、ADR-0004(fail-closed)、ADR-0007(接地原則)。提案経緯: ユーザー指示(2026-07-19、ADR-0007 提案への追加観点)。
- **Decision**(5 項):
  1. **再帰階層 L0〜L3 の定義と変更権限**:
     - L0 業務対象: 通常作業。
     - L1 ハーネス artefact(SKILLS / Wiki / Workflows / SubAgents 定義): 自動提案可、ADR-0004 の 6 段ゲート必須。
     - L2 改善機構自体(pattern-miner のスコア規則、reflector / curator / verifier のプロンプト、eval 基準、種別判定規則): 変更提案は、当該機構の出力に対する**接地メタ指標**(採択率・修正率・誤起票率・ロールバック率)に駆動される場合のみ許可。常に人間承認(mryfmo)。
     - L3 統治機構(ゲート・CI 定義・Hooks 設定・kill switch・ADR 群・凍結マニフェスト・本階層定義): 人間のみが変更。hash-freeze(ADR-0006 / a008 実装)で機械的に強制。
  2. **メタ指標の必須化**: すべての改善器ループに接地メタ指標を定義し(F3-T6 の採択率 ≥60% が先行例)、L2 変更 PR は根拠としてメタ指標の実測値を本文に記載する。
  3. **自己加速の禁止**: 起票上限・diff 閾値・承認要件・タイムアウト・昇格閾値は L3 所有の設定とし、自動変更の対象外。いかなる自動提案もこれらを緩和できない。
  4. **増幅封じ込め**: L2 変更はカナリア運用 — 次周期のメタ指標が悪化したら自動ロールバック提案(F6-T5 の機構を再利用)。L2 変更は 1 ループあたり 1 変更/周期に制限。
  5. **不動点の宣言**: 本システムは「ゲート付き再帰改善」であり、再帰は人間(mryfmo)の判断で終端する。無制限の再帰的自己改善(自己の統治機構・承認者・目的関数の自動変更)は明示的に非スコープ。
- **Consequences**: (+) 既に存在する二次ループ(F3-T6 等)が合法かつ安全に位置づけられる。誤り増幅が構造的に有界。NFR-01・ADR-0006 と整合し追加実装は薄い(メタ指標の記録と カナリア接続のみ)。(−) 改善器の改善は人間ゲートの分だけ遅い(意図的)。メタ指標の記録コスト。
- **根拠**: 上記 Context の文献・既存 ADR との整合。F3-T6 が先行例として存在。

## 併せて

- docs/decisions/README.md に ADR-0008 行を追加(Status: Proposed)。
- learning artifact に「F3-T6 / F6 の実装タスクはメタ指標記録とカナリア接続を要件に含める」を後続伝達として記録。

## Allowed files

`docs/decisions/ADR-0008-recursive-self-improvement-strata.md`、`docs/decisions/README.md`(1 行追加)、PR ブランチ操作、`.orchestration/` の a013 5 artifact。

## Forbidden actions

- 4 文書(束含む)・ADR-0001〜0007 の変更、外部 Web 取得、保護/フック変更、依存追加、force-push、main 直接 push

## Validation

```sh
python3 ci/check-docs.py
gh pr checks <PR番号>
```

## Done signal

`AGMSG-RESULT v1 task_id=a013 status=ready_for_review report=.orchestration/reports/a013-report.md validation=.orchestration/validation/a013-validation.md sandbox=.orchestration/sandboxes/a013-sandbox.md learning=.orchestration/learning/a013-learning.md autoskill=.orchestration/autoskill/runs/a013-autoskill.md`
