---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# ADR-0002: メモリ二層構造（SQLite 体験層 + Git 恒久層）。外部メモリ SaaS と重み更新型自己改善は不採用
旧呼称: ADR-H002

- Status: Accepted
Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)
- Context: Agents Memory の実現方式は (a) 外部メモリ基盤（Mem0 / Zep / Letta 等）、(b) モデル重みへの内在化（RL/FT）、(c) ファイル・DB による自前二層、の 3 系統がある。
- Decision: (c) を採用。体験層（episodic）= SQLite（agmsg 拡張スキーマ）に全セッション・ツール・スキルイベントを記録。恒久層（semantic/procedural）= Git 上の Wiki / SKILLS へ Reflector/Curator が還流。検索は FTS5 + frontmatter。外部メモリ基盤は `memory_export` ビューを介した将来拡張に留め、v1 では導入しない。重み更新型は不採用。
- Consequences: (+) Claude Code / Codex がネイティブに読む形式（Markdown/Git）に恒久知識が直接乗り、監査・ロールバック・可搬性が Git の機構で担保される。運用部品が増えない。(−) グラフ推論・高度な時制推論は当面持たない（必要性が実証された時点で再評価）。再評価条件: 体験層クエリの再現率不足が実測で示され、かつ Graphiti 等の自ホスト運用コストを許容する決裁が出た場合。
- 根拠: メモリ基盤のベンチマーク（LoCoMo）を巡る Mem0 / Zep の相互反論が未決着であること。Zep のトークンフットプリント（1 会話 60 万トークン級の報告）と取込直後検索失敗、Mem0 の大規模時インデックス信頼性問題の報告。重み更新型（SEAgent 等）の非検査性・非移植性は研究側（EvoSkills）も難点として明記。二重モデル体制（Claude/Codex）では重み内在化は共有不能。
