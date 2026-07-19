---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# Architecture decision records

| ADR | 題名 | 旧呼称 | Status |
|---|---|---|---|
| [ADR-0001](ADR-0001-git-single-source-of-truth.md) | Git を単一の真実源とし、ハーネス artefact の変更を PR 駆動に限定する | ADR-H001 | Accepted |
| [ADR-0002](ADR-0002-two-layer-memory.md) | メモリ二層構造（SQLite 体験層 + Git 恒久層）。外部メモリ SaaS と重み更新型自己改善は不採用 | ADR-H002 | Accepted |
| [ADR-0003](ADR-0003-ace-knowledge-refinement.md) | 知識還流・スキル最適化に ACE 型（Reflector/Curator・デルタ更新・grow-and-refine）を採用する | ADR-H003 | Accepted |
| [ADR-0004](ADR-0004-fail-closed-pr-pipeline.md) | 自動生成・自動最適化は fail-closed の 6 段 PR パイプラインに限定する（無人デプロイ禁止） | ADR-H004 | Accepted |
| [ADR-0005](ADR-0005-three-scope-promotion.md) | 3 層スコープ（全社 marketplace / プロジェクト .claude / 個人 ~/.claude）と一方向昇格パイプライン | ADR-H005 | Accepted |
| [ADR-0006](ADR-0006-skill-supply-chain-governance.md) | スキル供給網ガバナンス — 社内レジストリ限定・スキャン必須・動的コンテキスト禁止・自己改変の人間承認 | ADR-H006 | Accepted |
| [ADR-0007](ADR-0007-loop-graph-anchoring.md) | 自己改善をループのグラフとして設計し、接地アンカーで循環を防ぐ | — | Proposed |
