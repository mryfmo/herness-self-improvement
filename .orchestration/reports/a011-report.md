# a011 LLM Wiki Genealogy Report

## Status

ready_for_review

## Result

- Document: `docs/reference/llm-wiki-genealogy.md`
- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/10
- Source commit: `fb4469218975f29d8e11fb7dae8f2d0efd124dfd`
- Squash merge: `664ac7374037d99235612c4f2894bf4728472eb7`
- Branch: `a011/llm-wiki-genealogy`（merge 後に local / remote とも削除）
- Document SHA-256: `b7221a6ff6b6c04ef60fec99ae4ed2cff5b48b80e824516e860dab1d11d353ec`

## Content

- 2026-04-03 の X ポスト「LLM Knowledge Bases」と 2026-04-04 の task 指定 gist を Andrej Karpathy の原典として記載した。
- RAG の都度再発見に対し、LLM が永続的・複利的な知識アーティファクトを漸進的に構築・維持するという核心を要約した。
- 不変 raw sources、相互リンク Markdown Wiki、規約文書 schema の 3 層と、人間・LLM の分業を記載した。
- ACE（2025-10）と OpenAI Harness Engineering（2026-02-11）が 2026-04 の命名に先行することを、因果関係ではなく実践の収斂として区別した。
- Karpathy の原則と、ADR-0001〜0006、二層メモリ、append-only audit、`docs/`、`wiki-conventions.md`、`rules.src.md`、Curator、frontmatter、CI、mryfmo 決裁の対応を表にした。
- 原典の射程外として、ACE のデルタ更新、CI + 夜間 GC、供給網ガバナンス 7 制御、3 層スコープと昇格、PR 駆動監査を分けて記載した。
- REPORT v1.0 が Karpathy 原典を引用していないことと、将来改訂で出典追加と A-5 の訂正を併記する必要を明記した。

## Fact boundary

Karpathy に関する日付、題名、gist URL、核心思想は task file の列挙事項だけを使用した。外部 Web は取得していない。既存設計との対応、REPORT の欠落、A-5 の訂正はリポジトリ内の ADR、REPORT、`wiki-conventions.md`、`rules.src.md`、`evidence-and-gates.md`、`telemetry-schema.md` で確認した。

## Scope

PR #10 の変更は `docs/reference/llm-wiki-genealogy.md` だけである。4 保護文書、他文書、CI、protection/hooks、dependencies は変更していない。既存の dirty worktree と先行 task artifacts も変更・stage していない。

## PR flow

- `gh` を最初に使い、PR #9 の既存形式を確認した。
- commit は `docs(reference): add LLM Wiki genealogy`、本文 trailer は `Agent: worker`。
- PR 本文は全差分を説明し、末尾に `Agent: worker` footer を付けた。
- push CI、pull-request CI、merge 後 main CI はすべて成功した。
- CodeRabbit status は success だが、review limit のため本文レビューは未実施。inline comments は 0 件。内容は orchestrator が revision 前に承認済み。
- PR #10 を squash mergeし、checkout を main へ戻した。HEAD と origin/main は `664ac7374037d99235612c4f2894bf4728472eb7` で一致する。
