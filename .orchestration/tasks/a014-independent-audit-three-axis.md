# Task a014: 三軸規律による現状独立監査(修正はしない)

- task_id: a014
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 前提: a013 受入済み(ADR-0007/0008 が docs/decisions/ に存在)。**本タスクはリポジトリを変更しない**(artifact 出力のみ)。

## Objective

「Harness(対象)× Grounded Graph(位相: ADR-0007)× Gated RSI(深さ: ADR-0008)」の統合規律に照らして、以下を**読み取りのみで**全数監査し、矛盾・ヌケモレ・間違い・曖昧の所見表を提出する。

- docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md(全 FR/NFR・5〜6 章)
- docs/decisions/ADR-0001〜0008
- docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md(全タスク)
- docs/reference/ 全ページ
- 実装(githooks/ ci/ db/ .github/)と上記文書の間の乖離

## 独立性の要件(重要)

- `.orchestration/reports/orchestrator-audit-v2-findings.md` は**読むことを禁止**する(orchestrator の所見との独立突合のため)。自力の走査のみで所見を出すこと。
- 他の `.orchestration/` 配下(過去タスクの report/validation)は読んでよい(実装乖離の証拠として)。

## 所見の形式

`.orchestration/reports/a014-report.md` に表形式で:

| ID | 種別(矛盾/ヌケモレ/間違い/曖昧) | 所在(ファイル:節) | 内容 | 三軸のどの原則に反するか | 修正先の提案(SPEC/WORKPLAN/ADR/実装) |

- 各所見に根拠(引用行 or 実装ファイル)を必須付与。推測での指摘は「曖昧」として出し、根拠の無い断定をしない。
- 件数目標は設けない。見つからない領域は「監査済み・所見なし」と明記(沈黙と網羅の区別)。

## Allowed files

`.orchestration/` の a014 5 artifact のみ。リポジトリ本体の変更禁止。

## Forbidden actions

- リポジトリのあらゆる変更、orchestrator 所見ファイルの読取り、外部 Web 取得、force-push、依存追加

## Validation

`.orchestration/validation/a014-validation.md` に監査で実行した走査コマンド(grep 等)と対象網羅の証跡(読んだファイル一覧)を記録。

## Done signal

`AGMSG-RESULT v1 task_id=a014 status=ready_for_review report=.orchestration/reports/a014-report.md validation=.orchestration/validation/a014-validation.md sandbox=.orchestration/sandboxes/a014-sandbox.md learning=.orchestration/learning/a014-learning.md autoskill=.orchestration/autoskill/runs/a014-autoskill.md`
