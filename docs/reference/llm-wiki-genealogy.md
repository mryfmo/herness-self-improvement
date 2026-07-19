---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# LLM Wiki の系譜と本設計での拡張

## 原典

Andrej Karpathy は 2026-04-03 の X ポスト「LLM Knowledge Bases」と、翌 2026-04-04 の [gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) で、LLM が知識ベースを育て続ける構想を示した。本ページでは、この構想を「LLM Wiki」と呼ぶ。

出発点は、通常の RAG では問いのたびに情報を探し直し、その調査結果が次の仕事へ蓄積されないという問題である。代わりに、LLM が知識ベースを漸進的に構築・維持する。調査の成果を使い捨てず、後続の仕事が再利用できる、永続的で複利的なアーティファクトに変える考え方だ。

構成は次の 3 層からなる。

1. 不変の raw sources。知識の根拠として保持し、LLM が書き換えない。
2. LLM が維持する Wiki。相互リンクされた Markdown として、raw sources から得た知識を整理する。
3. schema。Wiki の構成と更新規約を文書化し、LLM を「規律ある Wiki メンテナ」として動かす。

人間はソースを選び、方向を定め、問いを渡す。LLM は、それ以外の構築と保守を担う。この分業により、知識の根拠と運用方針は人間が握ったまま、整理と更新を継続できる。

## 実践が命名に先行した

本設計が典拠とする ACE は 2025-10、OpenAI の「Harness engineering」は 2026-02-11 に公開されている。いずれも Karpathy による 2026-04 の命名より先である。

したがって、ここで示すのは Karpathy の提案から各先行事例へ影響が広がったという因果関係ではない。知識を LLM に継続保守させ、小さな更新と検査で品質を保つ実践が先にあり、後から「LLM Wiki」という名前で捉えやすくなった収斂領域として整理する。

## Karpathy の原則と本設計

| Karpathy の原則 | 本設計での実現 |
|---|---|
| 調査結果を永続的・複利的なアーティファクトへ変える | [ADR-0002](../decisions/ADR-0002-two-layer-memory.md) の二層メモリ。SQLite の体験層と、Git 上の Wiki / SKILLS からなる恒久層を接続する。体験層の `hx_audit` は append-only で記録され、整理済み知識は `docs/` に残る。 |
| 不変の raw sources と、LLM が維持する Wiki を分ける | 体験ログを根拠として保持し、Curator が `docs/` へ知識を還流する。元の記録と整理後の文書を同一視しない。 |
| Wiki を相互リンクされた Markdown にする | `docs/` を LLM Wiki とし、[Wiki conventions](wiki-conventions.md) がリポジトリ相対リンクを定める。CI がリンクと frontmatter を検査する。 |
| schema で LLM を規律あるメンテナにする | [Wiki conventions](wiki-conventions.md) が文書の配置、frontmatter、リンクを規定し、[`rules.src.md`](../../rules.src.md) がエージェントの変更経路を定める。Curator はこの規約に従って差分を作り、CI が機械的に検査する。 |
| 人間がソース・方向・問いを決め、LLM が保守する | mryfmo が決裁を担い、エージェントが保守を担う。変更は [ADR-0001](../decisions/ADR-0001-git-single-source-of-truth.md) と [ADR-0004](../decisions/ADR-0004-fail-closed-pr-pipeline.md) に従い、PR と承認を経る。 |

## 本設計で加えた知見

以下は、本設計が LLM Wiki の原則に追加した運用上の差分である。Karpathy の原典が扱わない範囲を、既存 ADR と REPORT の根拠で補っている。

- [ADR-0003](../decisions/ADR-0003-ace-knowledge-refinement.md) は、ACE の知見に基づき、更新を追記・行更新・重複統合・陳腐化削除のデルタに限定する。一括リライトを避け、Reflector と Curator を分業させる。
- [ADR-0001](../decisions/ADR-0001-git-single-source-of-truth.md) は、OpenAI の構造化 `docs/`、CI、夜間 GC の実践を組織規模での裏付けとして採用する。Wiki を作るだけでなく、逸脱の検出と小刻みな修正まで運用に含める。
- [ADR-0006](../decisions/ADR-0006-skill-supply-chain-governance.md) は、スキル供給網に対する 7 制御を定める。導入元の制限、静的スキャン、ハッシュと由来の記録、deny-by-default、自己改変の人間承認、kill switch、全量監査である。
- [ADR-0005](../decisions/ADR-0005-three-scope-promotion.md) は、全社・プロジェクト・個人の 3 層スコープと、上位スコープへの一方向昇格を加える。利用統計、Curator の汎化、scan、eval、承認を経て昇格する。
- [ADR-0001](../decisions/ADR-0001-git-single-source-of-truth.md) と [ADR-0004](../decisions/ADR-0004-fail-closed-pr-pipeline.md) は、すべての変更を PR に載せ、diff、検証結果、承認、履歴を監査可能にする。自動生成物も無人では反映しない。

## REPORT v1.0 の既知の欠落

[REPORT v1.0](REPORT-HARNESS-SELF-IMPROVEMENT-v1.0.md) は「LLM Wiki」という語を使っているが、Karpathy の X ポストと gist を引用していない。将来の REPORT 改訂では、この原典を主要参照情報源へ追加し、LLM Wiki の説明を原典と本設計の追加分に分ける必要がある。

同じ改訂では、SPEC の仮定 A-5 も修正対象になる。リポジトリ調査の結果、AIDD Platform の closed gates / data guards / evidence store を 3 部品の型付きコードとしてそのまま再利用できるという前提は成立しなかった。現状と修正方針は [Evidence store and closed gates](evidence-and-gates.md) に記録されている。原典の追加と A-5 の訂正を併記し、REPORT が参照する前提と系譜を揃える。
