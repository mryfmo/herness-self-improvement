---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# Harness × Grounded Graph × Gated RSI 三軸規律

## 位置づけ

本書は、この基盤を三つの軸で捉えるための自己記述であり、新たな意思決定ではない。意思決定の実体は [ADR-0001〜0008](../decisions/README.md) に置く。

## 三軸

本プロジェクトの規律は、次の三軸の合成である。

| 軸 | 規律 | 扱うもの | 実体 |
|---|---|---|---|
| 対象 | Harness Engineering | エージェントが働く環境（rules、SKILLS、Hooks、Wiki、CI） | [ADR-0001](../decisions/ADR-0001-git-single-source-of-truth.md)、[SPEC 5 章](SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md) |
| 位相 | Grounded Graph Engineering | 改善ループ群の配線（ペア、階層、調停、監査）と接地アンカー | [ADR-0007](../decisions/ADR-0007-loop-graph-anchoring.md) |
| 深さ | Gated RSI | 改善機構の自己適用の階層 L0〜L3 と人間不動点 | [ADR-0008](../decisions/ADR-0008-recursive-self-improvement-strata.md) |

## 単一ループの位置

単一の自己改善ループは規律の単位ではなく、最小構成要素にすぎない。[ADR-0007 の Context](../decisions/ADR-0007-loop-graph-anchoring.md) が示すように、単独では Goodhart の法則による目的との乖離、参照値への上方盲目、ループ間の衝突、測定自体の劣化という四つの構造的失敗を避けられない。

## 用語と修飾語

ここでいう Graph Engineering は、改善ループの位相を設計する工学を指す。LangGraph などのエージェント実行グラフとは別の概念であり、混用しない。

Graph は Grounded でなければならない。接地しないグラフは相互確認を循環させる。RSI は Gated でなければならない。gate のない再帰は誤りを増幅する。この二つの修飾語は安全性の実体であり、省略すれば [ADR-0004](../decisions/ADR-0004-fail-closed-pr-pipeline.md)、[ADR-0006](../decisions/ADR-0006-skill-supply-chain-governance.md)、[ADR-0007](../decisions/ADR-0007-loop-graph-anchoring.md)、[ADR-0008](../decisions/ADR-0008-recursive-self-improvement-strata.md) に反する。

## 人間不動点

「何が better か」という根源判断、凍結ノードの位置、承認は、機構の外にいる mryfmo から与えられる。再帰はこの人間不動点で終了する。

## 系譜

- [LLM Wiki の系譜](../reference/llm-wiki-genealogy.md) が整理した Karpathy の原典
- ADR-0007 の出典となったユーザー提供エッセイ（2026-07）
- ユーザーによる三軸の提案と統合指示（2026-07-19）

## 意思決定

- [ADR-0001](../decisions/ADR-0001-git-single-source-of-truth.md)
- [ADR-0002](../decisions/ADR-0002-two-layer-memory.md)
- [ADR-0003](../decisions/ADR-0003-ace-knowledge-refinement.md)
- [ADR-0004](../decisions/ADR-0004-fail-closed-pr-pipeline.md)
- [ADR-0005](../decisions/ADR-0005-three-scope-promotion.md)
- [ADR-0006](../decisions/ADR-0006-skill-supply-chain-governance.md)
- [ADR-0007](../decisions/ADR-0007-loop-graph-anchoring.md)
- [ADR-0008](../decisions/ADR-0008-recursive-self-improvement-strata.md)
