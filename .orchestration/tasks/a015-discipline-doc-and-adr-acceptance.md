# Task a015: 三軸規律文書の作成と ADR-0007/0008 の Accepted 昇格

- task_id: a015
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 3
- 前提: a014 受入済み。全変更は PR 経由。外部 Web 取得禁止(GitHub 操作許可)。

## Objective

1 PR で以下を実施:

1. `docs/specs/discipline-v1.0.md` 新規作成(下記内容)。
2. ADR-0007 / ADR-0008 の Status を `Accepted` に更新(Status 行のみ変更 + 昇格根拠行を 1 行追加。本文の他行は不変)。
3. docs/decisions/README.md の両行 Status を Accepted に更新。
4. README.md に規律文書への参照 1 行、rules.src.md の Purpose 相当節に 1〜2 行の参照を追加(生成器を再実行し CLAUDE.md/AGENTS.md を再生成コミット)。
5. canonical link 修正(監査所見 A014-12 のルート部分): README.md と rules.src.md の「Architecture decisions」参照先を ADR 束ファイルから `docs/decisions/README.md`(索引)へ変更。WORKPLAN 参照は v1.1 を正とする。ADR 束・SPEC・REPORT 本文は変更しない(a017/a018 の担当)。

## discipline-v1.0.md の内容(orchestrator 指定 — 創作禁止、以下を整形)

- frontmatter: owner mryfmo / last-verified 2026-07-19 / freshness 180d
- **位置づけ**: 本書は「決定」ではなく自己記述。決定の実体は ADR-0001〜0008。
- **三軸定式**: 本プロジェクトの規律は 3 軸の合成である。
  | 軸 | 規律 | 扱うもの | 実体 |
  |---|---|---|---|
  | 対象 | Harness Engineering | エージェントが働く環境(rules / SKILLS / Hooks / Wiki / CI) | ADR-0001、SPEC 5 章 |
  | 位相 | Grounded Graph Engineering | 改善ループ群の配線(ペア・階層・調停・監査)と接地アンカー | ADR-0007 |
  | 深さ | Gated RSI | 改善機構の自己適用の階層 L0〜L3 と人間不動点 | ADR-0008 |
- **Loop の降格**: 単一ループは規律の単位ではなく最小構成要素。単一ループの 4 失敗(Goodhart / 上方盲目 / 衝突 / 測定劣化)は ADR-0007 Context を参照。
- **用語の固定**: 本リポジトリで「Graph Engineering」は改善ループ位相の工学を指す。エージェント実行グラフ(LangGraph 等の実行アーキテクチャ)とは別概念であり、混用しない。
- **修飾語が安全性の実体**: Graph は _Grounded_(接地なきグラフは循環する)、RSI は _Gated_(ゲートなき再帰は増幅する)。修飾語を落とした運用は ADR-0004/0006/0007/0008 違反。
- **人間不動点**: 「何が better か」の根源判断・凍結ノードの位置・承認は機構の外(mryfmo)から与えられ、再帰はそこで終端する。
- **系譜**: docs/reference/llm-wiki-genealogy.md(Karpathy 原典)、ユーザー提供エッセイ(2026-07、ADR-0007 出典)、ユーザーによる三軸定式の提案と統合指示(2026-07-19)。
- ADR-0001〜0008 への相対リンク一覧。

## ADR 昇格の根拠行(両 ADR の Status 直下に追加)

`- Accepted: 2026-07-19 mryfmo 指示(ADR-0007/0008 の取り込み・RSI 追加・三軸統合と根本修正の指示)による。`

## Allowed files

`docs/specs/discipline-v1.0.md`、ADR-0007/0008(Status 行 + 根拠 1 行のみ)、docs/decisions/README.md、README.md(1 行)、rules.src.md + 再生成された CLAUDE.md / AGENTS.md、PR ブランチ操作、`.orchestration/` の a015 5 artifact。

## Forbidden actions

- 4 文書・ADR-0001〜0006 の変更、ADR-0007/0008 の指定外行の変更、外部 Web 取得、保護/フック変更、依存追加、force-push、main 直接 push

## Validation

```sh
python3 ci/check-docs.py
python3 ci/test_generate_rules.py && python3 ci/generate-rules.py && git diff --exit-code CLAUDE.md AGENTS.md
ADR-0007/0008 の diff が Status 行 + 根拠 1 行のみであることを git diff で実証
gh pr checks <PR番号>
```

## Done signal

`AGMSG-RESULT v1 task_id=a015 status=ready_for_review report=.orchestration/reports/a015-report.md validation=.orchestration/validation/a015-validation.md sandbox=.orchestration/sandboxes/a015-sandbox.md learning=.orchestration/learning/a015-learning.md autoskill=.orchestration/autoskill/runs/a015-autoskill.md`
